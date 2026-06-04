import 'package:json_annotation/json_annotation.dart';

part 'index.g.dart';

class DurationConverter implements JsonConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int json) => Duration(seconds: json);

  @override
  int toJson(Duration object) => object.inSeconds;
}

@JsonSerializable()
class Music {
  final String title;
  final String? artist;
  final String? album;
  @DurationConverter()
  final Duration duration;
  final String ossKey;
  final String? coverUrl;
  final String? lyricUrl;

  Music({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.ossKey,
    required this.coverUrl,
    required this.lyricUrl,
  });

  factory Music.fromJson(Map<String, dynamic> json) => _$MusicFromJson(json);

  Map<String, dynamic> toJson() => _$MusicToJson(this);

  @override
  String toString() {
    return 'Music(title: $title, artist: $artist, album: $album, duration: $duration, ossKey: $ossKey, coverUrl: $coverUrl, lyricUrl: $lyricUrl)';
  }
}
