import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:myapp/api/Model/User/index.dart';

class UserProvider extends ChangeNotifier {
  final jwtKey = "jwt_key";
  User? _user;

  String? _token = "";

  final _storage = FlutterSecureStorage();

  Future<void> loadToken() async {
    final token = await _storage.read(key: jwtKey);

    if (token != null) {
      _token = token;
      notifyListeners();
    }
  }

  Future<void> saveToken(String newToken) async {
    await _storage.write(key: jwtKey, value: token);
  }

  // String? get username => _user?.username;
  String? get token => _token;
  // String? get avatar => _user?.avatarURL;
  User? get user => _user;

  Future<void> updateUserInfo(User newUser) async {
    _user = newUser;
    try {
      if (_user!.token != null && _user!.token!.isNotEmpty) {
        await saveToken(_user!.token!);
      }
    } catch (e) {
      print(e);
    }
    notifyListeners();
  }

  void logout() {
    _user = null;
    _token = null;
    notifyListeners();
  }
}
