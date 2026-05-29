import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermissionKey {
  audio,
  storage,
}

class AppPermissionState {
  final Permission permission;
  final PermissionStatus status;

  const AppPermissionState({required this.permission, required this.status});

  bool get isGranted => status.isGranted || status.isLimited;
  bool get isDenied => status.isDenied;
  bool get isPermanentlyDenied => status.isPermanentlyDenied;
  bool get isRestricted => status.isRestricted;
}

class PermissionService {
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static Permission _permissionFor(AppPermissionKey key) {
    switch (key) {
      case AppPermissionKey.audio:
        return Permission.audio;
      case AppPermissionKey.storage:
        return Permission.storage;
    }
  }

  static Future<AppPermissionState> getStatus(AppPermissionKey key) async {
    if (!isAndroid) {
      return AppPermissionState(
        permission: _permissionFor(key),
        status: PermissionStatus.granted,
      );
    }
    final p = _permissionFor(key);
    final status = await p.status;
    return AppPermissionState(permission: p, status: status);
  }

  static Future<Map<AppPermissionKey, AppPermissionState>> getAllStatuses() async {
    final audio = await getStatus(AppPermissionKey.audio);
    final storage = await getStatus(AppPermissionKey.storage);
    return {
      AppPermissionKey.audio: audio,
      AppPermissionKey.storage: storage,
    };
  }

  static Future<AppPermissionState> request(AppPermissionKey key) async {
    if (!isAndroid) {
      return AppPermissionState(
        permission: _permissionFor(key),
        status: PermissionStatus.granted,
      );
    }
    final p = _permissionFor(key);
    final status = await p.request();
    return AppPermissionState(permission: p, status: status);
  }

  static Future<Map<AppPermissionKey, AppPermissionState>> requestAll() async {
    if (!isAndroid) {
      final all = await getAllStatuses();
      return all;
    }
    final statuses = await [
      _permissionFor(AppPermissionKey.audio),
      _permissionFor(AppPermissionKey.storage),
    ].request();

    return {
      AppPermissionKey.audio: AppPermissionState(
        permission: _permissionFor(AppPermissionKey.audio),
        status: statuses[_permissionFor(AppPermissionKey.audio)] ??
            PermissionStatus.denied,
      ),
      AppPermissionKey.storage: AppPermissionState(
        permission: _permissionFor(AppPermissionKey.storage),
        status: statuses[_permissionFor(AppPermissionKey.storage)] ??
            PermissionStatus.denied,
      ),
    };
  }

  /// 读取本地音频的最低权限要求：
  /// - Android 13+：通常需要音频媒体权限（READ_MEDIA_AUDIO）
  /// - Android 12-：通常需要存储权限（READ_EXTERNAL_STORAGE）
  ///
  /// 这里采用 “audio 或 storage 任意一个通过即可” 的策略，避免旧设备/新设备差异导致卡死。
  static Future<bool> hasAnyMediaAccess() async {
    if (!isAndroid) return true;
    final s = await getAllStatuses();
    return (s[AppPermissionKey.audio]?.isGranted ?? false) ||
        (s[AppPermissionKey.storage]?.isGranted ?? false);
  }

  static Future<void> openSystemSettings() async {
    if (!isAndroid) return;
    await openAppSettings();
  }
}

