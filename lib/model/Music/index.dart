import 'dart:typed_data';

class MusicInfo {
  final String title; // 标题
  final String artist; // 歌手
  final Duration duration; // 专辑
  final Uint8List? cover; // 时长
  final String? lyrics; // 歌词

  MusicInfo({
    required this.title,
    required this.artist,
    required this.duration,
    required this.cover,
    required this.lyrics,
  }); 
}
