import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/model/Music/index.dart';

import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/MusicDb/index.dart';
import 'package:collection/collection.dart';

class PlaylistProvider extends ChangeNotifier {
  final _dbService = MusicDbService();

  // 1. 内部保留从 Rust SQLite 读取出来的原始歌单
  List<Playlist> _rawPlaylists = [];
  List<String> _rawHistoryIds = [];

  // 2. 内存清洗后，真正暴露给 UI 渲染的有效歌单与历史记录
  List<Playlist> _filteredPlaylists = [];
  List<String> _filteredHistoryIds = [];

  // 2.1 存储当前有效的歌曲ID，用于CRUD后重新过滤
  Set<String> _activeSongIds = {};

  static const String favoritesPlaylistId = 'system_favorites';

  // 3. 将 Getter 导向清洗后的有效列表
  List<Playlist> get playlists => _filteredPlaylists;
  List<String> get historyIds => _filteredHistoryIds;

  List<Playlist> get userPlaylists =>
      _filteredPlaylists.where((p) => !p.isSystem).toList();
  List<Playlist> get systemPlaylists =>
      _filteredPlaylists.where((p) => p.isSystem).toList();

  PlaylistProvider() {
    // 构造函数不再调用 refreshFromDb，避免在 init() 前访问数据库导致空指针
  }

  /// 从数据库拉取最新歌单与播放历史 ID
  /// [musicProvider] is needed to retain network song IDs in the filtered results.
  Future<void> refreshFromDb({MusicProvider? musicProvider}) async {
    _rawPlaylists = await _dbService.getAllRustPlaylists();
    _rawHistoryIds = await _dbService.getHistoryIds();
    // 使用当前缓存的有效歌曲ID进行过滤，确保CRUD后响应式生效
    updateActivePlaylists(_activeSongIds, musicProvider: musicProvider);
  }

  /// 由 ProxyProvider 驱动，结合当前内存中有效的全局乐库动态瘦身
  /// [musicProvider] is optional but recommended — network song IDs from the queue
  /// will be retained alongside local library IDs.
  void updateActivePlaylists(Set<String> localSongIds, {MusicProvider? musicProvider}) {
    // Build a combined set of valid IDs: local library + network songs currently in queue
    final validIds = <String>{};
    validIds.addAll(localSongIds);
    if (musicProvider != null) {
      // Add ALL song IDs currently in the queue (both local and network).
      // This is critical for songs from "下载管理" (Download Management) page
      // whose IDs are file paths and are NOT in MusicProvider.library.
      // Without this, those songs get filtered out from favorites/history/playlists.
      for (final song in musicProvider.queue) {
        validIds.add(song.id);
      }
      // Also add all known network song IDs from persisted metadata
      // (critical for cold-start: queue is empty but _networkMeta is loaded)
      validIds.addAll(musicProvider.networkSongIds);
    }

    _activeSongIds = validIds;
    // 过滤歌单内的无效 ID
    _filteredPlaylists = _rawPlaylists.map((playlist) {
      final activeIds = playlist.songIds
          .where((id) => validIds.contains(id))
          .toList();
      return playlist.copyWith(songIds: activeIds);
    }).toList();

    // 过滤播放历史内的无效 ID
    _filteredHistoryIds = _rawHistoryIds
        .where((id) => validIds.contains(id))
        .toList();

    notifyListeners();
  }

  Future<void> bootstrap({
    required List<Music> currentLibrary,
    void Function(String module, String detail)? onProgress,
    MusicProvider? musicProvider,
  }) async {
    onProgress?.call('连接媒体数据库', '正在读取歌单架构...');
    await MusicDbService().init();

    // 从数据库加载原始数据，然后用传入的乐库进行初始过滤
    _rawPlaylists = await _dbService.getAllRustPlaylists();
    _rawHistoryIds = await _dbService.getHistoryIds();

    // 构建有效 ID 集合：本地库 + 网络歌曲
    final combinedIds = <String>{
      ...currentLibrary.map((s) => s.id),
    };
    if (musicProvider != null) {
      combinedIds.addAll(musicProvider.networkSongIds);
      for (final song in musicProvider.queue) {
        combinedIds.add(song.id);
      }
    }
    updateActivePlaylists(combinedIds, musicProvider: musicProvider);

    // 从原始数据中定位收藏歌单（避免 filtered 为空导致无法加载）
    final favPlaylist = _rawPlaylists.firstWhereOrNull(
      (p) => p.id == favoritesPlaylistId,
    );

    onProgress?.call('恢复收藏列表', '已载入 ${favPlaylist?.songIds.length ?? 0} 首收藏歌曲');
    onProgress?.call('恢复播放历史', '已载入 ${_rawHistoryIds.length} 首最近播放记录');
    onProgress?.call('同步自建歌单', '已拉取 ${userPlaylists.length} 个本地歌单');
  }

  // ─────────────────────────────────────────────
  // 歌单核心 CRUD 方法
  // ─────────────────────────────────────────────

  /// 创建新歌单（名称必填，封面/描述可选）
  Future<void> createPlaylist(
    String name, {
    String? coverPath,
    String? description,
    MusicProvider? musicProvider,
  }) async {
    if (name.trim().isEmpty) {
      debugPrint("警告: 歌单名称不能为空");
      return;
    }
    await _dbService.createPlaylist(
      name.trim(),
      coverPath: coverPath,
      description: description,
    );
    await refreshFromDb(musicProvider: musicProvider);
  }

  /// 删除歌单（系统歌单禁止删除）
  Future<void> deletePlaylist(String id, {MusicProvider? musicProvider}) async {
    final playlist = getPlaylistById(id);
    if (playlist == null) {
      debugPrint("警告: 歌单不存在, id=$id");
      return;
    }
    if (playlist.isSystem) {
      debugPrint("警告: 系统歌单不可删除");
      return;
    }
    await _dbService.deletePlaylist(id);
    await refreshFromDb(musicProvider: musicProvider);
  }

  /// 更新歌单信息（名称/描述/封面），传入 null 的参数保持不变
  Future<void> updatePlaylist(
    String playlistId,
    String name, {
    String? description,
    String? coverPath,
    MusicProvider? musicProvider,
  }) async {
    if (name.trim().isEmpty) {
      debugPrint("警告: 歌单名称不能为空");
      return;
    }
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) {
      debugPrint("警告: 歌单不存在, id=$playlistId");
      return;
    }
    if (playlist.isSystem) {
      debugPrint("警告: 系统歌单不可修改");
      return;
    }
    await _dbService.updatePlaylist(
      playlistId,
      name.trim(),
      desc: description,
      coverPath: coverPath,
    );
    await refreshFromDb(musicProvider: musicProvider);
  }

  /// 重命名歌单（便捷方法，内部复用 updatePlaylist）
  Future<void> renamePlaylist(String playlistId, String newName, {MusicProvider? musicProvider}) async {
    if (newName.trim().isEmpty) {
      debugPrint("警告: 歌单名称不能为空");
      return;
    }
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) {
      debugPrint("警告: 歌单不存在, id=$playlistId");
      return;
    }
    if (playlist.isSystem) {
      debugPrint("警告: 系统歌单不可重命名");
      return;
    }
    await _dbService.renamePlaylist(playlistId, newName.trim());
    await refreshFromDb(musicProvider: musicProvider);
  }

  /// 将歌曲添加到歌单（自动去重）
  Future<void> addToPlaylist(String playlistId, Music music, {MusicProvider? musicProvider}) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) {
      debugPrint("警告: 歌单不存在, id=$playlistId");
      return;
    }
    if (playlist.songIds.contains(music.id)) {
      debugPrint("提示: 歌曲已在歌单「${playlist.name}」中，跳过重复添加");
      return;
    }
    await _dbService.addMusicToPlaylist(playlistId, music.id);
    await refreshFromDb(musicProvider: musicProvider);
  }

  Future<void> removeFromPlaylist(String playlistId, String musicId, {MusicProvider? musicProvider}) async {
    await _dbService.removeFromPlaylist(playlistId, musicId);
    await refreshFromDb(musicProvider: musicProvider);
  }

  Future<void> addToHistory(Music music, int maxLimit, {MusicProvider? musicProvider}) async {
    await _dbService.addMusicToHistory(music.id, maxLimit);
    await refreshFromDb(musicProvider: musicProvider);
  }

  Future<void> clearHistory({MusicProvider? musicProvider}) async {
    await _dbService.clearHistory();
    await refreshFromDb(musicProvider: musicProvider);
  }

  Future<void> toggleMusicFavorite(Music music, {MusicProvider? musicProvider}) async {
    await _dbService.toggleMusicFavorite(music.id);
    await refreshFromDb(musicProvider: musicProvider);
  }

  // ─────────────────────────────────────────────
  // 辅助工具方法
  // ─────────────────────────────────────────────
  Playlist? getPlaylistById(String id) {
    return _filteredPlaylists.firstWhereOrNull((p) => p.id == id);
  }

  List<Music> getPlaylistSongs(String playlistId, List<Music> globalLibrary, {MusicProvider? musicProvider}) {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return [];

    return playlist.songIds
        .map((id) {
          final local = globalLibrary.firstWhereOrNull((m) => m.id == id);
          if (local != null) return local;
          return musicProvider?.getSongById(id);
        })
        .whereType<Music>()
        .toList();
  }

  List<Music> getHistorySongs(List<Music> globalLibrary, {MusicProvider? musicProvider}) {
    return _filteredHistoryIds
        .map((id) {
          final local = globalLibrary.firstWhereOrNull((m) => m.id == id);
          if (local != null) return local;
          return musicProvider?.getSongById(id);
        })
        .whereType<Music>()
        .toList();
  }
}
