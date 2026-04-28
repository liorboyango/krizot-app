/// Authentication service for the Krizot API.
///
/// Login flow: clients authenticate with the Firebase Client SDK first
/// (`signInWithEmailAndPassword`), then POST the resulting ID token to the
/// backend at `/api/auth/login` to retrieve the user profile. Subsequent
/// requests carry a Firebase ID token in the Authorization header; the
/// Firebase SDK handles refresh automatically (no `/auth/refresh` endpoint).
library;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

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
}

/// Service for authentication-related API calls.
class AuthService {
  AuthService({
    ApiClient? client,
    FirebaseAuth? firebaseAuth,
  })  : _client = client ?? ApiClient.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final ApiClient _client;
  final FirebaseAuth _firebaseAuth;

  /// Sign in with Firebase, then exchange the ID token for the backend
  /// user profile. Throws [ApiException], [NetworkException], or
  /// [FirebaseAuthException] on failure.
  Future<User> login(LoginCredentials credentials) async {
    final firebaseCredential = await _firebaseAuth.signInWithEmailAndPassword(
      email: credentials.email,
      password: credentials.password,
    );

    final idToken = await firebaseCredential.user?.getIdToken();
    if (idToken == null) {
      throw const ApiException(
        statusCode: 401,
        error: ApiError(
          code: 'INVALID_TOKEN',
          message: 'Failed to obtain Firebase ID token after sign-in.',
        ),
      );
    }

    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'idToken': idToken},
      );

      final body = response.data!;
      final data = body['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>? ?? data;
      return User.fromJson(userJson);
    } on DioException catch (e) {
      // Backend rejected the ID token — undo the local Firebase session
      // so the app doesn't end up half-authenticated.
      await _firebaseAuth.signOut();
      throw ApiClient.parseError(e);
    }
  }

  /// Forcibly end the session everywhere, then sign out of Firebase locally.
  ///
  /// The `/auth/logout` call is what kills sessions across all devices
  /// (used for "log out everywhere", password reset, suspicious activity).
  /// `FirebaseAuth.signOut()` only clears the local token cache.
  Future<void> logout() async {
    try {
      await _client.post<dynamic>('/auth/logout');
    } on DioException catch (_) {
      // Best-effort — always sign out locally
    } finally {
      await _firebaseAuth.signOut();
    }
  }

  /// Fetch the currently authenticated user's profile.
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

  /// Register a new user. Requires admin role.
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
}
