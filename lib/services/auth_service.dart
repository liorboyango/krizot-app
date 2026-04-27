/// Authentication service for the Krizot API.
///
/// Handles:
/// - Login (POST /api/auth/login)
/// - Logout (POST /api/auth/logout)
/// - Token refresh (POST /api/auth/refresh)
/// - Current user (GET /api/auth/me)
/// - Registration (POST /api/auth/register) — admin only
library;

import 'package:dio/dio.dart';

import '../models/user.dart';
import '../models/api_response.dart';
import 'api_client.dart';

/// Credentials used for login.
class LoginCredentials {
  const LoginCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

/// Result of a successful login.
class AuthResult {
  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final User user;
  final String accessToken;
  final String refreshToken;
}

/// Service for authentication-related API calls.
class AuthService {
  AuthService({ApiClient? client})
      : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  // ---------------------------------------------------------------------------
  // Login
  // ---------------------------------------------------------------------------

  /// Authenticate with email and password.
  ///
  /// On success, tokens are persisted in secure storage automatically.
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<AuthResult> login(LoginCredentials credentials) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: credentials.toJson(),
      );

      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;

      // Support both token/accessToken field names
      final accessToken = (data['token'] as String?) ??
          (data['accessToken'] as String?) ??
          '';
      final refreshToken = (data['refreshToken'] as String?) ?? '';
      final userJson = data['user'] as Map<String, dynamic>;

      final user = User.fromJson(userJson);

      await _client.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return AuthResult(
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------

  /// Invalidate the current session on the server and clear local tokens.
  Future<void> logout() async {
    try {
      await _client.post<dynamic>('/auth/logout');
    } on DioException catch (_) {
      // Best-effort — always clear local tokens
    } finally {
      await _client.clearTokens();
    }
  }

  // ---------------------------------------------------------------------------
  // Current user
  // ---------------------------------------------------------------------------

  /// Fetch the currently authenticated user's profile.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<User> getCurrentUser() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/auth/me');
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return User.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Registration (admin only)
  // ---------------------------------------------------------------------------

  /// Register a new user. Requires admin role.
  ///
  /// Throws [ApiException] or [NetworkException] on failure.
  Future<User> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'role': role.toApiString(),
        },
      );
      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return User.fromJson(userJson);
    } on DioException catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Token helpers
  // ---------------------------------------------------------------------------

  /// Returns true if there is a stored access token (user may be logged in).
  Future<bool> hasStoredToken() async {
    final token = await _client.getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
