import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userRoleKey = 'user_role';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';

  // Set once secure storage proves unusable on this device (key store errors,
  // signature changes, corrupted entries). Storage must never break an API call.
  static bool _useFileFallback = false;

  static Future<String?> _read(String key) async {
    if (!_useFileFallback) {
      try {
        return await _storage.read(key: key);
      } catch (_) {
        await _switchToFileFallback();
      }
    }
    return _readFile(key);
  }

  static Future<void> _write(String key, String value) async {
    if (!_useFileFallback) {
      try {
        await _storage.write(key: key, value: value);
        return;
      } catch (_) {
        await _switchToFileFallback();
      }
    }
    await _writeFile(key, value);
  }

  static Future<void> _switchToFileFallback() async {
    _useFileFallback = true;
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  static Future<File> _fileFor(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}gokulam_$key.txt');
  }

  static Future<String?> _readFile(String key) async {
    try {
      final file = await _fileFor(key);
      if (!await file.exists()) return null;
      final value = (await file.readAsString()).trim();
      return value.isEmpty ? null : value;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeFile(String key, String value) async {
    try {
      final file = await _fileFor(key);
      await file.writeAsString(value, flush: true);
    } catch (_) {}
  }

  static Future<void> saveTokens({required String access, required String refresh}) async {
    await _write(_accessTokenKey, access);
    await _write(_refreshTokenKey, refresh);
  }

  static Future<String?> getAccessToken() => _read(_accessTokenKey);
  static Future<String?> getRefreshToken() => _read(_refreshTokenKey);

  static Future<void> saveUserData({required String role, required int id, required String username}) async {
    await _write(_userRoleKey, role);
    await _write(_userIdKey, id.toString());
    await _write(_userNameKey, username);
  }

  static Future<void> saveData({required String role, required int id, required String username}) {
    return saveUserData(role: role, id: id, username: username);
  }

  static Future<String?> getUserRole() => _read(_userRoleKey);

  static Future<int?> getUserId() async {
    final id = await _read(_userIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
    for (final key in [_accessTokenKey, _refreshTokenKey, _userRoleKey, _userIdKey, _userNameKey]) {
      try {
        final file = await _fileFor(key);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }
}
