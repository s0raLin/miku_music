import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:myapp/api/Model/Music/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/utils/Http/index.dart';

class MusicApi {
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
        print("上传进度: ${(sent / total * 100).round()}%");
      },
    );

    if (response.statusCode == 200) {
      print("上传成功: ${response.data}");
    } else {
      print("上传失败");
    }
  }

  static Future<List<Music>> listMusic() async {
    final response = await HttpUtils().get("/api/music");

    if (response.statusCode == 200) {
      print("获取成功: ${response.data}");
      List dataList = response.data["data"];
      List<Music> musics = dataList
          .map((item) => Music.fromJson(item))
          .toList();
      return musics;
    } else {
      throw Exception("获取失败: ${response.statusMessage}");
    }
  }
}
