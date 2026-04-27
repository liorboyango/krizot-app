/// Dashboard screen – overview of stations, schedules, and key stats.
///
/// Adapts layout based on screen width:
/// - Desktop (1280px+): stat cards row + full schedule table
/// - Tablet (900px+): condensed layout
/// - Mobile (<900px): stacked cards
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../utils/app_colors.dart';
import '../utils/breakpoints.dart';
import '../utils/constants.dart';

/// The main dashboard screen.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Top bar
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: const _TopBar(),
            automaticallyImplyLeading: false,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(AppConstants.pagePadding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Greeting strip
                _GreetingStrip(),
                const SizedBox(height: 24),

                // Stat cards
                if (Breakpoints.isDesktop(width))
                  const _StatCardsRow()
                else
                  const _StatCardsGrid(),
                const SizedBox(height: 24),

                // Today's schedule table
                const _TodayScheduleSection(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Top bar
// ---------------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Krizot',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const Spacer(),
        // Search
        SizedBox(
          width: 240,
          height: 36,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search...',
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
          tooltip: 'Notifications',
        ),
        const SizedBox(width: 8),
        // Avatar
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.accent,
          child: const Text(
            'U',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Greeting strip
// ---------------------------------------------------------------------------

class _GreetingStrip extends StatelessWidget {
  _GreetingStrip();

  final String _today = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning, Commander',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _today,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Stat cards
// ---------------------------------------------------------------------------

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Stations',
            value: '--',
            icon: Icons.layers,
            accentColor: AppColors.info,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'On Duty',
            value: '--',
            icon: Icons.person,
            accentColor: AppColors.success,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Open Shifts',
            value: '--',
            icon: Icons.schedule,
            accentColor: AppColors.warning,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Critical',
            value: '--',
            icon: Icons.warning_amber,
            accentColor: AppColors.danger,
          ),
        ),
      ],
    );
  }
}

class _StatCardsGrid extends StatelessWidget {
  const _StatCardsGrid();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 160,
          child: _StatCard(
            label: 'Stations',
            value: '--',
            icon: Icons.layers,
            accentColor: AppColors.info,
          ),
        ),
        SizedBox(
          width: 160,
          child: _StatCard(
            label: 'On Duty',
            value: '--',
            icon: Icons.person,
            accentColor: AppColors.success,
          ),
        ),
        SizedBox(
          width: 160,
          child: _StatCard(
            label: 'Open Shifts',
            value: '--',
            icon: Icons.schedule,
            accentColor: AppColors.warning,
          ),
        ),
        SizedBox(
          width: 160,
          child: _StatCard(
            label: 'Critical',
            value: '--',
            icon: Icons.warning_amber,
            accentColor: AppColors.danger,
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
          top: const BorderSide(color: AppColors.border),
          right: const BorderSide(color: AppColors.border),
          bottom: const BorderSide(color: AppColors.border),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
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
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
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
// Today's schedule section (placeholder – populated in later tasks)
// ---------------------------------------------------------------------------

class _TodayScheduleSection extends StatelessWidget {
  const _TodayScheduleSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
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
          Padding(
            padding: const EdgeInsets.all(16),
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
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('New Shift'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 48,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No shifts scheduled for today',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
