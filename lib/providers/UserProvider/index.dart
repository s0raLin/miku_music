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
  String? _refreshToken;
  String? _neteaseCookie;
  String? _neteaseUsername;

  User? get user => _user;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get neteaseCookie => _neteaseCookie;
  String? get neteaseUsername => _neteaseUsername;

  bool get isLoggedIn => _user != null && _token != null;

  bool get isNeteaseLoggedIn =>
      _neteaseCookie != null && _neteaseCookie!.isNotEmpty;

  bool get hasNeteaseCookie => isNeteaseLoggedIn;

  /// 尝试从本地加密存储恢复登录状态（应用启动时调用）
  Future<void> tryAutoLogin() async {
    final savedToken = await _localAuth.readToken();
    final savedRefreshToken = await _localAuth
        .readRefreshToken(); // ← 修复：读取 Refresh Token
    final savedUserJson = await _localAuth.readUser();

    if (savedToken != null && savedUserJson != null) {
      _token = savedToken;
      _refreshToken = savedRefreshToken; // ← 修复：恢复内存 Refresh Token
      _user = User.fromJson(savedUserJson);
      _user!.token = savedToken;
      HttpUtils.setAuthToken(savedToken);
      debugPrint('[UserProvider] 已从本地恢复登录状态: ${_user!.username}');
    }

    // 同时恢复网易云 Cookie 和用户名
    await _restoreNeteaseCookie();

    notifyListeners();
  }

  /// 登录/注册/无感刷新成功后更新用户信息与 Token 对
  Future<void> updateUserInfo(
    User newUser, {
    String? accessToken,
    String? refreshToken,
  }) async {
    _user = newUser;

    // 优先取显式传入的 token，其次取 user 对象上的 token
    final newAccessToken = accessToken ?? newUser.token;
    if (newAccessToken != null && newAccessToken.isNotEmpty) {
      _token = newAccessToken;
      _user!.token = newAccessToken;
      HttpUtils.setAuthToken(newAccessToken);
      await _localAuth.saveToken(newAccessToken);
    }

    // 修复：更新 Refresh Token 并保存
    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
      await _localAuth.saveRefreshToken(refreshToken);
    }

    await _localAuth.saveUser(newUser.toJson());

    debugPrint('[UserProvider] 用户信息与双 Token 已更新: ${newUser.username}');
    notifyListeners();
  }

  /// 无感刷新成功时仅更新 Token 对（不重新保存 User）
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _token = accessToken;
    _refreshToken = refreshToken;

    if (_user != null) {
      _user!.token = accessToken;
    }

    HttpUtils.setAuthToken(accessToken);
    await _localAuth.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    debugPrint('[UserProvider] Token 对已隐式刷新成功');
    notifyListeners();
  }

  /// 登出：清除内存状态和本地存储
  Future<void> logout() async {
    _user = null;
    _token = null;
    _refreshToken = null;
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

  /// 清除网易云登录状态
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

  /// 处理 Token 过期 / 会话彻底失效（Refresh Token 也失效时调用）
  Future<void> handleSessionExpired() async {
    // 避免重复触发
    if (_user == null && _token == null) return;

    debugPrint('[UserProvider] 捕获到登录彻底失效，正在清理会话...');

    // 1. 清除内存与加密存储
    _user = null;
    _token = null;
    _refreshToken = null;
    HttpUtils.clearAuthToken();
    await _localAuth.clearAll();

    // 2. 清除网易云授权
    await clearNeteaseAuth();

    // 3. 通知 UI 更新状态（UI 会监听到并自动重绘为未登录或弹窗跳转）
    notifyListeners();
  }
}
