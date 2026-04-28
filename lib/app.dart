/// Root application widget for Krizot.
///
/// Configures:
/// - Material 3 theme with the Krizot design system
/// - GoRouter for declarative navigation
/// - Auth-aware route guards
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stations_screen.dart';
import 'screens/schedule_screen.dart';
import 'utils/app_theme.dart';

/// Named route paths.
class AppRoutes {
  static const login = '/login';
  static const dashboard = '/';
  static const stations = '/stations';
  static const schedule = '/schedule';
}

/// Root widget that owns the [GoRouter] and [MaterialApp.router].
class KrizotApp extends ConsumerWidget {
  const KrizotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _buildRouter(ref);
    return MaterialApp.router(
      title: 'Krizot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: AppRoutes.dashboard,
      redirect: (context, state) {
        final authState = ref.read(authStateProvider).value;
        final isAuthenticated = authState is AuthStateAuthenticated;
        final isLoginRoute = state.matchedLocation == AppRoutes.login;

        if (!isAuthenticated && !isLoginRoute) {
          return AppRoutes.login;
        }
        if (isAuthenticated && isLoginRoute) {
          return AppRoutes.dashboard;
        }
        return null;
      },
      refreshListenable: _AuthStateListenable(ref),
      routes: [
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.dashboard,
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: AppRoutes.stations,
          builder: (context, state) => const StationsScreen(),
        ),
        GoRoute(
          path: AppRoutes.schedule,
          builder: (context, state) => const ScheduleScreen(),
        ),
      ],
    );
  }
}

/// A [Listenable] that notifies GoRouter whenever the auth state changes.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(WidgetRef ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}
