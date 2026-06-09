import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/api/Model/Music/index.dart';
import 'package:myapp/model/Toplist/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/utils/Http/index.dart';

class MusicApi {
  /// 获取排行榜数据 (调用 /api/toplist)
  static Future<ToplistInfo?> fetchToplist() async {
    try {
      final response = await HttpUtils().get("/api/toplist");
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        if (data['code'] == 200) {
          return ToplistInfo.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      debugPrint("获取排行榜失败: $e");
      return null;
    }
  }

  static Future<void> pickAndUploadMusic() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'flac', 'wav', 'm4a', 'ogg', 'aac'],
    );

    if (result == null) {
      return;
    }
    final filePath = result.files.single.path;
    if (filePath == null) {
      return;
    }
    final fileName = result.files.single.name;

    final music = await MusicService.parse(filePath);

    FormData formData = FormData.fromMap({
      "audio": await MultipartFile.fromFile(filePath, filename: fileName),
      "title": music.title,
      "artist": music.artist,
      "album": music.album,
      "duration": music.duration.inSeconds.toString(),
      if (music.coverBytes != null)
        "cover": MultipartFile.fromBytes(
          music.coverBytes!,
          filename: "cover.jpg",
        ),
    });

    final response = await HttpUtils().postForm(
      "/api/music",
      formData: formData,
      onSendProgress: (int sent, int total) {
        debugPrint("上传进度: ${(sent / total * 100).round()}%");
      },
    );

    if (response.statusCode == 200) {
      debugPrint("上传成功: ${response.data}");
    } else {
      debugPrint("上传失败");
    }
  }

  static Future<List<Music>> listMusic() async {
    final response = await HttpUtils().get("/api/music");

    if (response.statusCode == 200) {
      debugPrint("获取成功: ${response.data}");
      List dataList = response.data["data"];
      List<Music> musics =
          dataList.map((item) => Music.fromJson(item)).toList();
      return musics;
    } else {
      throw Exception("获取失败: ${response.statusMessage}");
    }
  }

  static Future<(String, bool)> searchLyrics(
    String? artist,
    String? title,
  ) async {
    String syncedLyrics = '无滚动歌词';
    if (artist == "" || title == "") return (syncedLyrics, false);

    final dio = Dio();
    try {
      final response = await dio.get(
        'https://lrclib.net/api/get',
        queryParameters: {'artist_name': artist, 'track_name': title},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        syncedLyrics = data['syncedLyrics'] ?? '';
        if (syncedLyrics.isEmpty) return ("", false);
      }
    } on DioException catch (e) {
      debugPrint("未找到歌词: $e");
      return ("", false);
    }
    return (syncedLyrics, true);
  }
}
