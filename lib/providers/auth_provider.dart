/// Riverpod providers for authentication state in Krizot.
///
/// Exposes:
/// - [authServiceProvider] – the [AuthService] singleton
/// - [authStateProvider] – async notifier managing login/logout/session restore
/// - [currentUserProvider] – convenience provider for the logged-in user
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/error_handler.dart';

// ---------------------------------------------------------------------------
// Service provider
// ---------------------------------------------------------------------------

/// Provides the [AuthService] singleton.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// ---------------------------------------------------------------------------
// Auth state
// ---------------------------------------------------------------------------

/// Possible states of the authentication flow.
sealed class AuthState {
  const AuthState();
}

/// Initial state – session restoration in progress.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final UserModel user;
}

/// User is not authenticated.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An error occurred during authentication.
final class AuthError extends AuthState {
  const AuthError(this.error);
  final AppError error;
}

// ---------------------------------------------------------------------------
// Auth notifier
// ---------------------------------------------------------------------------

/// Manages the authentication lifecycle.
class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Attempt to restore a previous session on startup.
    final service = ref.read(authServiceProvider);
    final user = await service.restoreSession();
    if (user != null) {
      return AuthAuthenticated(user);
    }
    return const AuthUnauthenticated();
  }

  /// Signs in with [email] and [password].
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final service = ref.read(authServiceProvider);
    try {
      final result = await service.login(email: email, password: password);
      state = AsyncValue.data(AuthAuthenticated(result.user));
    } on AppError catch (e) {
      state = AsyncValue.data(AuthError(e));
    } catch (e) {
      state = AsyncValue.data(
        AuthError(ErrorHandler.handle(e)),
      );
    }
  }

  /// Signs out the current user.
  Future<void> logout() async {
    final service = ref.read(authServiceProvider);
    await service.logout();
    state = const AsyncValue.data(AuthUnauthenticated());
  }
}

/// The primary auth state provider.
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience provider – returns the current [UserModel] or `null`.
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state is AuthAuthenticated ? state.user : null,
    loading: () => null,
    error: (_, __) => null,
  );
});
