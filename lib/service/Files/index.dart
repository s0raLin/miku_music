import 'package:shared_preferences/shared_preferences.dart';

class FileService {
  static const String _storge_key = "folder_path";

  static Future savePaths(List<String> newPaths) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_storge_key) ?? [];
    //如果传入的是空列表,则清空该key
    if (newPaths.isEmpty) {
      await prefs.remove(_storge_key);
    }
    // 合并去重
    final merged = {...existing, ...newPaths}.toList();
    await prefs.setStringList(_storge_key, merged);
  }

  static Future<List<String>> loadPaths() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storge_key) ?? [];
  }
}
