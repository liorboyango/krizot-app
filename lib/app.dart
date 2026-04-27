import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/stations_screen.dart';
import 'utils/app_theme.dart';

/// Root application widget.
///
/// Configures theme, routing, and authentication guards.
class KrizotApp extends ConsumerWidget {
  const KrizotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _buildRouter(ref);
    return MaterialApp.router(
      title: 'Krizot',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        if (!authState.isInitialized) return null;

        final isLoggedIn = authState.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoginRoute) return '/login';
        if (isLoggedIn && isLoginRoute) return '/dashboard';
        return null;
      },
      refreshListenable: _AuthStateListenable(ref),
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              AppShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/stations',
              builder: (context, state) => const StationsScreen(),
            ),
          ],
        ),
      ],
    );
  }
}

/// Listenable that triggers router refresh on auth state changes.
class _AuthStateListenable extends ChangeNotifier {
  final WidgetRef _ref;
  late final _subscription;

  _AuthStateListenable(this._ref) {
    _subscription = _ref.listenManual(
      authProvider,
      (_, __) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

/// Shell layout with persistent sidebar navigation.
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1280;
    final isTablet = width >= 900;

    if (isDesktop) {
      return _DesktopShell(child: child);
    } else if (isTablet) {
      return _TabletShell(child: child);
    } else {
      return _MobileShell(child: child);
    }
  }
}

/// Desktop shell with full 220px sidebar.
class _DesktopShell extends ConsumerWidget {
  final Widget child;

  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          const SideNavigation(collapsed: false),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Tablet shell with collapsed 64px icon-only sidebar.
class _TabletShell extends ConsumerWidget {
  final Widget child;

  const _TabletShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          const SideNavigation(collapsed: true),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Mobile shell with bottom navigation bar.
class _MobileShell extends ConsumerWidget {
  final Widget child;

  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    int currentIndex = 0;
    if (location.startsWith('/dashboard')) currentIndex = 0;
    if (location.startsWith('/stations')) currentIndex = 1;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/stations');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers),
            label: 'Stations',
          ),
        ],
      ),
    );
  }
}

/// Persistent side navigation widget.
class SideNavigation extends ConsumerWidget {
  final bool collapsed;

  const SideNavigation({super.key, this.collapsed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final width = collapsed ? 64.0 : 220.0;

    return Container(
      width: width,
      color: const Color(0xFF1A2B4A),
      child: Column(
        children: [
          // Logo area
          Container(
            height: 64,
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 12 : 20,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D7CFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bolt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                if (!collapsed) ...
                  [
                    const SizedBox(width: 10),
                    const Text(
                      'KRIZOT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
              ],
            ),
          ),
          const Divider(color: Color(0x33FFFFFF), height: 1),
          const SizedBox(height: 8),
          // Nav items
          _NavItem(
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Dashboard',
            route: '/dashboard',
            isSelected: location.startsWith('/dashboard'),
            collapsed: collapsed,
          ),
          _NavItem(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
            label: 'Schedule',
            route: '/schedule',
            isSelected: location.startsWith('/schedule'),
            collapsed: collapsed,
          ),
          _NavItem(
            icon: Icons.layers_outlined,
            selectedIcon: Icons.layers,
            label: 'Stations',
            route: '/stations',
            isSelected: location.startsWith('/stations'),
            collapsed: collapsed,
          ),
          _NavItem(
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            label: 'Staff',
            route: '/staff',
            isSelected: location.startsWith('/staff'),
            collapsed: collapsed,
          ),
          _NavItem(
            icon: Icons.bar_chart_outlined,
            selectedIcon: Icons.bar_chart,
            label: 'Reports',
            route: '/reports',
            isSelected: location.startsWith('/reports'),
            collapsed: collapsed,
          ),
          const Spacer(),
          const Divider(color: Color(0x33FFFFFF), height: 1),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
            label: 'Settings',
            route: '/settings',
            isSelected: location.startsWith('/settings'),
            collapsed: collapsed,
          ),
          _LogoutNavItem(collapsed: collapsed),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Individual navigation item.
class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final bool isSelected;
  final bool collapsed;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.collapsed,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? const Color(0xFF0D7CFF)
        : _isHovered
            ? const Color(0xFF2C4270)
            : Colors.transparent;

    final textColor = widget.isSelected || _isHovered
        ? Colors.white
        : const Color(0xB3FFFFFF);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 12 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (widget.isSelected)
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(right: 8),
                )
              else
                const SizedBox(width: 11),
              Icon(
                widget.isSelected ? widget.selectedIcon : widget.icon,
                size: 20,
                color: textColor,
              ),
              if (!widget.collapsed) ...
                [
                  const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Logout navigation item.
class _LogoutNavItem extends ConsumerStatefulWidget {
  final bool collapsed;

  const _LogoutNavItem({required this.collapsed});

  @override
  ConsumerState<_LogoutNavItem> createState() => _LogoutNavItemState();
}

class _LogoutNavItemState extends ConsumerState<_LogoutNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () async {
          await ref.read(authProvider.notifier).logout();
          if (context.mounted) context.go('/login');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 12 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFE53E3E).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 11),
              Icon(
                Icons.logout,
                size: 20,
                color: _isHovered
                    ? const Color(0xFFE53E3E)
                    : const Color(0xB3FFFFFF),
              ),
              if (!widget.collapsed) ...
                [
                  const SizedBox(width: 10),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isHovered
                          ? const Color(0xFFE53E3E)
                          : const Color(0xB3FFFFFF),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
