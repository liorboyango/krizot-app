import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Navigation item data model.
class NavItem {
  final String label;
  final IconData icon;
  final String route;

  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// Desktop sidebar navigation (220px wide).
class SideNavigation extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final String userName;
  final String userRole;

  static const List<NavItem> _mainItems = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/dashboard'),
    NavItem(label: 'Schedule', icon: Icons.calendar_month_outlined, route: '/schedule'),
    NavItem(label: 'Stations', icon: Icons.layers_outlined, route: '/stations'),
    NavItem(label: 'Staff', icon: Icons.people_outline, route: '/staff'),
    NavItem(label: 'Reports', icon: Icons.bar_chart_outlined, route: '/reports'),
  ];

  static const List<NavItem> _bottomItems = [
    NavItem(label: 'Settings', icon: Icons.settings_outlined, route: '/settings'),
  ];

  const SideNavigation({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppColors.primary,
      child: Column(
        children: [
          // Logo area
          _buildLogo(),
          const SizedBox(height: 8),
          // Main nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _mainItems
                  .map((item) => _NavItemTile(
                        item: item,
                        isSelected: currentRoute == item.route,
                        onTap: () => onNavigate(item.route),
                      ))
                  .toList(),
            ),
          ),
          // Bottom items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                const Divider(color: Color(0x33FFFFFF), height: 1),
                const SizedBox(height: 8),
                ..._bottomItems.map((item) => _NavItemTile(
                      item: item,
                      isSelected: currentRoute == item.route,
                      onTap: () => onNavigate(item.route),
                    )),
                _NavItemTile(
                  item: const NavItem(
                    label: 'Logout',
                    icon: Icons.logout_outlined,
                    route: '',
                  ),
                  isSelected: false,
                  onTap: onLogout,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // User info
          _buildUserInfo(),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'KRIZOT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x33FFFFFF))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accent,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userRole.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.sidebarTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual navigation item tile.
class _NavItemTile extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavItemTile> createState() => _NavItemTileState();
}

class _NavItemTileState extends State<_NavItemTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isHovered = _isHovered;

    Color bgColor = Colors.transparent;
    Color textColor = AppColors.sidebarTextMuted;

    if (isSelected) {
      bgColor = AppColors.accent;
      textColor = Colors.white;
    } else if (isHovered) {
      bgColor = AppColors.primaryLight;
      textColor = Colors.white;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Left accent bar for selected state
              if (isSelected)
                Positioned(
                  left: 0,
                  top: 4,
                  bottom: 4,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      widget.item.icon,
                      size: 20,
                      color: textColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.item.label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact tablet sidebar (icons only, 64px wide).
class TabletSideNavigation extends StatelessWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;

  static const List<NavItem> _items = [
    NavItem(label: 'Dashboard', icon: Icons.dashboard_outlined, route: '/dashboard'),
    NavItem(label: 'Schedule', icon: Icons.calendar_month_outlined, route: '/schedule'),
    NavItem(label: 'Stations', icon: Icons.layers_outlined, route: '/stations'),
    NavItem(label: 'Staff', icon: Icons.people_outline, route: '/staff'),
    NavItem(label: 'Reports', icon: Icons.bar_chart_outlined, route: '/reports'),
  ];

  const TabletSideNavigation({
    super.key,
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      color: AppColors.primary,
      child: Column(
        children: [
          // Logo icon
          Container(
            height: 64,
            alignment: Alignment.center,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
            ),
          ),
          // Nav icons
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _items
                  .map((item) => _TabletNavIcon(
                        item: item,
                        isSelected: currentRoute == item.route,
                        onTap: () => onNavigate(item.route),
                      ))
                  .toList(),
            ),
          ),
          // Logout
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _TabletNavIcon(
              item: const NavItem(
                label: 'Logout',
                icon: Icons.logout_outlined,
                route: '',
              ),
              isSelected: false,
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabletNavIcon extends StatefulWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabletNavIcon({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_TabletNavIcon> createState() => _TabletNavIconState();
}

class _TabletNavIconState extends State<_TabletNavIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    Color bgColor = Colors.transparent;
    Color iconColor = AppColors.sidebarTextMuted;

    if (isSelected) {
      bgColor = AppColors.accent;
      iconColor = Colors.white;
    } else if (_isHovered) {
      bgColor = AppColors.primaryLight;
      iconColor = Colors.white;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.item.label,
        preferBelow: false,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.item.icon, size: 22, color: iconColor),
          ),
        ),
      ),
    );
  }
}
