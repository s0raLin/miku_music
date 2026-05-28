import 'dart:convert';
import 'dart:typed_data';

class Playlist {
  final String id;
  final String name;
  final String? description;
  Uint8List? coverBytes;
  String? coverPath;
  final List<String> songIds;
  final bool isSystem;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.coverBytes,
    required this.coverPath,
    required this.songIds,
    this.isSystem = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    Uint8List? coverBytes,
    String? coverPath,
    List<String>? songIds,
    bool? isSystem,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverBytes: coverBytes ?? this.coverBytes,
      coverPath: coverPath ?? this.coverPath,
      songIds: songIds ?? this.songIds,
      isSystem: isSystem ?? this.isSystem,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      // 'songIds': songIds,
      'isSystem': isSystem,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Playlist.fromNeteaseJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'].toString(),
      name: json['name'] ?? '未知歌单',
      description: json['description'],
      // 封面需要异步下载，这里先初始化为空，或者修改模型支持 URL
      coverBytes: null,
      coverPath: '',
      // 原始数据里没给歌曲列表，先给个空集
      songIds: [],
      // specialType 为 5 通常是网易云的“我喜欢的音乐”系统歌单
      isSystem: json['specialType'] == 5,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createTime']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updateTime']),
    );
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      coverPath: '',
      songIds: List<String>.from(json['songIds'] ?? []),
      isSystem: json['isSystem'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Convert to SharedPreferences-compatible format (store as JSON string)
  String toSerializedString() {
    return jsonEncode(toJson());
  }

  factory Playlist.fromSerializedString(String str) {
    return Playlist.fromJson(jsonDecode(str));
  }

  @override
  String toString() =>
      "Playlist(id: $id, name: $name, description: $description, songIds: $songIds, isSystem: $isSystem, createdAt: $createdAt, updatedAt: $updatedAt)";
}
