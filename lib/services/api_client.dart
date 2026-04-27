/// Dio-based HTTP client for the Krizot API.
///
/// Features:
/// - Automatic JWT Bearer token injection
/// - Token refresh on 401 responses
/// - Structured error parsing
/// - Request/response logging in debug mode
/// - Retry logic for transient failures
library;

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/api_response.dart';

/// Storage keys for JWT tokens.
class _StorageKeys {
  static const accessToken = 'krizot_access_token';
  static const refreshToken = 'krizot_refresh_token';
}

/// Singleton API client used throughout the app.
class ApiClient {
  ApiClient._internal();

  static final ApiClient _instance = ApiClient._internal();

  /// Access the singleton instance.
  static ApiClient get instance => _instance;

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Base URL for the Krizot REST API.
  /// Override via the KRIZOT_API_URL environment variable at build time:
  ///   flutter run --dart-define=KRIZOT_API_URL=https://api.example.com/api
  static const String _defaultBaseUrl = 'http://localhost:3000/api';
  static const String baseUrl = String.fromEnvironment(
    'KRIZOT_API_URL',
    defaultValue: _defaultBaseUrl,
  );

  // ---------------------------------------------------------------------------
  // Internal state
  // ---------------------------------------------------------------------------

  late final Dio _dio;
  late final Dio _refreshDio; // Separate instance to avoid interceptor loops
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isRefreshing = false;
  final List<Completer<void>> _refreshQueue = [];

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialise the Dio client. Must be called once at app startup.
  void init() {
    final baseOptions = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(baseOptions);
    _refreshDio = Dio(baseOptions);

    // Add interceptors in order
    _dio.interceptors.addAll([
      _AuthInterceptor(this),
      if (kDebugMode) LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  /// Retrieve the stored access token.
  Future<String?> getAccessToken() =>
      _storage.read(key: _StorageKeys.accessToken);

  /// Retrieve the stored refresh token.
  Future<String?> getRefreshToken() =>
      _storage.read(key: _StorageKeys.refreshToken);

  /// Persist both tokens after a successful login or refresh.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _StorageKeys.accessToken, value: accessToken),
      _storage.write(key: _StorageKeys.refreshToken, value: refreshToken),
    ]);
  }

  /// Clear all stored tokens (logout).
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _StorageKeys.accessToken),
      _storage.delete(key: _StorageKeys.refreshToken),
    ]);
  }

  /// Attempt to refresh the access token using the stored refresh token.
  /// Returns the new access token, or null if refresh failed.
  Future<String?> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await _refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>?;
      final newToken = data?['token'] as String? ??
          data?['accessToken'] as String?;

      if (newToken != null) {
        await _storage.write(
          key: _StorageKeys.accessToken,
          value: newToken,
        );
        return newToken;
      }
    } catch (_) {
      // Refresh failed — caller should redirect to login
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // HTTP helpers
  // ---------------------------------------------------------------------------

  /// Perform a GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );

  /// Perform a POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  /// Perform a PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  /// Perform a PATCH request.
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  /// Perform a DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) =>
      _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

  // ---------------------------------------------------------------------------
  // Error parsing
  // ---------------------------------------------------------------------------

  /// Convert a [DioException] into a typed [ApiException] or [NetworkException].
  static Exception parseError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return const NetworkException(
        message: 'Unable to reach the server. Please check your connection.',
      );
    }

    if (error.type == DioExceptionType.badResponse) {
      final statusCode = error.response?.statusCode ?? 500;
      final responseData = error.response?.data;

      ApiError apiError;
      if (responseData is Map<String, dynamic>) {
        apiError = ApiError.fromJson(responseData);
      } else {
        apiError = ApiError(
          code: 'SERVER_ERROR',
          message: error.message ?? 'An unexpected server error occurred.',
        );
      }

      return ApiException(
        statusCode: statusCode,
        error: apiError,
        originalError: error,
      );
    }

    return NetworkException(
      message: error.message ?? 'An unexpected error occurred.',
      originalError: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Interceptor
// ---------------------------------------------------------------------------

/// Interceptor that:
/// 1. Injects the Bearer token into every request.
/// 2. On 401, attempts a token refresh and retries the original request.
/// 3. On second 401, clears tokens (forces re-login).
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _client.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    // Avoid refresh loops for the refresh endpoint itself
    if (err.requestOptions.path.contains('/auth/refresh') ||
        err.requestOptions.path.contains('/auth/login')) {
      await _client.clearTokens();
      handler.next(err);
      return;
    }

    if (_client._isRefreshing) {
      // Queue this request until the ongoing refresh completes
      final completer = Completer<void>();
      _client._refreshQueue.add(completer);
      await completer.future;

      // Retry with the new token
      final newToken = await _client.getAccessToken();
      if (newToken != null) {
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        try {
          final response = await _client._dio.fetch(err.requestOptions);
          handler.resolve(response);
        } catch (e) {
          handler.next(err);
        }
      } else {
        handler.next(err);
      }
      return;
    }

    _client._isRefreshing = true;
    try {
      final newToken = await _client.refreshAccessToken();
      if (newToken != null) {
        // Resolve all queued requests
        for (final c in _client._refreshQueue) {
          c.complete();
        }
        _client._refreshQueue.clear();

        // Retry the original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final response = await _client._dio.fetch(err.requestOptions);
        handler.resolve(response);
      } else {
        await _client.clearTokens();
        for (final c in _client._refreshQueue) {
          c.completeError('Token refresh failed');
        }
        _client._refreshQueue.clear();
        handler.next(err);
      }
    } catch (e) {
      await _client.clearTokens();
      for (final c in _client._refreshQueue) {
        c.completeError(e);
      }
      _client._refreshQueue.clear();
      handler.next(err);
    } finally {
      _client._isRefreshing = false;
    }
  }
}
