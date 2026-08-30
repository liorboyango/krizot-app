import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../managers/user_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/breakpoints.dart';
import '../dispatch/dispatch_screen.dart';
import 'scheduler_screen.dart';
import 'stations_screen.dart';
import 'users_screen.dart';

/// Web chrome for Interfaces 1 & 3: a NavigationRail (wide) or bottom bar
/// (narrow) whose destinations are filtered by role — this is the
/// "switch between Scheduler and Dispatch" surface from DESIGN.md.
class WebShell extends StatelessWidget {
  final Widget child;

  const WebShell({super.key, required this.child});

  static List<
      ({
        String path,
        String label,
        IconData icon,
        bool managerOnly,
      })> _destinations(AppLocalizations l10n) => [
        (
          path: SchedulerScreen.ROUTE_PATH,
          label: l10n.navScheduler,
          icon: Icons.calendar_month,
          managerOnly: true,
        ),
        (
          path: StationsScreen.ROUTE_PATH,
          label: l10n.navStations,
          icon: Icons.location_on_outlined,
          managerOnly: true,
        ),
        (
          path: UsersScreen.ROUTE_PATH,
          label: l10n.navStaff,
          icon: Icons.people_outline,
          managerOnly: true,
        ),
        (
          path: DispatchScreen.ROUTE_PATH,
          label: l10n.navDispatch,
          icon: Icons.campaign_outlined,
          managerOnly: false,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userManager = locator<UserManager>();
    return StreamBuilder<AppUser?>(
      initialData: userManager.user,
      stream: userManager.onUserChanged,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final role = user?.role ?? UserRole.employee;
        final visible = _destinations(l10n)
            .where((d) => role.canManage || (!d.managerOnly && role.canDispatch))
            .toList();
        final location =
            GoRouterState.of(context).matchedLocation;
        var selectedIndex =
            visible.indexWhere((d) => location.startsWith(d.path));
        if (selectedIndex < 0) selectedIndex = 0;

        final width = MediaQuery.of(context).size.width;
        final useRail = width >= Breakpoints.tablet;

        void onSelect(int index) => context.go(visible[index].path);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Row(
            children: [
              if (useRail)
                NavigationRail(
                  backgroundColor: AppColors.primary,
                  indicatorColor: AppColors.accent,
                  extended: width >= Breakpoints.desktop,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelect,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Icon(Icons.calendar_month,
                        color: Colors.white, size: 32),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          tooltip: l10n.signOut,
                          icon: const Icon(Icons.logout, color: Colors.white70),
                          onPressed: () => userManager.signOut(),
                        ),
                      ),
                    ),
                  ),
                  selectedLabelTextStyle: const TextStyle(color: Colors.white),
                  unselectedLabelTextStyle:
                      const TextStyle(color: AppColors.sidebarTextMuted),
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  unselectedIconTheme:
                      const IconThemeData(color: AppColors.sidebarTextMuted),
                  destinations: [
                    for (final destination in visible)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              Expanded(child: child),
            ],
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelect,
                  destinations: [
                    for (final destination in visible)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
