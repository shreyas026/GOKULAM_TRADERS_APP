import 'dart:async';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';
import '../config/app_config.dart';

class AuthService {
  final _api = ApiService();

  Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await _api.post(ApiEndpoints.login, data: {
      'username': username,
      'password': password,
    });
    final user = UserModel.fromJson(res.data['user']);
    final tokens = res.data['tokens'];
    await StorageService.saveTokens(
      access: tokens['access'],
      refresh: tokens['refresh'],
    );
    await StorageService.saveData(
      role: user.role,
      id: user.id,
      username: user.username,
    );
    return {'user': user, 'tokens': tokens};
  }

  Future<UserModel> register(Map<String, dynamic> data) async {
    final res = await _api.post(ApiEndpoints.register, data: data);
    final user = UserModel.fromJson(res.data['user']);
    final tokens = res.data['tokens'];
    await StorageService.saveTokens(
      access: tokens['access'],
      refresh: tokens['refresh'],
    );
    await StorageService.saveData(
      role: user.role,
      id: user.id,
      username: user.username,
    );
    return user;
  }

  Future<UserModel> getProfile() async {
    final res = await _api.get(ApiEndpoints.profile);
    return UserModel.fromJson(res.data);
  }

  Future<void> logout() async {
    await StorageService.clearAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await StorageService.getAccessToken();
    return token != null;
  }

  Future<String?> getUserRole() => StorageService.getUserRole();
}