import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Authentication service for login/logout/session management.
class AuthService {
  final ApiClient _client;

  AuthService({ApiClient? client}) : _client = client ?? ApiClient.instance;

  /// Logs in with email and password.
  /// Returns the authenticated [UserModel] on success.
  /// Throws [AuthException] on failure.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );

      final body = response.data as Map<String, dynamic>;
      if (body['success'] != true) {
        throw AuthException(
          body['error']?['message']?.toString() ?? 'Login failed',
        );
      }

      final data = body['data'] as Map<String, dynamic>;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      final accessToken = data['accessToken']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';

      await _client.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return user;
    } on DioException catch (e) {
      final message = _extractErrorMessage(e);
      throw AuthException(message);
    }
  }

  /// Logs out and clears stored tokens.
  Future<void> logout() async {
    try {
      await _client.dio.post('/auth/logout');
    } catch (_) {
      // Ignore logout API errors — always clear local tokens.
    } finally {
      await _client.clearTokens();
    }
  }

  /// Checks if the user has a valid stored session.
  Future<bool> hasSession() => _client.hasToken();

  /// Fetches the current user profile from /auth/me.
  Future<UserModel?> getCurrentUser() async {
    try {
      final response = await _client.dio.get('/auth/me');
      final body = response.data as Map<String, dynamic>;
      if (body['success'] == true) {
        return UserModel.fromJson(body['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  String _extractErrorMessage(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['error']?['message']?.toString() ??
            data['message']?.toString() ??
            'An error occurred';
      }
    } catch (_) {}
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please try again.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Check your network.';
      default:
        return e.message ?? 'An unexpected error occurred';
    }
  }
}

/// Exception thrown by [AuthService] on authentication failures.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
