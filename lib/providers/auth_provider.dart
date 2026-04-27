import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

// ---------------------------------------------------------------------------
// Secure storage provider
// ---------------------------------------------------------------------------
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------
class AuthState {
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? accessToken,
    String? refreshToken,
    Map<String, dynamic>? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ---------------------------------------------------------------------------
// Auth notifier
// ---------------------------------------------------------------------------
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage;
  final Dio _dio;

  AuthNotifier(this._storage, this._dio) : super(const AuthState()) {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.read(key: AppConstants.tokenKey);
      final refreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey);
      if (token != null) {
        state = state.copyWith(
          accessToken: token,
          refreshToken: refreshToken,
          isAuthenticated: true,
          isLoading: false,
        );
        // Attach token to dio
        _dio.options.headers['Authorization'] = 'Bearer $token';
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        '${AppConstants.apiBaseUrl}/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final responseData = data['data'] as Map<String, dynamic>;
        final token = responseData['token'] as String? ??
            responseData['accessToken'] as String?;
        final refreshToken = responseData['refreshToken'] as String?;
        final user = responseData['user'] as Map<String, dynamic>?;

        if (token != null) {
          await _storage.write(key: AppConstants.tokenKey, value: token);
          if (refreshToken != null) {
            await _storage.write(
                key: AppConstants.refreshTokenKey, value: refreshToken);
          }
          _dio.options.headers['Authorization'] = 'Bearer $token';
          state = state.copyWith(
            accessToken: token,
            refreshToken: refreshToken,
            user: user,
            isAuthenticated: true,
            isLoading: false,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            error: 'Invalid response from server',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: data['error']?['message'] ?? 'Login failed',
        );
      }
    } on DioException catch (e) {
      final message = e.response?.data?['error']?['message'] ??
          e.response?.data?['message'] ??
          'Network error. Please try again.';
      state = state.copyWith(isLoading: false, error: message as String);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('${AppConstants.apiBaseUrl}/auth/logout');
    } catch (_) {
      // Ignore logout API errors
    }
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    _dio.options.headers.remove('Authorization');
    state = const AuthState();
  }

  Future<bool> refreshToken() async {
    final refreshToken = state.refreshToken;
    if (refreshToken == null) return false;
    try {
      final response = await _dio.post(
        '${AppConstants.apiBaseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final newToken = data['data']?['token'] as String?;
        if (newToken != null) {
          await _storage.write(key: AppConstants.tokenKey, value: newToken);
          _dio.options.headers['Authorization'] = 'Bearer $newToken';
          state = state.copyWith(accessToken: newToken);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }
}

// ---------------------------------------------------------------------------
// Dio provider (singleton with auth interceptor)
// ---------------------------------------------------------------------------
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Add logging interceptor in debug mode
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Try to refresh token
          final authNotifier = ref.read(authProvider.notifier);
          final refreshed = await authNotifier.refreshToken();
          if (refreshed) {
            // Retry the request
            final opts = error.requestOptions;
            final token = ref.read(authProvider).accessToken;
            opts.headers['Authorization'] = 'Bearer $token';
            try {
              final response = await dio.fetch(opts);
              return handler.resolve(response);
            } catch (e) {
              return handler.next(error);
            }
          } else {
            // Logout on auth failure
            ref.read(authProvider.notifier).logout();
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
});

// ---------------------------------------------------------------------------
// Auth provider
// ---------------------------------------------------------------------------
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = ref.watch(dioProvider);
  return AuthNotifier(storage, dio);
});
