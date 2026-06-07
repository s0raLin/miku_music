import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

class ReleaseInfo {
  final String tagName;
  final String description;
  final String htmlUrl;

  const ReleaseInfo({
    required this.tagName,
    required this.description,
    required this.htmlUrl,
  });
}

class UpdateCheckResult {
  final bool hasUpdate;
  final ReleaseInfo? latestRelease;
  final String currentVersion;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.latestRelease,
    required this.currentVersion,
  });
}

class UpdateCheckService {
  /// jsDelivr CDN 加速的 version.json 地址（全球 CDN，国内可用）
  static const String _versionUrl =
      'https://cdn.jsdelivr.net/gh/s0raLin/miku_music@latest/version.json';

  /// 防止同一应用生命周期内重复弹窗
  static bool _hasCheckedThisSession = false;

  final Dio _dio;

  UpdateCheckService._({required Dio dio}) : _dio = dio;

  static UpdateCheckService? _instance;

  static UpdateCheckService get instance {
    _instance ??= UpdateCheckService._(
      dio: Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      )),
    );
    return _instance!;
  }

  /// 仅在 Android 平台执行更新检查
  static bool get isSupportedPlatform => !kIsWeb && Platform.isAndroid;

  /// 检查是否有新版本可用（整个应用生命周期只执行一次有效检查）
  Future<UpdateCheckResult> checkForUpdate() async {
    if (_hasCheckedThisSession) {
      return UpdateCheckResult(hasUpdate: false, currentVersion: '');
    }
    _hasCheckedThisSession = true;

    // 获取当前版本号
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersionStr = packageInfo.version;
    final currentVersion = _parseVersion(currentVersionStr);

    if (currentVersion == null) {
      debugPrint('⚠️ 无法解析当前版本号: $currentVersionStr');
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersionStr,
      );
    }

    try {
      // 从 jsDelivr CDN 获取 version.json（秒级响应，国内不卡）
      final response = await _dio.get(_versionUrl);

      if (response.statusCode != 200) {
        debugPrint('⚠️ CDN 返回非 200: ${response.statusCode}');
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersionStr,
        );
      }

      final data = response.data as Map<String, dynamic>;
      final remoteVersionStr = data['version'] as String?;
      final tagName = data['tag_name'] as String? ?? '';
      final htmlUrl = data['html_url'] as String? ?? '';
      final description = data['description'] as String? ?? '';

      if (remoteVersionStr == null || remoteVersionStr.isEmpty) {
        debugPrint('⚠️ version.json 中无有效版本号');
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersionStr,
        );
      }

      final remoteVersion = _parseVersion(remoteVersionStr);
      if (remoteVersion == null) {
        debugPrint('⚠️ 无法解析远程版本号: $remoteVersionStr');
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersionStr,
        );
      }

      // 版本比较
      final hasUpdate = remoteVersion > currentVersion;

      if (hasUpdate) {
        return UpdateCheckResult(
          hasUpdate: true,
          currentVersion: currentVersionStr,
          latestRelease: ReleaseInfo(
            tagName: tagName,
            description: description,
            htmlUrl: htmlUrl,
          ),
        );
      }

      debugPrint('✅ 当前已是最新版本: $currentVersionStr');
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersionStr,
      );
    } on DioException catch (e) {
      debugPrint('⚠️ 检查更新网络错误: ${e.message}');
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersionStr,
      );
    } catch (e) {
      debugPrint('⚠️ 检查更新异常: $e');
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVersionStr,
      );
    }
  }

  Version? _parseVersion(String versionStr) {
    try {
      return Version.parse(versionStr);
    } catch (e) {
      debugPrint('⚠️ 版本解析失败: $versionStr, error: $e');
      return null;
    }
  }
}
