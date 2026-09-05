import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/music_queue.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/service/MusicDb/index.dart';
import 'package:myapp/service/NetworkSongStore/index.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MusicRepository {
  // ── 必须设为单例，防止跨页面或重新 Build 时内存 Map 被重置 ──
  MusicRepository._internal();
  static final MusicRepository _instance = MusicRepository._internal();
  factory MusicRepository() => _instance;

  // ── network song storage (以 Music 为单源数据，配合独立的 URL 缓存) ──
  final Map<String, Music> _networkSongs = {};
  final Map<String, String> _networkUrls = {};

  // ── cover cache ──
  final Map<String, String> _safeCoverCache = {};
  final Set<String> _loadingCoverIds = {};
  final Set<String> _noCoverIds = {};

  // ── debounce persist ──
  final List<NetworkSongMeta> _persistQueue = [];
  Timer? _persistTimer;

  // ── app info ──
  PackageInfo? _appInfo;
  PackageInfo? get appInfo => _appInfo;
  String get appVersion => _appInfo?.version ?? '加载中...';
  String get buildNumber => _appInfo?.buildNumber ?? '';

  /// Notify callback — set by the owning MusicProvider.
  VoidCallback? onNotify;

  // ── public network meta accessors ──

  String? getCoverUrl(String musicId) => _networkSongs[musicId]?.coverUrl;
  String? getNetworkUrl(String musicId) => _networkUrls[musicId];
  String? getCachedLyrics(String musicId) => _networkSongs[musicId]?.lyrics;
  bool isNetworkSong(String musicId) => _networkSongs.containsKey(musicId);
  Set<String> get networkSongIds => _networkSongs.keys.toSet();

  /// 根据 ID 精准获取 Music 实体（对于网络歌曲直接返回内存中的单例，避免重复创建）
  Music? getSongById(String id, List<Music> library, List<Music> queue) {
    final local = library.where((m) => m.id == id).firstOrNull;
    if (local != null) return local;

    final queued = queue.where((m) => m.id == id).firstOrNull;
    if (queued != null) return queued;

    return _networkSongs[id];
  }

  /// 批量导入搜索结果时，优先复用已有的内存实例
  (List<Music>, List<NetworkSongMeta>) importNetworkSearchResults(
    List<Map<String, String?>> songs,
  ) {
    final List<Music> musicList = [];
    final List<NetworkSongMeta> storeMetas = [];

    for (final s in songs) {
      final musicId = 'net_${s['id']}';
      final title = s['title'] ?? '';
      final artist = s['artist'] ?? '';
      final url = s['url'] ?? '';
      final coverUrl = s['coverUrl'];
      final lyrics = s['lyrics'];

      // 1. 先尝试获取内存中已有的对象
      var music = _networkSongs[musicId];

      if (music != null) {
        // 如果对象已存在，仅在关键信息更新时增量刷新
        if ((coverUrl != null && music.coverUrl != coverUrl) ||
            (lyrics != null && music.lyrics != lyrics)) {
          music = music.copyWith(
            coverUrl: coverUrl ?? music.coverUrl,
            lyrics: lyrics ?? music.lyrics,
          );
          _networkSongs[musicId] = music;
        }
      } else {
        // 2. 内存中不存在才注册新建
        registerNetworkSong(
          musicId: musicId,
          url: url,
          title: title,
          artist: artist,
          coverUrl: coverUrl,
          lyricContent: lyrics,
        );
        music = _networkSongs[musicId]!;
      }

      storeMetas.add(
        NetworkSongMeta(
          id: musicId,
          title: music.title,
          artist: music.artist,
          url: url,
          coverUrl: music.coverUrl,
          lyrics: music.lyrics,
          durationMs: music.duration.inMilliseconds,
        ),
      );

      musicList.add(music);
    }

    NetworkSongStore().upsertAll(storeMetas);
    return (musicList, storeMetas);
  }
  
  // ── cover helpers ──

  bool isCoverLoading(String musicId) => _loadingCoverIds.contains(musicId);
  bool hasNoCover(String musicId) => _noCoverIds.contains(musicId);

  /// Convert a potential netease cover URL to a safe local file:// URI.
  Future<String?> getSafeArtUri(String? coverUrl) async {
    if (coverUrl == null || coverUrl.isEmpty) return null;

    if (_safeCoverCache.containsKey(coverUrl)) {
      return _safeCoverCache[coverUrl];
    }

    if (coverUrl.contains('music.126.net')) {
      String targetUrl = coverUrl
          .replaceAll('http://', 'https://')
          .replaceAll('p2.music.126.net', 'p1.music.126.net');

      try {
        final file = await DefaultCacheManager().getSingleFile(
          targetUrl,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://music.163.com/',
          },
        );

        final safePath = Uri.file(file.path).toString();
        _safeCoverCache[coverUrl] = safePath;
        return safePath;
      } catch (e) {
        debugPrint('--- [MusicRepository] 预缓存网易云封面失败: $e ---');

        try {
          final fallbackFile = await DefaultCacheManager().getSingleFile(
            targetUrl,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          );
          final safePath = Uri.file(fallbackFile.path).toString();
          _safeCoverCache[coverUrl] = safePath;
          return safePath;
        } catch (_) {
          return null;
        }
      }
    }
    return coverUrl;
  }

  /// Lazily load cover bytes for a local music ID (not network).
  Future<Uint8List?> loadCoverLazy(String musicId) async {
    if (isNetworkSong(musicId) ||
        _noCoverIds.contains(musicId) ||
        _loadingCoverIds.contains(musicId)) {
      return null;
    }

    _loadingCoverIds.add(musicId);
    onNotify?.call();

    try {
      final updated = await MusicService.parse(musicId);
      if (updated.coverBytes != null && updated.coverBytes!.isNotEmpty) {
        _loadingCoverIds.remove(musicId);
        onNotify?.call();
        return updated.coverBytes;
      } else {
        _noCoverIds.add(musicId);
        return null;
      }
    } catch (e) {
      debugPrint('懒加载音频封面失败 [$musicId]: $e');
      _noCoverIds.add(musicId);
      return null;
    } finally {
      _loadingCoverIds.remove(musicId);
      onNotify?.call();
    }
  }

  // ── network song metadata management ──

  void registerNetworkSong({
    required String musicId,
    required String url,
    required String title,
    required String artist,
    String? coverUrl,
    String? lyricContent,
  }) {
    _networkUrls[musicId] = url;

    // 如果已存在该网络歌曲对象，通过 copyWith 增量更新；否则新建
    final existing = _networkSongs[musicId];
    if (existing != null) {
      _networkSongs[musicId] = existing.copyWith(
        title: title,
        artist: artist,
        coverUrl: coverUrl ?? existing.coverUrl,
        lyrics: lyricContent ?? existing.lyrics,
      );
    } else {
      _networkSongs[musicId] = Music(
        id: musicId,
        title: title,
        artist: artist,
        duration: Duration.zero,
        coverBytes: null,
        coverUrl: coverUrl,
        lyrics: lyricContent,
        album: null,
        source: MusicSource.network,
      );
    }
  }

  void updateNetworkUrl(String musicId, String freshUrl) {
    _networkUrls[musicId] = freshUrl;
  }

  void updateLyricContent(String musicId, String lyricContent) {
    final existing = _networkSongs[musicId];
    if (existing != null) {
      _networkSongs[musicId] = existing.copyWith(lyrics: lyricContent);
    }
  }

  /// Refresh netease song URL and return the fresh one.
  Future<String?> refreshNeteaseUrl(String musicId) async {
    if (!musicId.startsWith('net_')) return null;
    final numericId = musicId.substring(4);
    try {
      final freshUrl = await NeteaseApi.getRealUrl(
        numericId,
        // source: 'netease',
      );
      if (freshUrl != null && freshUrl.isNotEmpty) {
        updateNetworkUrl(musicId, freshUrl);
        return freshUrl;
      }
    } catch (_) {
      debugPrint('刷新网络歌曲URL失败，使用缓存URL');
    }
    return null;
  }

  // ── lyrics fetching ──

  Future<String?> fetchAndCacheLyrics(Music music) async {
    Future<(String, bool)> lyricFuture;
    if (music.id.startsWith('net_')) {
      final numericId = music.id.substring(4);
      lyricFuture = NeteaseApi.getLyric(numericId).then((map) {
        final lrc = map['lyric'];
        return (lrc ?? '', lrc != null && lrc.isNotEmpty);
      });
    } else {
      lyricFuture = MusicApi.searchLyrics(music.artist, music.title);
    }

    try {
      final (lrc, found) = await lyricFuture;
      if (found && lrc.isNotEmpty) {
        updateLyricContent(music.id, lrc);
        music.lyrics = lrc;
        _debouncePersistNetworkSong(
          music,
          getNetworkUrl(music.id) ?? '',
          getCoverUrl(music.id),
          lrc,
        );
        return lrc;
      }
    } catch (_) {}
    return null;
  }

  // ── persist network songs ──

  void debouncePersistNetworkSong(
    Music music,
    String url,
    String? coverUrl,
    String? lyrics,
  ) {
    _debouncePersistNetworkSong(music, url, coverUrl, lyrics);
  }

  void _debouncePersistNetworkSong(
    Music music,
    String url,
    String? coverUrl,
    String? lyrics,
  ) {
    final meta = NetworkSongMeta(
      id: music.id,
      title: music.title,
      artist: music.artist,
      url: url,
      coverUrl: coverUrl,
      lyrics: lyrics,
      durationMs: music.duration.inMilliseconds,
    );

    _persistQueue.removeWhere((item) => item.id == meta.id);
    _persistQueue.add(meta);

    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 500), () {
      if (_persistQueue.isNotEmpty) {
        NetworkSongStore().upsertAll(List.from(_persistQueue));
        _persistQueue.clear();
      }
    });
  }

  Future<void> loadPersistedNetworkSongs() async {
    try {
      final metas = await NetworkSongStore().loadAll();
      for (final meta in metas) {
        registerNetworkSong(
          musicId: meta.id,
          url: meta.url,
          title: meta.title,
          artist: meta.artist,
          coverUrl: meta.coverUrl,
          lyricContent: meta.lyrics,
        );
      }
      debugPrint('Loaded ${metas.length} persisted network songs');
    } catch (e) {
      debugPrint('Failed to load persisted network songs: $e');
    }
  }

  // ── app info ──

  Future<void> loadAppInfo() async {
    _appInfo = await PackageInfo.fromPlatform();
  }

  /// 将播放队列快照异步落盘到 Rust SQLite
  Future<void> saveQueueSnapshot(QueueSnapshot snapshot) async {
    try {
      final songIds = snapshot.songs.map((s) => s.id).toList();
      if (songIds.isEmpty) return;

      // 如果是网络歌曲，确保元数据也已异步持久化到数据库中
      for (final song in snapshot.songs) {
        if (isNetworkSong(song.id)) {
          final url = getNetworkUrl(song.id);
          if (url != null) {
            debouncePersistNetworkSong(
              song,
              url,
              getCoverUrl(song.id),
              getCachedLyrics(song.id),
            );
          }
        }
      }

      await MusicDbService().saveQueueSnapshot(
        snapshot,
        songIds: songIds,
        currentIndex: snapshot.currentIndex,
      );
    } catch (e) {
      debugPrint('持久化队列快照失败: $e');
    }
  }

  /// 删除单条历史快照持久化数据
  Future<void> deleteQueueSnapshot(String snapshotId) async {
    try {
      await MusicDbService().deleteQueueSnapshot(snapshotId);
    } catch (e) {
      debugPrint('删除历史快照失败: $e');
    }
  }

  /// 清空历史快照持久化数据
  Future<void> clearQueueHistory() async {
    try {
      await MusicDbService().clearQueueHistory();
    } catch (e) {
      debugPrint('清空历史快照失败: $e');
    }
  }

  /// 从 SQLite 数据库恢复历史快照列表，并自动映射解析 ID -> Music 实体
  Future<List<QueueSnapshot>> loadQueueHistoryFromDb({
    required List<Music> library,
    required List<Music> currentQueue,
  }) async {
    try {
      return await MusicDbService().getQueueHistory(
        limit: 20,
        songsFetcher: (ids) async {
          final List<Music> fetchedSongs = [];
          for (final id in ids) {
            // 优先从本地乐库、当前队列或网络缓存中精准获取 Music 实体
            final song = getSongById(id, library, currentQueue);
            if (song != null) {
              fetchedSongs.add(song);
            }
          }
          return fetchedSongs;
        },
      );
    } catch (e) {
      debugPrint('加载数据库队列历史失败: $e');
      return [];
    }
  }

  // ── lifecycle ──

  void dispose() {
    _persistTimer?.cancel();
  }
}
