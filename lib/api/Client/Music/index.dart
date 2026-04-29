import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:myapp/service/Music/index.dart';

class MusicApi {
  static final Dio _dio = Dio();

  static Future<void> pickAndUploadMusic() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom, //使用自定义模式
      allowedExtensions: ['mp3', 'flac', 'wav', 'm4a', 'ogg', 'aac'],
    );

    if (result == null && result?.files.single.path == null) {
      return;
    }
    final filePath = result?.files.single.path!;
    final fileName = result?.files.single.name;

    if (filePath == null || filePath.isEmpty) {
      return; //用户取消上传
    }
    final music = await MusicService.parse(filePath);

    FormData formData = FormData.fromMap({
      "audio": await MultipartFile.fromFile(filePath, filename: fileName),
      "title": music.title,
      "artist": music.artist,
      "album": music.album,
      "duration": music.duration.inSeconds.toString(),
      "cover": music.coverBytes != null
          ? base64Encode(music.coverBytes!)
          : null,
    });

    final response = await _dio.post(
      "http://localhost:8080/api/music",
      data: formData,
      onSendProgress: (int sent, int total) {
        // 这里可以计算进度：(sent / total * 100).toStringAsFixed(0)%
        print("上传进度: ${(sent / total * 100).round()}%");
      },
    );

    if (response.statusCode == 200) {
      print("上传成功: ${response.data}");
    } else {
      print("上传失败");
    }
  }
}
