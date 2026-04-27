import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Base URL for the Krizot backend API.
/// Override via --dart-define=API_BASE_URL=https://your-api.com/api
const String _kApiBaseUrl =
    String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3000/api');

/// Singleton Dio HTTP client with auth interceptor.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  late final Dio _dio = _buildDio();

  Dio get dio => _dio;

  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _kApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Auth interceptor: attach Bearer token to every request.
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Attempt token refresh on 401.
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefreshToken(dio);
            if (refreshed) {
              // Retry original request with new token.
              final token = await _storage.read(key: _tokenKey);
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $token';
              try {
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {}
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  /// Attempts to refresh the access token using the stored refresh token.
  Future<bool> _tryRefreshToken(Dio dio) async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await Dio(BaseOptions(baseUrl: _kApiBaseUrl)).post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final newToken = data['data']?['accessToken']?.toString();
        if (newToken != null) {
          await _storage.write(key: _tokenKey, value: newToken);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Stores auth tokens in secure storage.
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  /// Clears all stored tokens (logout).
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  /// Returns true if an access token is stored.
  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }
}
