/// Authentication service for Krizot.
///
/// Handles login, logout, and token persistence via [FlutterSecureStorage].
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import 'api_client.dart';

/// Result of a login attempt.
class AuthResult {
  const AuthResult({
    required this.user,
    required this.token,
    this.refreshToken,
  });

  final UserModel user;
  final String token;
  final String? refreshToken;
}

/// Service responsible for authentication operations.
class AuthService {
  AuthService({
    ApiClient? apiClient,
    FlutterSecureStorage? storage,
  })  : _api = apiClient ?? ApiClient.instance,
        _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Authenticates the user with [email] and [password].
  ///
  /// On success, persists the JWT and returns an [AuthResult].
  /// On failure, throws an [AppError].
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );

    if (data is! Map<String, dynamic>) {
      throw const AppError(message: 'Unexpected response from server.');
    }

    final token = data['token'] as String? ?? data['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw const AppError(message: 'No token received from server.');
    }

    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw const AppError(message: 'No user data received from server.');
    }

    final user = UserModel.fromJson(userJson);
    final refreshToken = data['refreshToken'] as String?;

    // Persist tokens and user.
    await Future.wait([
      _api.setToken(token),
      _storage.write(key: AppConstants.userKey, value: user.toJsonString()),
      if (refreshToken != null)
        _storage.write(
          key: AppConstants.refreshTokenKey,
          value: refreshToken,
        ),
    ]);

    return AuthResult(user: user, token: token, refreshToken: refreshToken);
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Clears all stored credentials.
  Future<void> logout() async {
    await Future.wait([
      _api.clearToken(),
      _storage.delete(key: AppConstants.userKey),
      _storage.delete(key: AppConstants.refreshTokenKey),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Session restoration
  // ---------------------------------------------------------------------------

  /// Attempts to restore a previous session from secure storage.
  ///
  /// Returns the cached [UserModel] if a valid token exists, otherwise `null`.
  Future<UserModel?> restoreSession() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    final userJson = await _storage.read(key: AppConstants.userKey);

    if (token == null || token.isEmpty || userJson == null) {
      return null;
    }

    try {
      return UserModel.fromJsonString(userJson);
    } catch (_) {
      // Corrupted cache – clear it.
      await logout();
      return null;
    }
  }
}
