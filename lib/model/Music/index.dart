import 'dart:typed_data';

class MusicInfo {
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
    this.album,
  });
}
