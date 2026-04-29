import 'dart:convert';
import 'dart:typed_data';

class MusicInfo {
  final String id;
  final String title; // 标题
  final String artist; // 歌手
  final Duration duration; // 时长
  final Uint8List? coverBytes; // 封面
  final String? lyrics; // 歌词
  final String? album;

  MusicInfo({
    required this.title,
    required this.artist,
    required this.duration,
    required this.coverBytes,
    required this.lyrics,
    this.album, required this.id,
  });

  // 将对象转换为 Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      // Duration 需要转换为毫秒或秒，后端才好处理
      'duration_ms': duration.inMilliseconds,
      // 封面：如果是二进制，需要转为 Base64 字符串
      'cover': coverBytes != null ? base64Encode(coverBytes!) : null,
      'lyrics': lyrics,
      'album': album,
    };
  }
}
