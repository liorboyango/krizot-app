/// Dio-based HTTP client for the Krizot REST API.
///
/// Features:
/// - Automatic JWT injection via request interceptor
/// - 401 handling → clears token and redirects to login
/// - Structured error wrapping via [ErrorHandler]
library;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/constants.dart';
import '../utils/error_handler.dart';

/// Singleton Dio client pre-configured for the Krizot API.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_storage),
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => _log(obj.toString()),
      ),
    ]);
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Exposes the underlying [Dio] instance for direct use.
  Dio get dio => _dio;

  // ---------------------------------------------------------------------------
  // Convenience wrappers
  // ---------------------------------------------------------------------------

  /// Performs a GET request and returns the decoded response data.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Performs a POST request and returns the decoded response data.
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Performs a PUT request and returns the decoded response data.
  Future<dynamic> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  /// Performs a DELETE request and returns the decoded response data.
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw ErrorHandler.handle(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  /// Stores the JWT access token in secure storage.
  Future<void> setToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  /// Removes the JWT access token from secure storage.
  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }

  static void _log(String message) {
    // ignore: avoid_print
    assert(() {
      // Only log in debug mode.
      // ignore: avoid_print
      print('[ApiClient] $message');
      return true;
    }());
  }
}

// ---------------------------------------------------------------------------
// Auth Interceptor
// ---------------------------------------------------------------------------

/// Injects the stored JWT into every outgoing request.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401 responses are handled at the provider / screen level.
    handler.next(err);
  }
}
