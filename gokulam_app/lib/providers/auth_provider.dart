import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;

  AuthState({this.user, this.isLoading = false, this.error, this.isLoggedIn = false});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error, bool? isLoggedIn}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  Future<void> checkLoginStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      try {
        final user = await _authService.getProfile();
        state = AuthState(user: user, isLoggedIn: true);
      } catch (_) {
        state = AuthState(isLoggedIn: false);
      }
    }
  }

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.login(username, password);
      state = AuthState(user: result['user'], isLoggedIn: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed: ${_friendlyError(e)}');
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authService.register(data);
      if (result.pending) {
        state = AuthState(user: result.user, isLoggedIn: false, isLoading: false,
          error: 'Registration submitted. Awaiting admin approval.');
      } else {
        state = AuthState(user: result.user, isLoggedIn: true);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _friendlyError(e));
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('4100') || msg.toLowerCase().contains('phones made')) {
      return 'This phone number is already registered.';
    }
    if (msg.contains('username') && msg.toLowerCase().contains('exists')) {
      return 'This username is already taken.';
    }
    if (msg.contains('401') || msg.contains('No active account') || msg.contains('Invalid credentials')) {
      return 'Invalid username or password.';
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});