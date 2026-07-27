import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRoleKey = 'user_role';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';

  static Future<void> saveTokens({required String access, required String refresh}) async {
    await _storage.write(key: _accessTokenKey, value: access);
    await _storage.write(key: _refreshTokenKey, value: refresh);
  }

  static Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);
  static Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);

  static Future<void> saveUserData({required String role, required int id, required String username}) async {
    await _storage.write(key: _userRoleKey, value: role);
    await _storage.write(key: _userIdKey, value: id.toString());
    await _storage.write(key: _userNameKey, value: username);
  }

  static Future<void> saveData({required String role, required int id, required String username}) {
    return saveUserData(role: role, id: id, username: username);
  }

  static Future<String?> getUserRole() => _storage.read(key: _userRoleKey);
  static Future<int?> getUserId() async {
    final id = await _storage.read(key: _userIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}