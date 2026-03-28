import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({this.status = AuthStatus.initial, this.user, this.error});

  AuthState copyWith({AuthStatus? status, User? user, String? error}) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;

  AuthNotifier(this._apiClient) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userData = prefs.getString(AppConstants.userKey);

    if (token != null && userData != null) {
      try {
        final user = User.fromJson(
          jsonDecode(userData) as Map<String, dynamic>,
        );
        state = state.copyWith(status: AuthStatus.authenticated, user: user);
      } catch (_) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.tokenKey,
        data['accessToken'] as String,
      );
      await prefs.setString(
        AppConstants.refreshTokenKey,
        data['refreshToken'] as String,
      );
      await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      log(e.toString());
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      );
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppConstants.tokenKey,
        data['accessToken'] as String,
      );
      await prefs.setString(
        AppConstants.refreshTokenKey,
        data['refreshToken'] as String,
      );
      await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));

      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: _parseError(e),
      );
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.remove(AppConstants.userKey);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Terjadi kesalahan';
      }
      return e.message ?? 'Terjadi kesalahan';
    }
    return 'Terjadi kesalahan';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ApiClient());
});
