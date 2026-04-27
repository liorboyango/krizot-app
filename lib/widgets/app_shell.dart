/// Authenticated app shell – wraps all protected screens with the
/// sidebar (desktop/tablet) or bottom navigation bar (mobile).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../router/app_router.dart';
import '../utils/app_colors.dart';
import '../utils/breakpoints.dart';
import '../utils/constants.dart';

/// Navigation destination descriptor.
class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
}

const List<_NavItem> _navItems = [
  _NavItem(
    label: 'Dashboard',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    route: AppRoutes.dashboard,
  ),
  _NavItem(
    label: 'Schedule',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
    route: AppRoutes.schedule,
  ),
  _NavItem(
    label: 'Stations',
    icon: Icons.layers_outlined,
    selectedIcon: Icons.layers,
    route: AppRoutes.stations,
  ),
];

/// Root shell widget that provides navigation chrome.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;

    if (Breakpoints.isDesktop(width)) {
      return _DesktopShell(child: child);
    }
    if (Breakpoints.isTablet(width)) {
      return _TabletShell(child: child);
    }
    return _MobileShell(child: child);
  }
}

// ---------------------------------------------------------------------------
// Desktop Shell – full 220 px sidebar
// ---------------------------------------------------------------------------

class _DesktopShell extends ConsumerWidget {
  const _DesktopShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(expanded: true),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tablet Shell – 64 px icon-only sidebar
// ---------------------------------------------------------------------------

class _TabletShell extends ConsumerWidget {
  const _TabletShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(expanded: false),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile Shell – bottom navigation bar
// ---------------------------------------------------------------------------

class _MobileShell extends ConsumerWidget {
  const _MobileShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _navItems.indexWhere((i) => i.route == location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accent.withOpacity(0.15),
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (index) {
          context.go(_navItems[index].route);
        },
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon, color: AppColors.accent),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sidebar widget (shared by desktop & tablet)
// ---------------------------------------------------------------------------

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = expanded
        ? AppConstants.sidebarWidth
        : AppConstants.sidebarCollapsedWidth;
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: width,
      color: AppColors.primary,
      child: Column(
        children: [
          // Logo / brand
          _SidebarHeader(expanded: expanded),

          const SizedBox(height: 8),

          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _navItems.map((item) {
                final isSelected = location == item.route;
                return _SidebarItem(
                  item: item,
                  isSelected: isSelected,
                  expanded: expanded,
                  onTap: () => context.go(item.route),
                );
              }).toList(),
            ),
          ),

          // Logout button
          _SidebarLogout(
            expanded: expanded,
            onLogout: () => ref.read(authStateProvider.notifier).logout(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: expanded
          ? const Text(
              'KRIZOT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            )
          : const Icon(Icons.shield, color: Colors.white, size: 28),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final bool expanded;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? AppColors.accent.withOpacity(0.2)
        : _hovered
            ? AppColors.primaryLight
            : Colors.transparent;

    final textColor = widget.isSelected
        ? Colors.white
        : _hovered
            ? Colors.white
            : Colors.white.withOpacity(0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.expanded ? 12 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: widget.isSelected
                ? const Border(
                    left: BorderSide(color: AppColors.accent, width: 3),
                  )
                : null,
          ),
          child: widget.expanded
              ? Row(
                  children: [
                    Icon(
                      widget.isSelected
                          ? widget.item.selectedIcon
                          : widget.item.icon,
                      color: textColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.item.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Icon(
                    widget.isSelected
                        ? widget.item.selectedIcon
                        : widget.item.icon,
                    color: textColor,
                    size: 20,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SidebarLogout extends StatelessWidget {
  const _SidebarLogout({
    required this.expanded,
    required this.onLogout,
  });

  final bool expanded;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: onLogout,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withOpacity(0.7),
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 12 : 0,
            vertical: 10,
          ),
        ),
        child: expanded
            ? const Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(fontSize: 14)),
                ],
              )
            : const Icon(Icons.logout, size: 20),
      ),
    );
  }
}
