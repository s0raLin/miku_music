import 'package:shared_preferences/shared_preferences.dart';

class FileService {
  static Future savePaths(List<String> newPaths) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList("folder_path") ?? [];
    // 合并去重
    final merged = {...existing, ...newPaths}.toList();
    await prefs.setStringList("folder_paths", merged);
  }

  static Future<List<String>> loadPaths() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList("folder_paths") ?? [];
  }
}
