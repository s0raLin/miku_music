import 'package:shared_preferences/shared_preferences.dart';

class FileService {
  static const String _storageKey = "folder_path";

  static Future savePaths(List<String> newPaths) async {
    final pfs = await SharedPreferences.getInstance();
    // final existing = pfs.getStringList(_storage_key) ?? [];
    //如果传入的是空列表,则清空该key
    if (newPaths.isEmpty) {
      await pfs.remove(_storageKey);
    } else {
      await pfs.setStringList(_storageKey, newPaths);
    }
    // 合并去重
    // final merged = {...existing, ...newPaths}.toList();
    // await pfs.setStringList(_storage_key, merged);
  }

  static Future<List<String>> loadPaths() async {
    final pfs = await SharedPreferences.getInstance();
    return pfs.getStringList(_storageKey) ?? [];
  }
}
