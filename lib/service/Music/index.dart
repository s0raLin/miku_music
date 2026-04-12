import 'dart:io';
import 'dart:typed_data';

import 'package:audiotags/audiotags.dart';
import 'package:mime/mime.dart';
import 'package:myapp/model/Music/index.dart';

class MusicScanner {
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

      duration: Duration(milliseconds: tag?.duration ?? 0),
      cover: coverBytes,
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
