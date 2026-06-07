import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

class ReleaseInfo {
  final String tagName;
  final String name;
  final String description;
  final String htmlUrl;
  final String? apkDownloadUrl;

  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.description,
    required this.htmlUrl,
    this.apkDownloadUrl,
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
  static bool get isSupportedPlatform =>
      !kIsWeb && Platform.isAndroid;

  /// 检查是否有新版本可用（整个应用生命周期只执行一次有效检查）
  /// 返回 [UpdateCheckResult]
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
      // 获取 GitHub Releases（仅取最新 5 条，减少网络开销）
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

      // 找到最新的带有 APK 的 release
      Map<String, dynamic>? latestReleaseWithApk;
      for (final release in releases) {
        final assets = release['assets'] as List? ?? [];
        final hasApk = assets.any(
          (a) => (a['name'] as String? ?? '').endsWith('.apk'),
        );
        if (hasApk) {
          latestReleaseWithApk = release as Map<String, dynamic>;
          break;
        }
      }

      if (latestReleaseWithApk == null) {
        debugPrint('ℹ️ 未找到包含 APK 的发布版本');
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVersionStr,
        );
      }

      // 解析远程版本号（去掉 'v' 前缀）
      final tagName = latestReleaseWithApk['tag_name'] as String? ?? '';
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

      // 版本比较
      final hasUpdate = remoteVersion > currentVersion;

      if (hasUpdate) {
        // 查找 APK 下载链接
        final assets = latestReleaseWithApk['assets'] as List? ?? [];
        String? apkUrl;
        for (final a in assets) {
          if ((a['name'] as String? ?? '').endsWith('.apk')) {
            apkUrl = a['browser_download_url'] as String?;
            break;
          }
        }

        // 提取 release 描述（取 body 前 500 字符作为摘要）
        final body = latestReleaseWithApk['body'] as String? ?? '';
        final description = body.length > 500
            ? '${body.substring(0, 500)}...'
            : body;

        return UpdateCheckResult(
          hasUpdate: true,
          currentVersion: currentVersionStr,
          latestRelease: ReleaseInfo(
            tagName: tagName,
            name: latestReleaseWithApk['name'] as String? ?? tagName,
            description: description,
            htmlUrl: latestReleaseWithApk['html_url'] as String? ?? '',
            apkDownloadUrl: apkUrl,
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

  /// 安全解析版本号
  Version? _parseVersion(String versionStr) {
    try {
      // package_info_plus 返回的版本格式可能是 "1.2.3" 或 "1.2.3+45"
      // Version 包支持 "1.2.3+45" 格式
      return Version.parse(versionStr);
    } catch (e) {
      debugPrint('⚠️ 版本解析失败: $versionStr, error: $e');
      return null;
    }
  }
}
