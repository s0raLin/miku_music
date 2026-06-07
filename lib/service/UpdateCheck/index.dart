import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

class ReleaseInfo {
  final String tagName;
  final String description;
  final String htmlUrl;
  final String cloudDriveUrl;
  final String cloudDrivePassword;

  const ReleaseInfo({
    required this.tagName,
    required this.description,
    required this.htmlUrl,
    required this.cloudDriveUrl,
    required this.cloudDrivePassword,
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
  static const String _repoOwner = 's0raLin';
  static const String _repoName = 'miku_music';

  /// 防止同一应用生命周期内重复弹窗
  static bool _hasCheckedThisSession = false;

  final Dio _dio;

  UpdateCheckService._({required Dio dio}) : _dio = dio;

  static UpdateCheckService? _instance;

  static UpdateCheckService get instance {
    _instance ??= UpdateCheckService._(
      dio: Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Accept': 'application/vnd.github.v3+json'},
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
      final response = await _dio.get(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases',
        queryParameters: {'per_page': 5},
      );

      if (response.statusCode != 200) {
        debugPrint('⚠️ GitHub API 返回非 200: ${response.statusCode}');
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersionStr,
        );
      }

      final List releases = response.data as List;
      if (releases.isEmpty) {
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersionStr,
        );
      }

      // 取最新的 release 做版本比较
      final latestRelease = releases.first as Map<String, dynamic>;

      final tagName = latestRelease['tag_name'] as String? ?? '';
      final remoteVersionStr =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;
      final remoteVersion = _parseVersion(remoteVersionStr);

      if (remoteVersion == null) {
        debugPrint('⚠️ 无法解析远程版本号: $remoteVersionStr');
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersionStr,
        );
      }

      if (remoteVersion <= currentVersion) {
        debugPrint('✅ 当前已是最新版本: $currentVersionStr');
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersionStr,
        );
      }

      final body = latestRelease['body'] as String? ?? '';
      final description = body.length > 500
          ? '${body.substring(0, 500)}...'
          : body;

      final cloudUrl = dotenv.get('CLOUD_DRIVE_URL', fallback: '');
      final cloudPwd = dotenv.get('CLOUD_DRIVE_PASSWORD', fallback: '');

      return UpdateCheckResult(
        hasUpdate: true,
        currentVersion: currentVersionStr,
        latestRelease: ReleaseInfo(
          tagName: tagName,
          description: description,
          htmlUrl: latestRelease['html_url'] as String? ?? '',
          cloudDriveUrl: cloudUrl,
          cloudDrivePassword: cloudPwd,
        ),
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
