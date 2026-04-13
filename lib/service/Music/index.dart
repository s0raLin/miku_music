import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:mime/mime.dart';
import 'package:myapp/model/Music/index.dart';

class MusicService {
  static Future<MusicInfo> getSongById(String id) async {
    //模拟本地延迟
    await Future.delayed(const Duration(milliseconds: 500));

    return MusicInfo(
      title: '千本桜',
      artist: '黒うさP / 初音ミク',
      album: 'ALL THAT 千本桜',
      duration: const Duration(seconds: 245),
      coverBytes: null, // 实际开发中通过文件读取或网络获取
      lyrics:
          "[00:00.00]千本桜 夜ニ紛レ\n[00:05.00]君ノ声モ届カナイヨ\n[00:10.00]此処は宴 鋼の檻\n[00:15.00]その断頭台で見下ろして",
    );
  }

  static Future<MusicInfo> parse(String path) async {
    final Tag? tag = await AudioTags.read(path);

    String? lyrics = tag?.lyrics;
    String? artist = tag?.trackArtist ?? tag?.albumArtist ?? "未知歌手";
    Uint8List? coverBytes;
    if (tag?.pictures.isNotEmpty ?? false) {
      coverBytes = tag?.pictures.first.bytes;
    }

    return MusicInfo(
      title: tag?.title ?? "未知标题",
      artist: artist,
      album: tag?.album ?? "未知",

      duration: Duration(milliseconds: tag?.duration ?? 0),
      coverBytes: coverBytes,
      lyrics: lyrics,
    );
  }

  static Future<List<FileSystemEntity>> scanDirectory(
    String selectedDirectory,
  ) async {
    // 遍历文件夹
    final dir = Directory(selectedDirectory);

    try {
      List<FileSystemEntity> entities = dir.listSync(recursive: true);

      final List<File> musicFiles = entities.whereType<File>().where((file) {
        final mimeType = lookupMimeType(file.path);
        return mimeType != null && mimeType.startsWith("audio/");
      }).toList();
      return musicFiles;
    } catch (e) {
      return [];
    }
  }

  static Stream<MusicInfo> scanMusic(String selectedDirectory) async* {
    final musicFiles = await scanDirectory(selectedDirectory);

    for (var file in musicFiles) {
      try {
        //逐个解析
        final music = await parse(file.path);
        //解析完一个立即投递出去
        yield music;
      } catch (e) {
        //解析失败继续下一个
        continue;
      }
    }
  }
}
