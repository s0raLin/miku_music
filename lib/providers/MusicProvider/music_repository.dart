import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/service/NetworkSongStore/index.dart';
import 'package:package_info_plus/package_info_plus.dart';

class _NetworkSongMeta {
  final String url;
  final String title;
  final String artist;
  final String? coverUrl;
  String? lyricContent;

  _NetworkSongMeta({
    required this.url,
    required this.title,
    required this.artist,
    this.coverUrl,
  });
}

class MusicRepository {
  // ── network song metadata cache ──
  final Map<String, _NetworkSongMeta> _networkMeta = {};

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

  String? getCoverUrl(String musicId) => _networkMeta[musicId]?.coverUrl;
  String? getNetworkUrl(String musicId) => _networkMeta[musicId]?.url;
  String? getCachedLyrics(String musicId) =>
      _networkMeta[musicId]?.lyricContent;
  bool isNetworkSong(String musicId) => _networkMeta.containsKey(musicId);
  Set<String> get networkSongIds => _networkMeta.keys.toSet();

  Music? getSongById(String id, List<Music> library, List<Music> queue) {
    final local = library.where((m) => m.id == id).firstOrNull;
    if (local != null) return local;

    final queued = queue.where((m) => m.id == id).firstOrNull;
    if (queued != null) return queued;

    final netMeta = _networkMeta[id];
    if (netMeta != null) {
      return Music(
        id: id,
        title: netMeta.title,
        artist: netMeta.artist,
        duration: Duration.zero,
        coverBytes: null,
        lyrics: netMeta.lyricContent,
        album: null,
        source: MusicSource.network,
      );
    }
    return null;
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
    _networkMeta[musicId] = _NetworkSongMeta(
      url: url,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
    )..lyricContent = lyricContent;
  }

  void updateNetworkUrl(String musicId, String freshUrl) {
    final meta = _networkMeta[musicId];
    if (meta != null) {
      _networkMeta[musicId] = _NetworkSongMeta(
        url: freshUrl,
        title: meta.title,
        artist: meta.artist,
        coverUrl: meta.coverUrl,
      )..lyricContent = meta.lyricContent;
    }
  }

  void updateLyricContent(String musicId, String lyricContent) {
    _networkMeta[musicId]?.lyricContent = lyricContent;
  }

  /// Refresh netease song URL and return the fresh one.
  Future<String?> refreshNeteaseUrl(String musicId) async {
    if (!musicId.startsWith('net_')) return null;
    final numericId = musicId.substring(4);
    try {
      final freshUrl = await NeteaseApi.getRealUrl(
        numericId,
        source: 'netease',
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
          _networkMeta[music.id]?.url ?? '',
          _networkMeta[music.id]?.coverUrl,
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
        _networkMeta[meta.id] = _NetworkSongMeta(
          url: meta.url,
          title: meta.title,
          artist: meta.artist,
          coverUrl: meta.coverUrl,
        );
        if (meta.lyrics != null && meta.lyrics!.isNotEmpty) {
          _networkMeta[meta.id]?.lyricContent = meta.lyrics;
        }
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

  // ── bulk network songs import (for search results) ──

  /// Import a batch of network search result songs.
  /// Returns (musicList, storeMetas) so the provider can build the queue.
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

      final music = Music(
        id: musicId,
        title: title,
        artist: artist,
        duration: Duration.zero,
        coverBytes: null,
        lyrics: lyrics,
        album: null,
        source: MusicSource.network,
      );

      registerNetworkSong(
        musicId: musicId,
        url: url,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
        lyricContent: lyrics,
      );

      storeMetas.add(
        NetworkSongMeta(
          id: musicId,
          title: title,
          artist: artist,
          url: url,
          coverUrl: coverUrl,
          lyrics: lyrics,
          durationMs: 0,
        ),
      );

      musicList.add(music);
    }

    NetworkSongStore().upsertAll(storeMetas);
    return (musicList, storeMetas);
  }

  // ── lifecycle ──

  void dispose() {
    _persistTimer?.cancel();
  }
}
