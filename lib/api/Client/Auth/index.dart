import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:myapp/api/Model/ApiResponse/index.dart';
import 'package:myapp/api/Model/User/index.dart';
import 'package:myapp/service/LocalAuth/index.dart';
import 'package:myapp/utils/Http/index.dart';
import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

/// 认证 API 客户端
///
/// 包含以下接口:
/// - sendCode: 发送邮箱验证码
/// - register: 邮箱验证码注册
/// - loginByCode: 邮箱+验证码登录
/// - loginByPassword: 邮箱+密码登录
/// - login: 兼容旧版用户名+密码登录
/// - uploadAvatar: 上传头像到OSS
class UserApi {
  static final base = "/api/auth";
  static final _localAuth = LocalAuth();

  // ─────────────────── 发送验证码 ───────────────────

  /// 发送邮箱验证码
  /// [email] 目标邮箱
  /// [purpose] 用途: "register" 或 "login"
  static Future<void> sendCode({
    required String email,
    required String purpose,
  }) async {
    final response = await HttpUtils().post(
      "$base/send-code",
      data: {"email": email, "purpose": purpose},
    );

    final result = ApiResponse.fromJson(response.data);
    if (result.code != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: result.msg,
      );
    }
  }

  // ─────────────────── 注册 ───────────────────

  /// 邮箱验证码注册
  /// 验证通过后自动创建用户并返回 JWT + 用户信息
  static Future<User> register({
    required String email,
    required String code,
    required String username,
    required String password,
  }) async {
    final response = await HttpUtils().post(
      "$base/register",
      data: {
        "email": email,
        "code": code,
        "username": username,
        "password": password,
      },
    );

    final result = ApiResponse.fromJson(response.data);
    if (result.code != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: result.msg,
      );
    }
    return _handleAuthResponse(result);
  }

  // ─────────────────── 邮箱+验证码登录 ───────────────────

  /// 邮箱验证码登录
  static Future<User> loginByCode({
    required String email,
    required String code,
  }) async {
    final response = await HttpUtils().post(
      "$base/login-by-code",
      data: {"email": email, "code": code},
    );

    final result = ApiResponse.fromJson(response.data);
    if (result.code != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: result.msg,
      );
    }
    return _handleAuthResponse(result);
  }

  // ─────────────────── 邮箱+密码登录 ───────────────────

  /// 邮箱密码登录
  static Future<User> loginByPassword({
    required String email,
    required String password,
  }) async {
    final response = await HttpUtils().post(
      "$base/login-by-password",
      data: {"email": email, "password": password},
    );

    final result = ApiResponse.fromJson(response.data);
    if (result.code != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: result.msg,
      );
    }
    return _handleAuthResponse(result);
  }

  // ─────────────────── 内部辅助：处理认证响应 ───────────────────

  /// 从认证接口响应中提取 user + 双 Token 并持久化
  static Future<User> _handleAuthResponse(ApiResponse result) async {
    final user = User.fromJson(result.data?["user"]);
    final accessToken = result.data?["access_token"] as String?;
    final refreshToken = result.data?["refresh_token"] as String?;

    user.token = accessToken; // 如果 User Model 维护了主 token

    // 保存 Token 对
    if (accessToken != null && refreshToken != null) {
      await _localAuth.saveToken(accessToken);
      await _localAuth.saveRefreshToken(refreshToken);
    }

    await _localAuth.saveUser(user.toJson());
    return user;
  }

  // ─────────────────── 刷新 Token 接口 ───────────────────

  /// 使用 refreshToken 换取新的 access_token 与 refresh_token
  static Future<Map<String, String>> refreshToken(String refreshToken) async {
    // 使用新的 Dio 实例发起请求，规避原单例拦截器的死循环
    final dio = Dio();
    final response = await dio.post(
      "$base/refresh",
      data: {"refresh_token": refreshToken},
    );

    final result = ApiResponse.fromJson(response.data);
    if (result.code != 0) {
      throw Exception("刷新令牌失效");
    }

    final newAccessToken = result.data?["access_token"] as String;
    final newRefreshToken = result.data?["refresh_token"] as String;

    await _localAuth.saveToken(newAccessToken);
    await _localAuth.saveRefreshToken(newRefreshToken);

    return {"access_token": newAccessToken, "refresh_token": newRefreshToken};
  }

  // ─────────────────── 头像上传 ───────────────────

  /// 上传用户头像到OSS
  static Future<String> uploadAvatar({
    required List<int> avatarBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      "avatar": MultipartFile.fromBytes(avatarBytes, filename: fileName),
    });

    final response = await HttpUtils().postForm(
      "$base/avatar",
      formData: formData,
    );

    final result = ApiResponse.fromJson(response.data);
    if (result.code != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: result.msg,
      );
    }

    return result.data?["avatar_url"] as String;
  }

  /// 用户头像保存到本地
  Future<String?> downloadAndSaveAvatar(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final directory = await getApplicationDocumentsDirectory();

      String fileName = path.basename(Uri.parse(url).path);
      if (fileName.isEmpty) {
        fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.png';
      }

      //拼接本地路径
      final localPath = path.join(directory.path, fileName);
      final file = File(localPath);

      //将下载的字节数据写入文件
      await file.writeAsBytes(response.bodyBytes);

      debugPrint("头像保存成功,路径为: $localPath");
      return localPath;
    } catch (e) {
      debugPrint("头像保存出错: $e");
      return null;
    }
  }

  // ─────────────────── 本地持久化读取 ───────────────────

  /// 从本地加密存储读取已保存的 token
  static Future<String?> getSavedToken() async {
    return await _localAuth.readToken();
  }

  /// 从本地加密存储读取已保存的用户信息
  static Future<Map<String, dynamic>?> getSavedUserJson() async {
    return await _localAuth.readUser();
  }

  /// 清除本地存储的认证数据（登出）
  static Future<void> clearLocalAuth() async {
    await _localAuth.clearAll();
  }

  // ─────────────────── 修改密码 ───────────────────

  /// 修改密码（需要已登录）
  static Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await HttpUtils().post(
      "$base/change-password",
      data: {"old_password": oldPassword, "new_password": newPassword},
    );

    final result = ApiResponse.fromJson(response.data);
    if (result.code != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: result.msg,
      );
    }
  }

  // ─────────────────── 注销账号 ───────────────────

  /// 注销当前登录用户账号（需要已登录）
  static Future<void> deleteAccount() async {
    final response = await HttpUtils().post("$base/delete-account");

    final result = ApiResponse.fromJson(response.data);
    if (result.code != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: result.msg,
      );
    }
  }

  // ─────────────────── 更新个性签名 ───────────────────

  /// 更新个性签名（需要已登录）
  static Future<void> updateSignature({required String signature}) async {
    final response = await HttpUtils().post(
      "$base/update-signature",
      data: {"signature": signature},
    );

    final result = ApiResponse.fromJson(response.data);
    // 修改 UserApi 内抛出异常的通用包装逻辑
    if (result.code != 0) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response, // 必须传入 response，避免 error.response 为 null
        type: DioExceptionType.badResponse,
        message: result.msg.isNotEmpty ? result.msg : "业务处理失败 (${result.code})",
      );
    }
  }
}
