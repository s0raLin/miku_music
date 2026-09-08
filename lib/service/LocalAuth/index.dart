import 'dart:convert';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 本地加密存储服务
///
/// 使用 AES-256-CBC 加密用户敏感数据后存储到 FlutterSecureStorage。
class LocalAuth {
  static const _tokenKey = 'encrypted_token';
  static const _keyRefreshToken = 'encrypted_refresh_token';
  static const _userKey = 'encrypted_user';

  final _storage = const FlutterSecureStorage();

  // 固定 AES key（生产环境应从设备指纹派生）
  static final _encryptKey = encrypt.Key.fromUtf8(
    'MikuMusic2024Key!32bytesLong____',
  );
  static final _iv = encrypt.IV.fromUtf8('MikuMusicIV_16__');

  // ─────────────────── 通用加解密辅助方法 ───────────────────

  String? _encrypt(String plainText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptKey));
      return encrypter.encrypt(plainText, iv: _iv).base64;
    } catch (e) {
      debugPrint('[LocalAuth] 加密失败: $e');
      return null;
    }
  }

  String? _decrypt(String encryptedText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptKey));
      return encrypter.decrypt64(encryptedText, iv: _iv);
    } catch (e) {
      debugPrint('[LocalAuth] 解密失败: $e');
      return null;
    }
  }

  // ─────────────────── Access Token ───────────────────

  /// 加密并保存 Access Token
  Future<void> saveToken(String token) async {
    final encrypted = _encrypt(token);
    if (encrypted != null) {
      await _storage.write(key: _tokenKey, value: encrypted);
      debugPrint('[LocalAuth] Access Token 已加密保存');
    }
  }

  /// 读取并解密 Access Token
  Future<String?> readToken() async {
    final encrypted = await _storage.read(key: _tokenKey);
    if (encrypted == null) return null;
    return _decrypt(encrypted);
  }

  // ─────────────────── Refresh Token ───────────────────

  /// 加密并保存 Refresh Token
  Future<void> saveRefreshToken(String refreshToken) async {
    final encrypted = _encrypt(refreshToken);
    if (encrypted != null) {
      await _storage.write(key: _keyRefreshToken, value: encrypted);
      debugPrint('[LocalAuth] Refresh Token 已加密保存');
    }
  }

  /// 读取并解密 Refresh Token
  Future<String?> readRefreshToken() async {
    final encrypted = await _storage.read(key: _keyRefreshToken);
    if (encrypted == null) return null;
    return _decrypt(encrypted);
  }

  // ─────────────────── 双 Token 快捷操作 ───────────────────

  /// 同时加解密保存双 Token
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await saveToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  // ─────────────────── 用户信息 ───────────────────

  /// 加密并保存用户信息 JSON
  Future<void> saveUser(Map<String, dynamic> userJson) async {
    final jsonStr = json.encode(userJson);
    final encrypted = _encrypt(jsonStr);
    if (encrypted != null) {
      await _storage.write(key: _userKey, value: encrypted);
      debugPrint('[LocalAuth] 用户信息已加密保存');
    }
  }

  /// 读取并解密用户信息
  Future<Map<String, dynamic>?> readUser() async {
    final encrypted = await _storage.read(key: _userKey);
    if (encrypted == null) return null;

    final jsonStr = _decrypt(encrypted);
    if (jsonStr == null) return null;

    try {
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[LocalAuth] 用户 JSON 解析失败: $e');
      return null;
    }
  }

  // ─────────────────── 清除数据 ───────────────────

  /// 清除所有本地认证数据（登出时调用）
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _keyRefreshToken); // 修复：补充清除 refresh_token
      await _storage.delete(key: _userKey);
      debugPrint('[LocalAuth] 已清除所有本地认证数据');
    } catch (e) {
      debugPrint('[LocalAuth] 清除本地认证数据失败: $e');
    }
  }
}
