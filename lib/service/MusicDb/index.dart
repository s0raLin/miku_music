import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/providers/MusicProvider/music_queue.dart';

import 'package:myapp/src/rust/api/audio_db.dart' as rust_db;

import 'package:path_provider/path_provider.dart';

class MusicDbService {
  MusicDbService._internal();

  static final MusicDbService _instance = MusicDbService._internal();

  factory MusicDbService() => _instance;

  // 使用别名 rust_db.DbManager
  rust_db.DbManager? _dbManager;

  final _playlistUpdateController = StreamController<void>.broadcast();
  Stream<void> get playlistUpdates => _playlistUpdateController.stream;

  final _queueHistoryUpdateController = StreamController<void>.broadcast();
  Stream<void> get queueHistoryUpdates => _queueHistoryUpdateController.stream;

  Future<void> init() async {
    if (_dbManager != null) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = "${docDir.path}/m3_music.db";

      _dbManager = await rust_db.DbManager.newInstance(dbPath: dbPath);
      debugPrint("本地 SQLite 数据库初始化成功: $dbPath");
    } catch (e) {
      debugPrint("本地 SQLite 数据库初始化失败: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 队列快照历史 (QueueHistory) 业务方法
  // ═══════════════════════════════════════════════════════════════════════════

  /// 保存当前播放队列快照到数据库
  Future<String> saveQueueSnapshot(QueueSnapshot snapshot, {
    required List<String> songIds,
    required int currentIndex,
    int maxLimit = 20,
  }) async {
    if (_dbManager == null || songIds.isEmpty) return "";

    try {
      // 修复：使用 BigInt.from 将 int 转为 Rust 期望的 BigInt
      final snapshotId = await _dbManager!.saveQueueSnapshot(
        songs: songIds,
        currentIndex: currentIndex,
        maxLimit: maxLimit,
      );

      _queueHistoryUpdateController.add(null);
      return snapshotId;
    } catch (e) {
      debugPrint("[MusicDbService] saveQueueSnapshot 失败: $e");
      return "";
    }
  }

  /// 获取数据库中的队列快照历史列表
  /// 注意：这里的 QueueSnapshot 是 Dart 侧的模型，MusicItem 是 Dart 侧的歌曲模型
  Future<List<QueueSnapshot>> getQueueHistory({
    int limit = 20,
    required Future<List<Music>> Function(List<String> ids) songsFetcher,
  }) async {
    if (_dbManager == null) return [];

    try {
      // 修复：传入 BigInt 类型 limit
      final rawSnapshots = await _dbManager!.getQueueHistory(limit: limit);
      final List<QueueSnapshot> result = [];

      for (var raw in rawSnapshots) {
        final List<Music> songs = await songsFetcher(raw.songs);

        result.add(
          QueueSnapshot(
            id: raw.id,
            name: "历史播放队列 (${songs.length}首)",
            songs: songs,
            // 修复：BigInt 转为 int
            currentIndex: raw.currentIndex.toInt(),
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              // 修复：如果 raw.createdAt 是 BigInt，使用 .toInt()
              raw.createdAt.toInt() * 1000,
              isUtc: true,
            ).toLocal(),
          ),
        );
      }

      return result;
    } catch (e) {
      debugPrint("[MusicDbService] getQueueHistory 失败: $e");
      return [];
    }
  }

  Future<void> deleteQueueSnapshot(String snapshotId) async {
    if (_dbManager == null) return;

    try {
      await _dbManager!.deleteQueueSnapshot(snapshotId: snapshotId);
      _queueHistoryUpdateController.add(null);
    } catch (e) {
      debugPrint("[MusicDbService] deleteQueueSnapshot 失败: $e");
    }
  }

  Future<void> clearQueueHistory() async {
    if (_dbManager == null) return;

    try {
      await _dbManager!.clearQueueHistory();
      _queueHistoryUpdateController.add(null);
    } catch (e) {
      debugPrint("[MusicDbService] clearQueueHistory 失败: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 原有 歌单 & 历史 相关方法
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> createPlaylist(
    String name, {
    String? coverPath = "",
    String? description = "",
  }) async {
    await _dbManager?.createPlaylist(
      name: name,
      description: description,
      isSystem: false,
    );
    _playlistUpdateController.add(null);
  }

  Future<List<Playlist>> getAllRustPlaylists() async {
    final rustPlaylists = await _dbManager?.getAllPlaylists();
    if (rustPlaylists == null || rustPlaylists.isEmpty) {
      debugPrint("歌单列表为空");
      return [];
    }

    final List<Playlist> finalPlaylists = [];

    for (var rp in rustPlaylists) {
      finalPlaylists.add(
        Playlist(
          id: rp.id,
          name: rp.name,
          description: rp.description,
          coverPath: rp.coverPath,
          isSystem: rp.isSystem == 1,
          songIds: rp.ids,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            rp.createdAt.toInt() * 1000,
            isUtc: true,
          ).toLocal(),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            rp.updatedAt.toInt() * 1000,
            isUtc: true,
          ).toLocal(),
        ),
      );
    }

    return finalPlaylists;
  }

  Future<List<String>> getHistoryIds() async {
    final ids = await _dbManager?.getPlayHistory();
    if (ids == null || ids.isEmpty) return [];
    return ids;
  }

  Future<void> clearHistory() async {
    await _dbManager?.clearHistory();
    _playlistUpdateController.add(null);
  }

  Future<void> deletePlaylist(String id) async {
    await _dbManager?.deletePlaylist(playlistId: id);
    _playlistUpdateController.add(null);
  }

  Future<void> renamePlaylist(String id, String newName) async {
    await _dbManager?.updatePlaylist(id: id, name: newName);
    _playlistUpdateController.add(null);
  }

  Future<void> updatePlaylist(
    String id,
    String name, {
    String? desc,
    String? coverPath,
  }) async {
    await _dbManager?.updatePlaylist(
      id: id,
      name: name,
      description: desc,
      coverPath: coverPath,
    );
    _playlistUpdateController.add(null);
  }

  Future<void> addMusicToPlaylist(String playlistId, String musicId) async {
    await _dbManager?.addSongToPlaylist(
      playlistId: playlistId,
      musicId: musicId,
    );
    _playlistUpdateController.add(null);
  }

  Future<void> addMusicToHistory(String musicId, int maxLimit) async {
    await _dbManager?.addToHistory(musicId: musicId, maxLimit: maxLimit);
    _playlistUpdateController.add(null);
  }

  Future<void> toggleMusicFavorite(String musicId) async {
    await _dbManager?.toggleSongFavorite(musicId: musicId);
    _playlistUpdateController.add(null);
  }

  Future<void> removeFromPlaylist(String playlistId, String musicId) async {
    await _dbManager?.removeSongFromPlaylist(
      playlistId: playlistId,
      musicId: musicId,
    );
    _playlistUpdateController.add(null);
  }

  Future<void> insertNetworkSong({
    required String id,
    required String title,
    required String artist,
    required String url,
    String? coverUrl,
    String? lyrics,
    int durationMs = 0,
  }) async {
    await _dbManager?.insertSong(
      music: rust_db.MusicInfo(
        id: id,
        title: title,
        artist: artist,
        album: null,
        durationMs: durationMs,
        coverPath: coverUrl,
        lyrics: lyrics,
        path: url,
      ),
    );
    debugPrint('[MusicDbService] insertNetworkSong: $id');
  }
}
