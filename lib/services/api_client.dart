/// Dio-based HTTP client for the Krizot API.
///
/// Features:
/// - Firebase ID token injected as Bearer on every request
/// - On 401, force-refresh the ID token and retry the original request once
/// - Structured error parsing
/// - Request/response logging in debug mode
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/api_response.dart';

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

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  /// Initialise the Dio client. Must be called once at app startup,
  /// after `Firebase.initializeApp()`.
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
  // HTTP helpers
  // ---------------------------------------------------------------------------

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
/// 1. Injects the Firebase ID token as a Bearer header on every request
///    (the SDK auto-refreshes tokens that are within 5 minutes of expiry).
/// 2. On 401, force-refreshes the ID token and retries the original request once.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._client);

  final ApiClient _client;

  static const _retriedFlag = '_krizotAuthRetried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final token = await user.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } on FirebaseAuthException catch (_) {
        // Fall through; the request will likely 401 and be handled below.
      }
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

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.extra[_retriedFlag] == true) {
      // Already retried once with a fresh token — give up.
      handler.next(err);
      return;
    }

    try {
      final newToken = await user.getIdToken(true);
      if (newToken == null) {
        handler.next(err);
        return;
      }

      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      err.requestOptions.extra[_retriedFlag] = true;

      final response = await _client._dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } on FirebaseAuthException catch (_) {
      handler.next(err);
    }
  }
}
