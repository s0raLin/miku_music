import 'package:flutter/material.dart';
import 'package:myapp/api/Model/User/index.dart';
import 'package:myapp/service/LocalAuth/index.dart';
import 'package:myapp/utils/Http/index.dart';

/// 用户状态管理 Provider
///
/// 负责:
/// - 从本地加密存储加载已登录用户
/// - 登录/注册后更新用户状态
/// - 登出时清除本地数据
class UserProvider extends ChangeNotifier {
  final _localAuth = LocalAuth();

  User? _user;
  String? _token;

  User? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _user != null && _token != null;

  /// 尝试从本地加密存储恢复登录状态
  /// 在应用启动时调用
  Future<void> tryAutoLogin() async {
    final savedToken = await _localAuth.readToken();
    final savedUserJson = await _localAuth.readUser();

    if (savedToken != null && savedUserJson != null) {
      _token = savedToken;
      _user = User.fromJson(savedUserJson);
      _user!.token = savedToken;
      HttpUtils.setAuthToken(savedToken); // 同步到 HTTP 拦截器
      debugPrint('[UserProvider] 已从本地恢复登录状态: ${_user!.username}');
      notifyListeners();
    }
  }

  /// 登录/注册成功后更新用户信息
  Future<void> updateUserInfo(User newUser) async {
    _user = newUser;
    _token = newUser.token;

    // 加密保存到本地
    if (newUser.token != null && newUser.token!.isNotEmpty) {
      await _localAuth.saveToken(newUser.token!);
      HttpUtils.setAuthToken(newUser.token!); // 同步到 HTTP 拦截器
    }
    await _localAuth.saveUser(newUser.toJson());

    debugPrint('[UserProvider] 用户信息已更新: ${newUser.username}');
    notifyListeners();
  }

  /// 登出：清除内存状态和本地存储
  Future<void> logout() async {
    _user = null;
    _token = null;
    HttpUtils.clearAuthToken(); // 清除 HTTP 拦截器中的 token
    await _localAuth.clearAll();
    debugPrint('[UserProvider] 已登出');
    notifyListeners();
  }
}
