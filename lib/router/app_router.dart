/// GoRouter configuration for Krizot.
///
/// Routes:
/// - `/login`       → [LoginScreen]
/// - `/`            → [DashboardScreen] (requires auth)
/// - `/stations`    → [StationsScreen] (requires auth)
/// - `/schedule`    → [ScheduleScreen] (requires auth)
///
/// Auth guard: unauthenticated users are redirected to `/login`.
/// Authenticated users visiting `/login` are redirected to `/`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/stations_screen.dart';
import '../screens/schedule_screen.dart';
import '../widgets/app_shell.dart';

// ---------------------------------------------------------------------------
// Route names (use these constants instead of raw strings)
// ---------------------------------------------------------------------------

/// Named route constants.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String dashboard = '/';
  static const String stations = '/stations';
  static const String schedule = '/schedule';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

/// Provides the [GoRouter] instance, reactive to auth state changes.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoading = authState is AsyncLoading;
      final isAuthenticated = authState.value is AuthStateAuthenticated;
      final isLoginRoute = state.matchedLocation == AppRoutes.login;

      // While restoring session, stay put.
      if (isLoading) return null;

      // Unauthenticated → redirect to login (unless already there).
      if (!isAuthenticated && !isLoginRoute) return AppRoutes.login;

      // Authenticated → redirect away from login.
      if (isAuthenticated && isLoginRoute) return AppRoutes.dashboard;

      return null;
    },
    routes: [
      // Login (no shell)
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _fadePage(
          state,
          const LoginScreen(),
        ),
      ),

      // Authenticated shell (sidebar + top bar)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            name: 'dashboard',
            pageBuilder: (context, state) => _fadePage(
              state,
              const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.stations,
            name: 'stations',
            pageBuilder: (context, state) => _fadePage(
              state,
              const StationsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.schedule,
            name: 'schedule',
            pageBuilder: (context, state) => _fadePage(
              state,
              const ScheduleScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Page builder helpers
// ---------------------------------------------------------------------------

/// Creates a [CustomTransitionPage] with a 200 ms fade.
CustomTransitionPage<void> _fadePage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
