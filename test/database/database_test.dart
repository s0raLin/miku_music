import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/src/rust/api/audio_db.dart';
import 'package:myapp/src/rust/frb_generated.dart';

void main() {
  setUpAll(() async {
    await RustLib.init();
  });

  group("DbManager Tests", () {
    const testDbPath = './test_music.db';

    // 每次测试完把测试数据库删掉，保持测试环境干净
    tearDown(() async {
      final file = File(testDbPath);
      if (await file.exists()) {
        await file.delete();
      }
    });
    test("插入歌曲并验证", () async {
      try {
        final dbManager = await DbManager.newInstance(
          dbPath: "./test_music_cache.db",
        );

        // 3. 构造歌曲数据
        final song = MusicInfo(
          id: "song_12345",
          title: "夜曲",
          artist: "周杰伦",
          album: "十一月的萧邦",
          durationMs: 238000,
          coverPath: "/absolute/path/to/cover.jpg",
          lyrics: "一群嗜血的蚂蚁...",
          path: "/absolute/path/to/music.mp3",
        );

        await dbManager.insertSong(music: song);

        debugPrint("插入歌曲成功");
      } catch (e) {
        debugPrint("发生错误: $e");
      }
    });

    test("查找歌曲", () async {
      final dbManager = await DbManager.newInstance(dbPath: "./music_cache.db");

      final song = await dbManager.getSong(id: "song_12345");
      expect(song, isNotNull, reason: "数据库应该能查到这首歌");
      debugPrint("歌曲标题: ${song!.title}");
    });
  });
}
