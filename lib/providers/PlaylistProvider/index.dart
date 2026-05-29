import 'dart:async';
import 'package:flutter/material.dart';
import 'package:myapp/model/Music/index.dart';

import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/service/MusicDb/index.dart';
import 'package:collection/collection.dart';

class PlaylistProvider extends ChangeNotifier {
  final _dbService = MusicDbService();

  List<Playlist> _playlists = [];
  List<Playlist> get playlists => _playlists;

  List<String> _historyIds = [];
  List<String> get historyIds => _historyIds;

  static const String favoritesPlaylistId = 'system_favorites';

  List<Playlist> get userPlaylists =>
      _playlists.where((p) => !p.isSystem).toList();
  List<Playlist> get systemPlaylists =>
      _playlists.where((p) => p.isSystem).toList();

  PlaylistProvider() {
    refreshFromDb();
  }

  /// 从数据库拉取最新歌单与播放历史 ID
  Future<void> refreshFromDb() async {
    _playlists = await _dbService.getAllRustPlaylists();
    _historyIds = await _dbService.getHistoryIds();
    notifyListeners();
  }

  Future<void> bootstrap({
    void Function(String module, String detail)? onProgress,
  }) async {
    onProgress?.call('连接媒体数据库', '正在读取歌单架构...');
    await MusicDbService().init();

    _playlists = await _dbService.getAllRustPlaylists();

    final favPlaylist = getPlaylistById(favoritesPlaylistId);
    _historyIds = await _dbService.getHistoryIds();

    onProgress?.call('恢复收藏列表', '已载入 ${favPlaylist?.songIds.length ?? 0} 首收藏歌曲');

    onProgress?.call('恢复播放历史', '已载入 ${_historyIds.length} 首最近播放记录');

    onProgress?.call('同步自建歌单', '已拉取 ${userPlaylists.length} 个本地歌单');

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 歌单核心 CRUD 方法（主动触发更新，杜绝套娃）
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
    return _playlists.firstWhereOrNull((p) => p.id == id);
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
    return _historyIds
        .map((id) => globalLibrary.firstWhereOrNull((m) => m.id == id))
        .whereType<Music>()
        .toList();
  }
}
