import 'dart:convert';
import 'dart:typed_data';

class Music {
  final String id;
  final String title; // 标题
  final String artist; // 歌手
  final Duration duration; // 时长
  Uint8List? coverBytes; // 封面
  String? lyrics; // 歌词
  final String? album;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.coverBytes,
    required this.lyrics,
    this.album,
  });

  /// 核心实现：copyWith 方法
  Music copyWith({
    String? id,
    String? title,
    String? artist,
    Duration? duration,
    Uint8List? coverBytes, // 允许传入新的封面或保持原样
    String? lyrics, // 允许传入新的歌词或保持原样
    String? album,
  }) {
    return Music(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      // 如果外部传入了 coverBytes（哪怕传的是 null），就用外部的；如果没传该参数，才保留旧值
      coverBytes: coverBytes ?? this.coverBytes,
      lyrics: lyrics ?? this.lyrics,
      album: album ?? this.album,
    );
  }

  // 将对象转换为 Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'duration_ms': duration.inMilliseconds,
      'cover': coverBytes != null ? base64Encode(coverBytes!) : null,
      'lyrics': lyrics,
      'album': album,
    };
  }
}
