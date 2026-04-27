import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth state representing the current authentication status.
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Provider for [AuthService].
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Async provider that checks for an existing session on startup.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Notifier managing authentication state.
class AuthNotifier extends AsyncNotifier<AuthState> {
  late AuthService _authService;

  @override
  Future<AuthState> build() async {
    _authService = ref.read(authServiceProvider);
    // Check for existing session.
    final hasSession = await _authService.hasSession();
    if (hasSession) {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        return AuthState(user: user);
      }
    }
    return const AuthState();
  }

  /// Performs login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.login(email: email, password: password);
      state = AsyncValue.data(AuthState(user: user));
    } on AuthException catch (e) {
      state = AsyncValue.data(AuthState(error: e.message));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: 'An unexpected error occurred'));
    }
  }

  /// Performs logout and clears session.
  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(AuthState());
  }

  /// Clears any auth error message.
  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(clearError: true));
    }
  }
}
