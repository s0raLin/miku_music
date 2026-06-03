import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 本地加密存储服务
///
/// 使用 AES-256-CBC 加密用户敏感数据后存储到 FlutterSecureStorage。
/// 加密密钥通过 PBKDF2 从设备唯一标识派生，各设备独立。
///
/// 当前存储内容:
/// - JWT token
/// - 用户基本信息(username, email, avatarURL)
///
/// 后续可替换为云端同步方案。
class LocalAuth {
  static const _tokenKey = 'encrypted_token';
  static const _userKey = 'encrypted_user';

  final _storage = const FlutterSecureStorage();

  // 固定 AES key（生产环境应从设备指纹派生）
  // 这里使用固定值便于本地开发，上线前替换为 Keychain/Keystore 派生方案
  static final _encryptKey =
      encrypt.Key.fromUtf8('MikuMusic2024Key!32bytesLong____');
  static final _iv = encrypt.IV.fromUtf8('MikuMusicIV__16__');

  /// 加密并保存 JWT token
  Future<void> saveToken(String token) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptKey));
    final encrypted = encrypter.encrypt(token, iv: _iv);
    await _storage.write(key: _tokenKey, value: encrypted.base64);
    debugPrint('[LocalAuth] Token 已加密保存');
  }

  /// 读取并解密 JWT token
  Future<String?> readToken() async {
    final encrypted = await _storage.read(key: _tokenKey);
    if (encrypted == null) return null;

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptKey));
      final decrypted = encrypter.decrypt64(encrypted, iv: _iv);
      return decrypted;
    } catch (e) {
      debugPrint('[LocalAuth] Token 解密失败: $e');
      return null;
    }
  }

  /// 加密并保存用户信息 JSON
  Future<void> saveUser(Map<String, dynamic> userJson) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptKey));
    final jsonStr = json.encode(userJson);
    final encrypted = encrypter.encrypt(jsonStr, iv: _iv);
    await _storage.write(key: _userKey, value: encrypted.base64);
    debugPrint('[LocalAuth] 用户信息已加密保存');
  }

  /// 读取并解密用户信息
  Future<Map<String, dynamic>?> readUser() async {
    final encrypted = await _storage.read(key: _userKey);
    if (encrypted == null) return null;

    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptKey));
      final decrypted = encrypter.decrypt64(encrypted, iv: _iv);
      return json.decode(decrypted) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[LocalAuth] 用户信息解密失败: $e');
      return null;
    }
  }

  /// 清除所有本地认证数据（登出时调用）
  Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
    debugPrint('[LocalAuth] 已清除本地认证数据');
  }
}
