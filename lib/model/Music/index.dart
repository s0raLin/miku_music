import 'dart:convert';
import 'dart:typed_data';

enum MusicSource { local, network }

class Music {
  final String id;
  final String title; // 标题
  final String artist; // 歌手
  final Duration duration; // 时长
  Uint8List? coverBytes; // 本地/解包封面字节
  final String? coverUrl; // 网络封面 URL
  String? lyrics; // 歌词
  final String? album;
  final MusicSource source;

  Music({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    this.coverBytes,
    this.coverUrl,
    this.lyrics,
    this.album,
    this.source = MusicSource.local,
  });

  /// 核心实现：copyWith 方法
  Music copyWith({
    String? id,
    String? title,
    String? artist,
    Duration? duration,
    Uint8List? coverBytes,
    String? coverUrl,
    String? lyrics,
    String? album,
    MusicSource? source,
  }) {
    return Music(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      duration: duration ?? this.duration,
      coverBytes: coverBytes ?? this.coverBytes,
      coverUrl: coverUrl ?? this.coverUrl,
      lyrics: lyrics ?? this.lyrics,
      album: album ?? this.album,
      source: source ?? this.source,
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
      'cover_url': coverUrl,
      'lyrics': lyrics,
      'album': album,
      'source': source.name,
    };
  }

  // 从 Map 解析还原对象
  factory Music.fromJson(Map<String, dynamic> json) {
    return Music(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      duration: Duration(milliseconds: json['duration_ms'] as int? ?? 0),
      coverBytes: json['cover'] != null
          ? base64Decode(json['cover'] as String)
          : null,
      coverUrl: json['cover_url'] as String?,
      lyrics: json['lyrics'] as String?,
      album: json['album'] as String?,
      source: MusicSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => MusicSource.local,
      ),
    );
  }
}
