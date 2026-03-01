import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env.dart';
import '../models/user.dart';
import '../services/api_client.dart';

/// Authentication state.
class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

/// Auth provider — manages login, register, logout, token persistence.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._storage) : super(const AuthState());

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  /// Extract a user-friendly error message from an exception.
  String _extractError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        // Backend returns { error: { message: '...' } }
        final errObj = data['error'];
        if (errObj is Map && errObj['message'] != null) {
          return errObj['message'].toString();
        }
        // Fallback: top-level message
        if (data['message'] != null) return data['message'].toString();
      }
      // Network / timeout
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please try again.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'No internet connection.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  /// Force-reset loading state (used when splash timeout fires).
  void forceResetLoading() {
    state = state.copyWith(isLoading: false);
  }

  /// Set optimistic auth state when token exists but checkAuth timed out.
  /// This marks the user as authenticated so screens don't redirect to login.
  /// Call checkAuth() afterwards to load the actual user data in the background.
  void setOptimisticAuth() {
    state = state.copyWith(isAuthenticated: true, isLoading: false);
  }

  /// Silently retry loading user data (no loading spinner, no error state changes).
  Future<void> silentCheckAuth() async {
    try {
      final token = await _storage.read(key: Env.accessTokenKey);
      if (token == null) return;

      final response = await _api.getMe();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']['user']);
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
        );
      }
    } catch (_) {
      // Silently ignore — user data will load next time
    }
  }

  /// Check if user has valid token on app start.
  Future<void> checkAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.read(key: Env.accessTokenKey);
      if (token == null) {
        state = state.copyWith(isLoading: false, isAuthenticated: false);
        return;
      }

      final response = await _api.getMe();
      if (response.statusCode == 200 && response.data['success'] == true) {
        final user = User.fromJson(response.data['data']['user']);
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
        );
      } else {
        await _clearTokens();
        state = state.copyWith(isLoading: false, isAuthenticated: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        error: e.toString(),
      );
    }
  }

  /// Login with email and password.
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.login(email, password);
      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.write(
            key: Env.accessTokenKey, value: data['accessToken']);
        await _storage.write(
            key: Env.refreshTokenKey, value: data['refreshToken']);

        final user = User.fromJson(data['user']);
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'Login failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Register a new account.
  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.register(name, email, password);
      if (response.statusCode == 201 && response.data['success'] == true) {
        final data = response.data['data'];
        await _storage.write(
            key: Env.accessTokenKey, value: data['accessToken']);
        await _storage.write(
            key: Env.refreshTokenKey, value: data['refreshToken']);

        final user = User.fromJson(data['user']);
        state = state.copyWith(
          user: user,
          isLoading: false,
          isAuthenticated: true,
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: response.data['message'] ?? 'Registration failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractError(e));
      return false;
    }
  }

  /// Logout — clear tokens and state.
  Future<void> logout() async {
    await _clearTokens();
    state = const AuthState();
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: Env.accessTokenKey);
    await _storage.delete(key: Env.refreshTokenKey);
  }
}

/// Auth provider instance.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.read(apiClientProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthNotifier(api, storage);
});
