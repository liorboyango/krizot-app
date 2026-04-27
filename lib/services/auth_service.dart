import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import 'api_client.dart';

/// Authentication service for login, logout, and token management.
class AuthService {
  final ApiClient _client;
  final FlutterSecureStorage _storage;

  AuthService({
    ApiClient? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? ApiClient.instance,
        _storage = storage ?? const FlutterSecureStorage();

  /// Login with email and password.
  ///
  /// Returns the authenticated [User] on success.
  /// Throws [AuthException] on failure.
  Future<User> login(String email, String password) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      final body = response.data!;
      if (body['success'] != true) {
        throw AuthException(
          body['error']?['message'] as String? ?? 'Login failed',
        );
      }

      final data = body['data'] as Map<String, dynamic>;
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String?;

      // Persist tokens securely
      await _storage.write(key: AppConstants.tokenKey, value: accessToken);
      if (refreshToken != null) {
        await _storage.write(
            key: AppConstants.refreshTokenKey, value: refreshToken);
      }
      await _storage.write(
          key: AppConstants.userKey, value: jsonEncode(user.toJson()));

      return user;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  /// Logout: clear stored tokens.
  Future<void> logout() async {
    try {
      await _client.post<dynamic>('/auth/logout');
    } catch (_) {
      // Best-effort logout
    } finally {
      await _storage.delete(key: AppConstants.tokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.userKey);
    }
  }

  /// Restore session from secure storage.
  ///
  /// Returns the stored [User] if a valid token exists, otherwise null.
  Future<User?> restoreSession() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final userJson = await _storage.read(key: AppConstants.userKey);
    if (token == null || userJson == null) return null;

    try {
      final user = User.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>);
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Get current user from /auth/me.
  Future<User?> getCurrentUser() async {
    try {
      final response =
          await _client.get<Map<String, dynamic>>('/auth/me');
      final body = response.data!;
      if (body['success'] == true) {
        return User.fromJson(body['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['error']?['message'] as String? ??
            data['message'] as String? ??
            'Authentication failed';
      }
    } catch (_) {}
    return e.message ?? 'Authentication failed';
  }
}

/// Exception thrown by [AuthService] on authentication errors.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
