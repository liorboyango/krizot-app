import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/schedule_model.dart';
import '../utils/app_colors.dart';
import '../utils/breakpoints.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/side_navigation.dart';
import '../widgets/top_bar.dart';
import '../widgets/shimmer_loading.dart';

/// Main dashboard screen with responsive layout.
/// Desktop: sidebar + stats + schedule table.
/// Tablet: compact sidebar + stats + table.
/// Mobile: bottom nav + cards.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _currentRoute = '/dashboard';

  void _handleNavigate(String route) {
    if (route.isEmpty) return;
    setState(() => _currentRoute = route);
    // Navigate to route when other screens are implemented
    if (route != '/dashboard') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$route coming soon'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final authState = ref.watch(authStateProvider).valueOrNull;
    final user = authState?.user;

    if (width >= Breakpoints.desktop) {
      return _DesktopLayout(
        currentRoute: _currentRoute,
        onNavigate: _handleNavigate,
        onLogout: _handleLogout,
        userName: user?.name ?? '',
        userInitials: user?.initials ?? '?',
        userRole: user?.role ?? '',
      );
    } else if (width >= Breakpoints.tablet) {
      return _TabletLayout(
        currentRoute: _currentRoute,
        onNavigate: _handleNavigate,
        onLogout: _handleLogout,
        userName: user?.name ?? '',
        userInitials: user?.initials ?? '?',
        userRole: user?.role ?? '',
      );
    } else {
      return _MobileLayout(
        currentRoute: _currentRoute,
        onNavigate: _handleNavigate,
        onLogout: _handleLogout,
        userName: user?.name ?? '',
        userInitials: user?.initials ?? '?',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Layout
// ─────────────────────────────────────────────────────────────────────────────

class _DesktopLayout extends ConsumerWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final String userName;
  final String userInitials;
  final String userRole;

  const _DesktopLayout({
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
    required this.userName,
    required this.userInitials,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          SideNavigation(
            currentRoute: currentRoute,
            onNavigate: onNavigate,
            onLogout: onLogout,
            userName: userName,
            userRole: userRole,
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                TopBar(
                  title: 'Dashboard',
                  userName: userName,
                  userInitials: userInitials,
                ),
                Expanded(
                  child: _DashboardContent(userName: userName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tablet Layout
// ─────────────────────────────────────────────────────────────────────────────

class _TabletLayout extends ConsumerWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final String userName;
  final String userInitials;
  final String userRole;

  const _TabletLayout({
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
    required this.userName,
    required this.userInitials,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Compact sidebar
          TabletSideNavigation(
            currentRoute: currentRoute,
            onNavigate: onNavigate,
            onLogout: onLogout,
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                TopBar(
                  title: 'Dashboard',
                  userName: userName,
                  userInitials: userInitials,
                ),
                Expanded(
                  child: _DashboardContent(userName: userName),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Layout
// ─────────────────────────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerWidget {
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final String userName;
  final String userInitials;

  const _MobileLayout({
    required this.currentRoute,
    required this.onNavigate,
    required this.onLogout,
    required this.userName,
    required this.userInitials,
  });

  int get _selectedIndex {
    const routes = ['/dashboard', '/schedule', '/stations', '/staff', '/reports'];
    final idx = routes.indexOf(currentRoute);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'KRIZOT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.accent,
              child: Text(
                userInitials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _DashboardContent(userName: userName),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: AppColors.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          const routes = ['/dashboard', '/schedule', '/stations', '/staff', '/reports'];
          onNavigate(routes[index]);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.layers_outlined),
            activeIcon: Icon(Icons.layers),
            label: 'Stations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Staff',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard Content (shared across layouts)
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardContent extends ConsumerWidget {
  final String userName;

  const _DashboardContent({required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < Breakpoints.mobile;

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardStatsProvider.notifier).refresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting strip
            _GreetingStrip(userName: userName),
            const SizedBox(height: 24),

            // Stat cards
            statsAsync.when(
              loading: () => const StatCardsShimmer(),
              error: (e, _) => _ErrorBanner(
                message: e.toString(),
                onRetry: () => ref.read(dashboardStatsProvider.notifier).refresh(),
              ),
              data: (state) {
                if (state.error != null) {
                  return _ErrorBanner(
                    message: state.error!,
                    onRetry: () =>
                        ref.read(dashboardStatsProvider.notifier).refresh(),
                  );
                }
                final stats = state.stats ?? DashboardStats.empty();
                return _StatCardsRow(stats: stats, isMobile: isMobile);
              },
            ),
            const SizedBox(height: 24),

            // Today's schedule table
            statsAsync.when(
              loading: () => _ScheduleTableCard(
                schedules: const [],
                isLoading: true,
              ),
              error: (e, _) => _ScheduleTableCard(
                schedules: const [],
                isLoading: false,
              ),
              data: (state) => _ScheduleTableCard(
                schedules: state.stats?.todaySchedules ?? [],
                isLoading: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Greeting Strip
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingStrip extends StatelessWidget {
  final String userName;

  const _GreetingStrip({required this.userName});

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(now);
    final displayName = userName.isNotEmpty ? ', $userName' : '';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting$displayName 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Refresh button
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Consumer(
            builder: (context, ref, _) => IconButton(
              onPressed: () =>
                  ref.read(dashboardStatsProvider.notifier).refresh(),
              icon: const Icon(
                Icons.refresh_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              tooltip: 'Refresh',
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Cards Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatCardsRow extends StatelessWidget {
  final DashboardStats stats;
  final bool isMobile;

  const _StatCardsRow({required this.stats, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        label: 'Total Stations',
        value: stats.activeStations.toString(),
        icon: Icons.layers_outlined,
        accentColor: AppColors.success,
        iconBgColor: AppColors.shiftCovered,
      ),
      StatCard(
        label: 'On Duty',
        value: stats.onDuty.toString(),
        icon: Icons.people_outline,
        accentColor: AppColors.info,
        iconBgColor: const Color(0xFFEBF4FF),
      ),
      StatCard(
        label: 'Open Shifts',
        value: stats.openShifts.toString(),
        icon: Icons.schedule_outlined,
        accentColor: AppColors.warning,
        iconBgColor: AppColors.shiftOpen,
      ),
      StatCard(
        label: 'Critical',
        value: stats.criticalShifts.toString(),
        icon: Icons.warning_amber_outlined,
        accentColor: AppColors.danger,
        iconBgColor: AppColors.shiftCritical,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: cards,
      );
    }

    return Row(
      children: cards
          .asMap()
          .entries
          .map((e) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e.key < 3 ? 16 : 0),
                  child: e.value,
                ),
              ))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Schedule Table Card
// ─────────────────────────────────────────────────────────────────────────────

class _ScheduleTableCard extends StatelessWidget {
  final List<ScheduleModel> schedules;
  final bool isLoading;

  const _ScheduleTableCard({
    required this.schedules,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < Breakpoints.mobile;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              children: [
                const Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (!isMobile)
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.open_in_new, size: 14),
                    label: const Text('View All'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Table content
          if (isLoading)
            const TableShimmer(rowCount: 6)
          else if (schedules.isEmpty)
            _EmptySchedule()
          else if (isMobile)
            _MobileScheduleList(schedules: schedules)
          else
            _DesktopScheduleTable(schedules: schedules),
        ],
      ),
    );
  }
}

/// Desktop data table for today's schedules.
class _DesktopScheduleTable extends StatelessWidget {
  final List<ScheduleModel> schedules;

  const _DesktopScheduleTable({required this.schedules});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Column headers
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.tableRowAlt,
          child: const Row(
            children: [
              _TableHeader(label: 'Station', flex: 2),
              _TableHeader(label: 'Shift Time', flex: 2),
              _TableHeader(label: 'Assigned To', flex: 2),
              _TableHeader(label: 'Status', flex: 1),
              _TableHeader(label: 'Actions', flex: 1),
            ],
          ),
        ),
        const Divider(height: 1),
        // Data rows
        ...schedules.asMap().entries.map(
              (e) => _ScheduleTableRow(
                schedule: e.value,
                isEven: e.key.isEven,
              ),
            ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;

  const _TableHeader({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Individual schedule table row with hover effect.
class _ScheduleTableRow extends StatefulWidget {
  final ScheduleModel schedule;
  final bool isEven;

  const _ScheduleTableRow({
    required this.schedule,
    required this.isEven,
  });

  @override
  State<_ScheduleTableRow> createState() => _ScheduleTableRowState();
}

class _ScheduleTableRowState extends State<_ScheduleTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final schedule = widget.schedule;
    final stationName = schedule.station?.name ?? 'Station ${schedule.stationId}';
    final assignedTo = schedule.user?.name ?? 'Unassigned';
    final status = schedule.shiftStatus;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.tableRowHover
              : widget.isEven
                  ? AppColors.surface
                  : AppColors.tableRowAlt,
          border: const Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            // Station
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: schedule.station?.isActive == true
                          ? AppColors.success
                          : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    stationName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Shift time
            Expanded(
              flex: 2,
              child: Text(
                schedule.shiftTimeRange,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            // Assigned to
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  if (schedule.isAssigned) ...
                    [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.accent.withOpacity(0.15),
                        child: Text(
                          schedule.user?.initials ?? '?',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  Text(
                    assignedTo,
                    style: TextStyle(
                      fontSize: 13,
                      color: schedule.isAssigned
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontStyle: schedule.isAssigned
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // Status chip
            Expanded(
              flex: 1,
              child: StatusChip.fromString(status),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: AnimatedOpacity(
                opacity: _isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      tooltip: 'Edit',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.person_add_outlined,
                        size: 16,
                        color: AppColors.success,
                      ),
                      tooltip: 'Assign',
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mobile card list for schedules.
class _MobileScheduleList extends StatelessWidget {
  final List<ScheduleModel> schedules;

  const _MobileScheduleList({required this.schedules});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: schedules
          .map((s) => _MobileScheduleCard(schedule: s))
          .toList(),
    );
  }
}

class _MobileScheduleCard extends StatelessWidget {
  final ScheduleModel schedule;

  const _MobileScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final stationName = schedule.station?.name ?? 'Station ${schedule.stationId}';
    final assignedTo = schedule.user?.name ?? 'Unassigned';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stationName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${schedule.shiftTimeRange} · $assignedTo',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          StatusChip.fromString(schedule.shiftStatus),
        ],
      ),
    );
  }
}

/// Empty state for schedule table.
class _EmptySchedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'No schedules for today',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Create a new shift to get started',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('New Shift'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error banner with retry button.
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.shiftCritical,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.danger,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}
