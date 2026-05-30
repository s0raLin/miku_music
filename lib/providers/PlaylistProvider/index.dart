import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/model/Music/index.dart';

import 'package:myapp/model/Playlist/index.dart';
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

  static const String favoritesPlaylistId = 'system_favorites';

  // 3. 将 Getter 导向清洗后的有效列表
  List<Playlist> get playlists => _filteredPlaylists;
  List<String> get historyIds => _filteredHistoryIds;

  List<Playlist> get userPlaylists =>
      _filteredPlaylists.where((p) => !p.isSystem).toList();
  List<Playlist> get systemPlaylists =>
      _filteredPlaylists.where((p) => p.isSystem).toList();

  PlaylistProvider() {
    refreshFromDb();
  }

  /// 从数据库拉取最新歌单与播放历史 ID（只更新 raw 原始数据）
  Future<void> refreshFromDb() async {
    _rawPlaylists = await _dbService.getAllRustPlaylists();
    _rawHistoryIds = await _dbService.getHistoryIds();
    // 注意：这里先不盲目 notifyListeners()，等 ProxyProvider 的逻辑来统一驱动清洗
  }

  /// ✨ 核心优雅逻辑：由 ProxyProvider 驱动，结合当前内存中有效的全局乐库动态瘦身
  void updateActivePlaylists(Set<String> localSongIds) {
    // 过滤歌单内的无效 ID
    _filteredPlaylists = _rawPlaylists.map((playlist) {
      final activeIds = playlist.songIds
          .where((id) => localSongIds.contains(id))
          .toList();
      return playlist.copyWith(songIds: activeIds);
    }).toList();

    // 过滤播放历史内的无效 ID
    _filteredHistoryIds = _rawHistoryIds
        .where((id) => localSongIds.contains(id))
        .toList();

    notifyListeners();
  }

  Future<void> bootstrap({
    required List<Music> currentLibrary, // ✨ 建议把启动时的内存乐库一同传进来，用于初次清洗自驱
    void Function(String module, String detail)? onProgress,
  }) async {
    onProgress?.call('连接媒体数据库', '正在读取歌单架构...');
    await MusicDbService().init();

    _rawPlaylists = await _dbService.getAllRustPlaylists();
    _rawHistoryIds = await _dbService.getHistoryIds();

    // ✨ 修复：从包含完整原始数据的 _rawPlaylists 中去定位，避免冷启动时 filtered 为空导致无法加载
    final favPlaylist = _rawPlaylists.firstWhereOrNull(
      (p) => p.id == favoritesPlaylistId,
    );

    onProgress?.call('恢复收藏列表', '已载入 ${favPlaylist?.songIds.length ?? 0} 首收藏歌曲');
    onProgress?.call('恢复播放历史', '已载入 ${_rawHistoryIds.length} 首最近播放记录');

    // ✨ 在通知 UI 前，利用刚传进来的乐库先进行一次初始过滤，让 userPlaylists 能正确计算出数量
    final localSongIds = currentLibrary.map((s) => s.id).toSet();
    updateActivePlaylists(localSongIds);

    onProgress?.call('同步自建歌单', '已拉取 ${userPlaylists.length} 个本地歌单');
  }

  // ─────────────────────────────────────────────
  // 歌单核心 CRUD 方法
  // ─────────────────────────────────────────────

  Future<void> createPlaylist(
    String name, {
    String? coverPath,
    String? description,
  }) async {
    await _dbService.createPlaylist(
      name,
      coverPath: coverPath,
      description: description,
    );
    await refreshFromDb();
  }

  Future<void> deletePlaylist(String id) async {
    final playlist = getPlaylistById(id);
    if (playlist != null && playlist.isSystem) {
      debugPrint("警告: 系统歌单不可删除");
      return;
    }
    await _dbService.deletePlaylist(id);
    await refreshFromDb();
  }

  Future<void> updatePlaylist(
    String playlistId,
    String name, {
    String? description,
    String? coverPath,
  }) async {
    await _dbService.updatePlaylist(
      playlistId,
      name,
      desc: description,
      coverPath: coverPath,
    );
    await refreshFromDb();
  }

  Future<void> renamePlaylist(String playlistId, String newName) async {
    await _dbService.renamePlaylist(playlistId, newName);
    await refreshFromDb();
  }

  Future<void> addToPlaylist(String playlistId, Music music) async {
    await _dbService.addMusicToPlaylist(playlistId, music.id);
    await refreshFromDb();
  }

  Future<void> removeFromPlaylist(String playlistId, String musicId) async {
    await _dbService.removeFromPlaylist(playlistId, musicId);
    await refreshFromDb();
  }

  Future<void> addToHistory(Music music) async {
    await _dbService.addMusicToHistory(music.id);
    await refreshFromDb();
  }

  Future<void> clearHistory() async {
    await _dbService.clearHistory();
    await refreshFromDb();
  }

  Future<void> toggleMusicFavorite(Music music) async {
    await _dbService.toggleMusicFavorite(music.id);
    await refreshFromDb();
  }

  // ─────────────────────────────────────────────
  // 辅助工具方法
  // ─────────────────────────────────────────────
  Playlist? getPlaylistById(String id) {
    return _filteredPlaylists.firstWhereOrNull((p) => p.id == id);
  }

  List<Music> getPlaylistSongs(String playlistId, List<Music> globalLibrary) {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return [];

    return playlist.songIds
        .map((id) => globalLibrary.firstWhereOrNull((m) => m.id == id))
        .whereType<Music>()
        .toList();
  }

  List<Music> getHistorySongs(List<Music> globalLibrary) {
    return _filteredHistoryIds
        .map((id) => globalLibrary.firstWhereOrNull((m) => m.id == id))
        .whereType<Music>()
        .toList();
  }
}
