import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';

import '../entities/app_user.dart';
import '../entities/go_router_refresh_stream.dart';
import '../managers/user_manager.dart';
import '../widgets/screens/admin/scheduler_screen.dart';
import '../widgets/screens/admin/stations_screen.dart';
import '../widgets/screens/admin/statistics_screen.dart';
import '../widgets/screens/admin/users_screen.dart';
import '../widgets/screens/admin/web_shell.dart';
import '../widgets/screens/dispatch/dispatch_screen.dart';
import '../widgets/screens/dispatch/event_types_screen.dart';
import '../widgets/screens/employee/employee_home_screen.dart';
import '../widgets/screens/sign_in_screen.dart';
import '../widgets/screens/splash_screen.dart';
import 'service_locator.dart';

class RouteGenerator {
  RouteGenerator._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  /// Web-only shell paths (Interfaces 1 & 3).
  static const _webShellPaths = [
    SchedulerScreen.ROUTE_PATH,
    StationsScreen.ROUTE_PATH,
    UsersScreen.ROUTE_PATH,
    StatisticsScreen.ROUTE_PATH,
    DispatchScreen.ROUTE_PATH,
  ];

  static GoRouter get router {
    final userManager = locator<UserManager>();
    final goRouter = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: SplashScreen.ROUTE_PATH,
      refreshListenable: GoRouterRefreshStream(Rx.merge<dynamic>([
        userManager.authResolvedStream,
        userManager.onUserChanged,
      ])),
      redirect: _redirect,
      routes: [
        GoRoute(
          path: SplashScreen.ROUTE_PATH,
          name: SplashScreen.ROUTE_NAME,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: SignInScreen.ROUTE_PATH,
          name: SignInScreen.ROUTE_NAME,
          builder: (context, state) => const SignInScreen(),
        ),
        GoRoute(
          path: EmployeeHomeScreen.ROUTE_PATH,
          name: EmployeeHomeScreen.ROUTE_NAME,
          builder: (context, state) => const EmployeeHomeScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => WebShell(child: child),
          routes: [
            GoRoute(
              path: SchedulerScreen.ROUTE_PATH,
              name: SchedulerScreen.ROUTE_NAME,
              builder: (context, state) => const SchedulerScreen(),
            ),
            GoRoute(
              path: StationsScreen.ROUTE_PATH,
              name: StationsScreen.ROUTE_NAME,
              builder: (context, state) => const StationsScreen(),
            ),
            GoRoute(
              path: UsersScreen.ROUTE_PATH,
              name: UsersScreen.ROUTE_NAME,
              builder: (context, state) => const UsersScreen(),
            ),
            GoRoute(
              path: StatisticsScreen.ROUTE_PATH,
              name: StatisticsScreen.ROUTE_NAME,
              builder: (context, state) => const StatisticsScreen(),
            ),
            GoRoute(
              path: DispatchScreen.ROUTE_PATH,
              name: DispatchScreen.ROUTE_NAME,
              builder: (context, state) => const DispatchScreen(),
              routes: [
                GoRoute(
                  path: EventTypesScreen.ROUTE_SUB_PATH,
                  name: EventTypesScreen.ROUTE_NAME,
                  builder: (context, state) => const EventTypesScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    registerGoRouter(goRouter);
    return goRouter;
  }

  static String? _redirect(BuildContext context, GoRouterState state) {
    final userManager = locator<UserManager>();
    final path = state.matchedLocation;

    if (!userManager.authResolved) {
      return path == SplashScreen.ROUTE_PATH ? null : SplashScreen.ROUTE_PATH;
    }

    if (!userManager.isSignedIn) {
      return path == SignInScreen.ROUTE_PATH ? null : SignInScreen.ROUTE_PATH;
    }

    final user = userManager.user;
    if (user == null) {
      // Signed in, but the backend hasn't created the profile doc yet.
      return path == SplashScreen.ROUTE_PATH ? null : SplashScreen.ROUTE_PATH;
    }

    // Mobile builds are Interface 2 only, regardless of role.
    if (!kIsWeb) {
      return path == EmployeeHomeScreen.ROUTE_PATH
          ? null
          : EmployeeHomeScreen.ROUTE_PATH;
    }

    final home = _homeFor(user.role);
    if (path == SplashScreen.ROUTE_PATH || path == SignInScreen.ROUTE_PATH) {
      return home;
    }

    final wantsShell =
        _webShellPaths.any((shellPath) => path.startsWith(shellPath));
    if (wantsShell && !_mayAccess(user.role, path)) return home;

    return null;
  }

  static String _homeFor(UserRole role) {
    if (role.canManage) return SchedulerScreen.ROUTE_PATH;
    if (role.canDispatch) return DispatchScreen.ROUTE_PATH;
    return EmployeeHomeScreen.ROUTE_PATH;
  }

  static bool _mayAccess(UserRole role, String path) {
    if (role.canManage) return true;
    if (role.canDispatch) return path.startsWith(DispatchScreen.ROUTE_PATH);
    return false;
  }
}
