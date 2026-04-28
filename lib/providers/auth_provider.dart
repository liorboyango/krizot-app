/// Riverpod providers for authentication state.
///
/// Exposes:
/// - [authServiceProvider]   - AuthService singleton
/// - [authStateProvider]     - AsyncNotifier managing login/logout lifecycle
/// - [currentUserProvider]   - Derived provider for the current User
library;

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';

// Service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Represents the current authentication state.
sealed class AuthState {
  const AuthState();
}

/// User is not authenticated.
final class AuthStateUnauthenticated extends AuthState {
  const AuthStateUnauthenticated();
}

/// Authentication is in progress.
final class AuthStateLoading extends AuthState {
  const AuthStateLoading();
}

/// User is authenticated.
final class AuthStateAuthenticated extends AuthState {
  const AuthStateAuthenticated({required this.user});
  final User user;
}

/// Authentication failed.
final class AuthStateError extends AuthState {
  const AuthStateError({required this.message});
  final String message;
}

/// Manages the authentication lifecycle.
class AuthNotifier extends AsyncNotifier<AuthState> {
  late AuthService _authService;

  @override
  Future<AuthState> build() async {
    _authService = ref.read(authServiceProvider);

    // Propagate sign-outs that happen outside this notifier (e.g. token
    // revoked server-side, signOut from another part of the app).
    final sub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null && state.value is AuthStateAuthenticated) {
        state = const AsyncValue.data(AuthStateUnauthenticated());
      }
    });
    ref.onDispose(sub.cancel);

    return _checkExistingSession();
  }

  Future<AuthState> _checkExistingSession() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return const AuthStateUnauthenticated();
    }
    try {
      final user = await _authService.getCurrentUser();
      return AuthStateAuthenticated(user: user);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await FirebaseAuth.instance.signOut();
      }
      return const AuthStateUnauthenticated();
    } catch (_) {
      return const AuthStateUnauthenticated();
    }
  }

  /// Attempt to log in with the given credentials.
  Future<void> login(String email, String password) async {
    state = const AsyncValue.data(AuthStateLoading());
    try {
      final user = await _authService.login(
        LoginCredentials(email: email, password: password),
      );
      state = AsyncValue.data(AuthStateAuthenticated(user: user));
    } on FirebaseAuthException catch (e) {
      state = AsyncValue.data(AuthStateError(message: _firebaseMessage(e)));
    } on ApiException catch (e) {
      state = AsyncValue.data(AuthStateError(message: e.userMessage));
    } on NetworkException catch (e) {
      state = AsyncValue.data(AuthStateError(message: e.message));
    } catch (_) {
      state = const AsyncValue.data(
        AuthStateError(message: 'An unexpected error occurred. Please try again.'),
      );
    }
  }

  /// Log out the current user.
  Future<void> logout() async {
    await _authService.logout();
    state = const AsyncValue.data(AuthStateUnauthenticated());
  }

  /// Re-fetch the current user profile from the API.
  Future<void> refreshUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AsyncValue.data(AuthStateAuthenticated(user: user));
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        state = const AsyncValue.data(AuthStateUnauthenticated());
      }
    } catch (_) {}
  }

  String _firebaseMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'Sign-in failed. Please try again.';
    }
  }
}

/// Provider for the [AuthNotifier].
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience provider that returns the current [User] or null.
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState is AuthStateAuthenticated) return authState.user;
  return null;
});

/// Returns true when the user is authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
