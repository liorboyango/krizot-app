/// Dashboard screen for Krizot.
///
/// Shows:
/// - Stat cards: total stations, on duty, open shifts, critical
/// - Today's schedule table
/// - Responsive: desktop sidebar + table, mobile bottom nav + cards
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/schedules_provider.dart';
import '../providers/stations_provider.dart';
import '../models/schedule.dart';
import '../utils/app_colors.dart';
import '../utils/breakpoints.dart';
import '../utils/error_handler.dart';
import '../app.dart';
import 'schedule_screen.dart';
import 'stations_screen.dart';

/// Dashboard page.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.desktop) {
      return const _DesktopDashboard();
    }
    return const _MobileDashboard();
  }
}

// ---------------------------------------------------------------------------
// Desktop layout
// ---------------------------------------------------------------------------

class _DesktopDashboard extends ConsumerWidget {
  const _DesktopDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          const _SideNav(),
          Expanded(
            child: Column(
              children: [
                const _TopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _GreetingStrip(ref: ref),
                        const SizedBox(height: 24),
                        const _StatsRow(),
                        const SizedBox(height: 24),
                        const _TodayScheduleTable(),
                      ],
                    ),
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

// ---------------------------------------------------------------------------
// Mobile layout
// ---------------------------------------------------------------------------

class _MobileDashboard extends ConsumerStatefulWidget {
  const _MobileDashboard();

  @override
  ConsumerState<_MobileDashboard> createState() => _MobileDashboardState();
}

class _MobileDashboardState extends ConsumerState<_MobileDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Krizot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardContent(),
          ScheduleScreen(),
          StationsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.layers_outlined), label: 'Stations'),
        ],
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GreetingStrip(ref: ref),
          const SizedBox(height: 16),
          const _StatsRow(),
          const SizedBox(height: 16),
          const _TodayScheduleTable(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Side navigation
// ---------------------------------------------------------------------------

class _SideNav extends ConsumerWidget {
  const _SideNav();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 220,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo
          Padding(
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
                  child: const Center(
                    child: Text('K', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
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
            ),
          ),
          const SizedBox(height: 32),
          _NavItem(icon: Icons.home_outlined, label: 'Dashboard', route: AppRoutes.dashboard, currentRoute: location),
          _NavItem(icon: Icons.calendar_today_outlined, label: 'Schedule', route: AppRoutes.schedule, currentRoute: location),
          _NavItem(icon: Icons.layers_outlined, label: 'Stations', route: AppRoutes.stations, currentRoute: location),
          _NavItem(icon: Icons.people_outlined, label: 'Staff', route: '/staff', currentRoute: location),
          _NavItem(icon: Icons.bar_chart_outlined, label: 'Reports', route: '/reports', currentRoute: location),
          const Spacer(),
          _NavItem(icon: Icons.settings_outlined, label: 'Settings', route: '/settings', currentRoute: location),
          _NavItem(
            icon: Icons.logout,
            label: 'Logout',
            route: '',
            currentRoute: location,
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final VoidCallback? onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.currentRoute == widget.route;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap ?? () {
          if (widget.route.isNotEmpty) context.go(widget.route);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                : _hovered
                    ? AppColors.primaryLight
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: isSelected || _hovered
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected || _hovered
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.accent,
            child: Text(
              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting strip
// ---------------------------------------------------------------------------

class _GreetingStrip extends StatelessWidget {
  const _GreetingStrip({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good morning' : now.hour < 17 ? 'Good afternoon' : 'Good evening';
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, ${user?.name ?? 'Manager'}',
          style: Theme.of(context).textTheme.displayLarge,
        ),
        const SizedBox(height: 4),
        Text(dateStr, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row
// ---------------------------------------------------------------------------

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(scheduleStatsProvider(null));
    final stationStatsAsync = ref.watch(stationStatsProvider);

    return statsAsync.when(
      loading: () => const _StatsRowSkeleton(),
      error: (e, _) => _StatsRowError(error: e, onRetry: () => ref.invalidate(scheduleStatsProvider)),
      data: (stats) => stationStatsAsync.when(
        loading: () => const _StatsRowSkeleton(),
        error: (e, _) => _StatsRowError(error: e, onRetry: () => ref.invalidate(stationStatsProvider)),
        data: (stationStats) => LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final cards = [
              _StatCard(
                label: 'Total Stations',
                value: stationStats.total.toString(),
                icon: Icons.layers_outlined,
                accentColor: AppColors.success,
              ),
              _StatCard(
                label: 'On Duty',
                value: stats.onDuty.toString(),
                icon: Icons.person_outlined,
                accentColor: AppColors.info,
              ),
              _StatCard(
                label: 'Open Shifts',
                value: stats.openShifts.toString(),
                icon: Icons.schedule_outlined,
                accentColor: AppColors.warning,
              ),
              _StatCard(
                label: 'Critical',
                value: stats.criticalShifts.toString(),
                icon: Icons.warning_amber_outlined,
                accentColor: AppColors.danger,
              ),
            ];
            if (isNarrow) {
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: cards,
              );
            }
            return Row(
              children: cards
                  .map((c) => Expanded(child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: c,
                      )))
                  .toList()
                ..last = Expanded(child: cards.last),
            );
          },
        ),
      ),
    );
  }
}

class _StatsRowSkeleton extends StatelessWidget {
  const _StatsRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 3 ? 16 : 0),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRowError extends StatelessWidget {
  const _StatsRowError({required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.shiftCritical,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ErrorHandler.getMessage(error),
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent bar
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today's schedule table
// ---------------------------------------------------------------------------

class _TodayScheduleTable extends ConsumerWidget {
  const _TodayScheduleTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesNotifierProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text("Today's Schedule", style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => ref.read(schedulesNotifierProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          schedulesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: _StatsRowError(
                error: e,
                onRetry: () => ref.read(schedulesNotifierProvider.notifier).refresh(),
              ),
            ),
            data: (state) {
              if (state.schedules.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('No schedules for today', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }
              return _ScheduleTable(schedules: state.schedules);
            },
          ),
        ],
      ),
    );
  }
}

class _ScheduleTable extends StatelessWidget {
  const _ScheduleTable({required this.schedules});
  final List<Schedule> schedules;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(1.5),
        4: FlexColumnWidth(1),
      },
      children: [
        const TableRow(
          decoration: BoxDecoration(color: AppColors.tableRowAlt),
          children: [
            _TableHeader('Station'),
            _TableHeader('Shift'),
            _TableHeader('Assigned'),
            _TableHeader('Status'),
            _TableHeader('Actions'),
          ],
        ),
        ...schedules.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return TableRow(
            decoration: BoxDecoration(
              color: i.isOdd ? AppColors.tableRowAlt : AppColors.surface,
            ),
            children: [
              _TableCell(s.station?.name ?? s.stationId),
              _TableCell(
                '${_fmt(s.startTime)}-${_fmt(s.endTime)}',
              ),
              _TableCell(s.user?.name ?? (s.isAssigned ? s.userId! : 'Unassigned')),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                child: _StatusChip(isAssigned: s.isAssigned),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.accent,
                  onPressed: () {},
                  tooltip: 'Edit',
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  String _fmt(DateTime dt) => DateFormat('HH:mm').format(dt);
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(
        text,
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

class _TableCell extends StatelessWidget {
  const _TableCell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isAssigned});
  final bool isAssigned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAssigned ? AppColors.shiftCovered : AppColors.shiftOpen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAssigned ? 'Covered' : 'Open',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isAssigned ? AppColors.shiftCoveredText : AppColors.shiftOpenText,
        ),
      ),
    );
  }
}
