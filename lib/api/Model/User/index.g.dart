// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'index.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// NOTE: This file is auto-generated. You should regenerate it after
// changing the User model by running:
//   flutter pub run build_runner build --delete-conflicting-outputs

User _$UserFromJson(Map<String, dynamic> json) => User(
  username: json['username'] as String,
  avatarURL: json['avatar'] as String?,
  email: json['email'] as String,
  token: json['token'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'username': instance.username,
  'avatar': instance.avatarURL,
  'email': instance.email,
  'token': instance.token,
};
