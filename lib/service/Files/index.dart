import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class FileService {
  static const String _storageKey = "folder_path";

  /// Get the M3Music directory under the system Downloads folder.
  /// This is the default download & scan directory.
  /// 异步获取符合当前系统规范的 Downloads/M3Music 目录
  static Future<Directory> getM3MusicDir() async {
    Directory? downloadRoot;

    try {
      if (Platform.isAndroid) {
        // Android 专属：获取外部存储的公共下载目录
        downloadRoot = await getExternalStorageDirectory();
        // 提示：getExternalStorageDirectory() 通常返回 /storage/emulated/0/Android/data/包名/files
        // 如果你想去公共的 Download 文件夹，且处理了 Android 11+ 的分区存储权限，可以使用：
        // downloadRoot = Directory('/storage/emulated/0/Download');
        // 但最安全的跨平台做法是统一交由 path_provider 寻找可写目录：
      } else if (Platform.isIOS) {
        // iOS 没有公共下载目录，一般下载到文档目录下
        downloadRoot = await getApplicationDocumentsDirectory();
      } else {
        // Windows, macOS, Linux 桌面端
        downloadRoot = await getDownloadsDirectory();
      }
    } catch (e) {
      // 兜底方案：如果获取失败，使用临时目录，防止程序崩溃
      downloadRoot = await getTemporaryDirectory();
    }

    // 如果平台不支持 getDownloadsDirectory (比如某些特定环境)，换个普通文档目录兜底
    downloadRoot ??= await getApplicationDocumentsDirectory();

    return Directory(p.join(downloadRoot.path, 'M3Music'));
  }

  /// 因为 getM3MusicDir 变成了异步，这里对应的同步方法需要废弃或改为异步
  static Future<String> getM3MusicPath() async {
    final dir = await getM3MusicDir();
    return dir.path;
  }

  static Future savePaths(List<String> newPaths) async {
    final pfs = await SharedPreferences.getInstance();
    // final existing = pfs.getStringList(_storageKey) ?? [];
    //如果传入的是空列表,则清空该key
    if (newPaths.isEmpty) {
      await pfs.remove(_storageKey);
    } else {
      await pfs.setStringList(_storageKey, newPaths);
    }
    // 合并去重
    // final merged = {...existing, ...newPaths}.toList();
    // await pfs.setStringList(_storageKey, merged);
  }

  static Future<List<String>> loadPaths() async {
    final pfs = await SharedPreferences.getInstance();
    return pfs.getStringList(_storageKey) ?? [];
  }

  static Future<List<String>> loadPathsWithDefault() async {
    // Default: use M3Music under Downloads
    final m3MusicDir = await getM3MusicDir();
    if (!await m3MusicDir.exists()) {
      await m3MusicDir.create(recursive: true);
    }

    // Network cache directory (for persisted network song metadata/cache)
    final docDir = await getApplicationDocumentsDirectory();
    final networkCacheDir = Directory(p.join(docDir.path, 'network_cache'));
    if (!await networkCacheDir.exists()) {
      await networkCacheDir.create(recursive: true);
    }

    final saved = await loadPaths();
    final allPaths = <String>{
      m3MusicDir.path,
      networkCacheDir.path,
      ...saved,
    };

    return allPaths.toList();
  }
}
