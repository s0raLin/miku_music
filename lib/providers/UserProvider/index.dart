import 'package:flutter/material.dart';
import 'package:myapp/api/Model/User/index.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/service/LocalAuth/index.dart';
import 'package:myapp/utils/Http/index.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户状态管理 Provider
class UserProvider extends ChangeNotifier {
  final _localAuth = LocalAuth();

  User? _user;
  String? _token;
  String? _neteaseCookie;
  String? _neteaseUsername; // ← 新增

  User? get user => _user;
  String? get token => _token;
  String? get neteaseCookie => _neteaseCookie;
  String? get neteaseUsername => _neteaseUsername;

  bool get isLoggedIn => _user != null && _token != null;

  // ← 兼容原来 SettingsPage 用的名字
  bool get isNeteaseLoggedIn =>
      _neteaseCookie != null && _neteaseCookie!.isNotEmpty;

  bool get hasNeteaseCookie => isNeteaseLoggedIn;

  /// 尝试从本地加密存储恢复登录状态
  Future<void> tryAutoLogin() async {
    final savedToken = await _localAuth.readToken();
    final savedUserJson = await _localAuth.readUser();

    if (savedToken != null && savedUserJson != null) {
      _token = savedToken;
      _user = User.fromJson(savedUserJson);
      _user!.token = savedToken;
      HttpUtils.setAuthToken(savedToken);
      debugPrint('[UserProvider] 已从本地恢复登录状态: ${_user!.username}');
    }

    // 同时恢复网易云 Cookie 和用户名
    await _restoreNeteaseCookie();

    notifyListeners();
  }

  /// 登录/注册成功后更新用户信息
  Future<void> updateUserInfo(User newUser) async {
    _user = newUser;
    _token = newUser.token;

    if (newUser.token != null && newUser.token!.isNotEmpty) {
      await _localAuth.saveToken(newUser.token!);
      HttpUtils.setAuthToken(newUser.token!);
    }
    await _localAuth.saveUser(newUser.toJson());

    debugPrint('[UserProvider] 用户信息已更新: ${newUser.username}');
    notifyListeners();
  }

  /// 登出：清除内存状态和本地存储
  Future<void> logout() async {
    _user = null;
    _token = null;
    HttpUtils.clearAuthToken();
    await _localAuth.clearAll();

    // 同时清除网易云 Cookie
    await clearNeteaseAuth();

    debugPrint('[UserProvider] 已登出');
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════
  //  网易云 Cookie 相关方法
  // ═══════════════════════════════════════════════════════════════

  /// 保存网易云 Cookie + 用户名（扫码登录成功后调用）
  Future<void> saveNeteaseCookie(String cookie, {String? nickname}) async {
    if (cookie.isEmpty) return;

    _neteaseCookie = cookie;
    _neteaseUsername = nickname ?? '网易云用户';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('netease_cookie', cookie);
    await prefs.setString('netease_username', _neteaseUsername!);

    // 立刻注入到 NeteaseApi
    NeteaseApi.getCookieHandler = () => _neteaseCookie ?? '';

    debugPrint('[UserProvider] 网易云 Cookie 已保存并注入: $_neteaseUsername');
    notifyListeners();
  }

  /// 从本地恢复网易云 Cookie
  Future<void> _restoreNeteaseCookie() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('netease_cookie');
    final username = prefs.getString('netease_username');

    if (cookie != null && cookie.isNotEmpty) {
      _neteaseCookie = cookie;
      _neteaseUsername = username ?? '网易云用户';
      NeteaseApi.getCookieHandler = () => _neteaseCookie ?? '';
      debugPrint('[UserProvider] 已恢复网易云 Cookie: $_neteaseUsername');
    } else {
      NeteaseApi.getCookieHandler = null;
    }
  }

  /// 清除网易云登录状态（兼容原来 clearNeteaseAuth 名字）
  Future<void> clearNeteaseAuth() async {
    _neteaseCookie = null;
    _neteaseUsername = null;
    NeteaseApi.getCookieHandler = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('netease_cookie');
    await prefs.remove('netease_username');

    debugPrint('[UserProvider] 网易云 Cookie 已清除');
    notifyListeners();
  }

  // 兼容旧方法名
  Future<void> clearNeteaseCookie() => clearNeteaseAuth();
}
