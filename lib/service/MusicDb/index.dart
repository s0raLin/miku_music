import 'dart:async';

import 'package:flutter/material.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/src/rust/api/audio_db.dart';
import 'package:path_provider/path_provider.dart';

class MusicDbService {
  // 1. 私有化构造函数，外界无法通过 `MusicDbService()` 随意 new 出来
  MusicDbService._internal();

  // 2. 静态唯一的全局实例
  static final MusicDbService _instance = MusicDbService._internal();

  // 3. 工厂构造函数永远返回这同一个实例
  factory MusicDbService() => _instance;

  // 4. 内部唯一的 _dbManager，在 init() 里只被初始化一次
  DbManager? _dbManager;

  //创建一个全局控制器,用来广播数据库表改变的信号
  final _playlistUpdateController = StreamController<void>.broadcast();
  Stream<void> get playlistUpdates => _playlistUpdateController.stream;

  Future<void> init() async {
    if (_dbManager != null) return; // 已经初始化过，直接拦截

    try {
      // 获取沙盒路径，并在其中创建 M3Music 的数据库文件
      final docDir = await getApplicationDocumentsDirectory();
      final dbPath = "${docDir.path}/m3_music.db";

      // ⚠️ 关键点：调用构造函数初始化 Rust 的 DbManager
      // 注：FRB 通常会额外生成一个静态方法或顶层构造函数，如 rust_api.DbManager.newInstance(dbPath: dbPath)
      // 如果你的本地没有 newInstance，可以直接看看生成文件里是否有类似 `crateApiAudioDbDbManagerNew({required String dbPath})` 的工厂方法。
      // 这里假设你用的是工厂方法或关联函数：
      _dbManager = await DbManager.newInstance(dbPath: dbPath);
      debugPrint("本地 SQLite 数据库初始化成功: $dbPath");
    } catch (e) {
      debugPrint("本地 SQLite 数据库初始化失败: $e");
    }
  }

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
            rp.createdAt.toInt() * 1000, // 因为 Rust 存的是秒，Dart 需要毫秒，所以乘以 1000
            isUtc: true, // 如果你 Rust 存的是 Utc 时间戳，建议带上
          ).toLocal(), // 自动转换为用户 Arch Linux / 手机系统所在的本地时区
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

  Future<void> deletePlaylist(String id) async {
    await _dbManager?.deletePlaylist(playlistId: id);
    _playlistUpdateController.add(null);
  }

  Future<void> renamePlaylist(String id, String newName) async {
    await _dbManager?.updatePlaylist(id: id, name: newName);
    _playlistUpdateController.add(null); //发射信号
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
    _playlistUpdateController.add(null); //发射信号
  }

  Future<void> addMusicToPlaylist(String playlistId, String musicId) async {
    await _dbManager?.addSongToPlaylist(
      playlistId: playlistId,
      musicId: musicId,
    );
    _playlistUpdateController.add(null);
  }

  Future<void> addMusicToHistory(String musicId) async {
    await _dbManager?.addToHistory(musicId: musicId);
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
}
