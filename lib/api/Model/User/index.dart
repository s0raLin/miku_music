import 'package:json_annotation/json_annotation.dart';

part 'index.g.dart';

/// 用户模型 - 与后端 User struct 对应
/// 注册和登录成功后后端返回的 user 对象
@JsonSerializable()
class User {
  /// 数据库主键 ID
  @JsonKey(name: 'ID')
  final int? id;

  final String username;

  /// 头像 OSS URL，可能为 null
  final String? avatarURL;

  final String email;

  /// JWT token，从登录/注册响应中获取，不存储在后端
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? token;

  User({
    this.id,
    required this.username,
    required this.avatarURL,
    required this.email,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
