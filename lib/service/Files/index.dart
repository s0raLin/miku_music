import 'dart:io';

import 'package:mime/mime.dart';

class MusicScanner {
  static Future<List<FileSystemEntity>> scanDirectory(String selectedDirectory) async {

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
}
