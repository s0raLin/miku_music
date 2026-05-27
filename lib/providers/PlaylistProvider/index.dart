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

  static const String favoritesPlaylistId = 'system_favorites';
  static const String recentPlaylistId = 'system_recent';

  List<Playlist> get userPlaylists =>
      _playlists.where((p) => !p.isSystem).toList();
  List<Playlist> get systemPlaylists =>
      _playlists.where((p) => p.isSystem).toList();

  // 1. 构造函数保持绝对干净，或者只在初始化阶段拉取一次数据，不允许在里面订阅容易重复构建的单例 Stream
  PlaylistProvider() {
    refreshFromDb();
  }

  /// 从数据库拉取最新歌单数据
  Future<void> refreshFromDb() async {
    _playlists = await _dbService.getAllRustPlaylists();
    notifyListeners();
  }

  Future<void> bootstrap({
    void Function(String module, String detail)? onProgress,
  }) async {
    onProgress?.call('连接媒体数据库', '正在读取歌单架构...');

    // 从 Rust SQLite 中获取包含系统和自建的完整列表
    _playlists = await _dbService.getAllRustPlaylists();

    // 提取系统专属歌单实体，用于更加精细的进度信息展示
    final favPlaylist = getPlaylistById(favoritesPlaylistId);
    final recentPlaylist = getPlaylistById(recentPlaylistId);

    onProgress?.call('恢复收藏列表', '已载入 ${favPlaylist?.songIds.length ?? 0} 首收藏歌曲');

    onProgress?.call(
      '恢复播放历史',
      '已载入 ${recentPlaylist?.songIds.length ?? 0} 首最近播放记录',
    );

    onProgress?.call('同步自建歌单', '已拉取 ${userPlaylists.length} 个本地歌单');

    // 全部装载完毕，统一派发 UI 刷新通知
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 歌单核心 CRUD 方法（主动触发更新，杜绝套娃）
  // ─────────────────────────────────────────────

  /// 创建新歌单
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
    // 主动控制刷新，只有这一个口子，清清爽爽
    await refreshFromDb();
  }

  /// 删除指定歌单
  Future<void> deletePlaylist(String id) async {
    final playlist = getPlaylistById(id);
    if (playlist != null && playlist.isSystem) {
      debugPrint("警告: 系统歌单不可删除");
      return;
    }
    await _dbService.deletePlaylist(id);
    await refreshFromDb();
  }

  /// 重命名歌单
  Future<void> renamePlaylist(String playlistId, String newName) async {
    await _dbService.renamePlaylist(playlistId, newName);
    await refreshFromDb();
  }

  /// 向歌单追加歌曲
  Future<void> addToPlaylist(String playlistId, MusicInfo music) async {
    await _dbService.addMusicToPlaylist(playlistId, music.id);
    await refreshFromDb();
  }

  /// 从歌单移除歌曲
  Future<void> removeFromPlaylist(String playlistId, String musicId) async {
    await _dbService.removeFromPlaylist(playlistId, musicId);
    await refreshFromDb();
  }

  /// 将歌曲添加到历史记录
  Future<void> addToHistory(MusicInfo music) async {
    await _dbService.addMusicToHistory(music.id);
    await refreshFromDb();
  }

  // 将歌曲添加到收藏
  Future<void> toggleMusicFavorite(MusicInfo music) async {
    await _dbService.toggleMusicFavorite(music.id);
    await refreshFromDb();
  }

  // ─────────────────────────────────────────────
  // 辅助工具方法
  // ─────────────────────────────────────────────
  Playlist? getPlaylistById(String id) {
    return _playlists.firstWhereOrNull((p) => p.id == id);
  }

  List<MusicInfo> getPlaylistSongs(
    String playlistId,
    List<MusicInfo> globalLibrary,
  ) {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return [];

    return playlist.songIds
        .map((id) => globalLibrary.firstWhereOrNull((m) => m.id == id))
        .whereType<MusicInfo>()
        .toList();
  }
}
