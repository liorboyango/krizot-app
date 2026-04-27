import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/app_colors.dart';
import '../common/loading_shimmer.dart';
import '../common/error_banner.dart';

/// Weekly grid view showing stations vs days with colored shift cells
class WeeklyGridView extends ConsumerWidget {
  final bool isDesktop;
  final bool isTablet;

  const WeeklyGridView({
    super.key,
    required this.isDesktop,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyScheduleProvider);

    return weeklyAsync.when(
      loading: () => const _GridShimmer(),
      error: (error, _) => ErrorBanner(
        message: error.toString().replaceFirst('Exception: ', ''),
        onRetry: () => ref.invalidate(weeklyScheduleProvider),
      ),
      data: (weekly) => isDesktop || isTablet
          ? _DesktopWeeklyGrid(weekly: weekly)
          : _MobileWeeklyGrid(weekly: weekly),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop weekly grid (full table)
// ---------------------------------------------------------------------------
class _DesktopWeeklyGrid extends ConsumerWidget {
  final WeeklySchedule weekly;

  const _DesktopWeeklyGrid({required this.weekly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
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
          children: [
            // Header row
            _GridHeaderRow(days: weekly.days),
            const Divider(height: 1, color: AppColors.border),
            // Station rows
            if (weekly.grid.isEmpty)
              _EmptyGridState()
            else
              ...weekly.grid.map(
                (row) => _StationRow(
                  row: row,
                  days: weekly.days,
                  onCellTap: (schedule) {
                    ref.read(assignmentPanelProvider.notifier).open(schedule);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridHeaderRow extends StatelessWidget {
  final List<DayInfo> days;

  const _GridHeaderRow({required this.days});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Station column header
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              'Station',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          // Day columns
          ...days.map(
            (day) => Expanded(
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      day.dayName.substring(0, 3).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      DateFormat('d').format(day.date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _isToday(day.date)
                            ? AppColors.accent
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _StationRow extends StatelessWidget {
  final StationWeekRow row;
  final List<DayInfo> days;
  final ValueChanged<Schedule> onCellTap;

  const _StationRow({
    required this.row,
    required this.days,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          // Station name
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.station.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  row.station.location,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, color: AppColors.border),
          // Day cells
          ...days.map((day) {
            final schedules = row.days[day.index] ?? [];
            return Expanded(
              child: _DayCell(
                schedules: schedules,
                onTap: schedules.isNotEmpty
                    ? () => onCellTap(schedules.first)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DayCell extends StatefulWidget {
  final List<Schedule> schedules;
  final VoidCallback? onTap;

  const _DayCell({required this.schedules, this.onTap});

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.schedules.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.background : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _hovered ? AppColors.border : Colors.transparent,
          ),
        ),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: const Center(
            child: Text(
              '—',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.schedules
                .take(2)
                .map((s) => _ShiftChip(schedule: s, isHovered: _hovered))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  final Schedule schedule;
  final bool isHovered;

  const _ShiftChip({required this.schedule, required this.isHovered});

  @override
  Widget build(BuildContext context) {
    final (bg, textColor, label) = _chipStyle();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isHovered ? bg.withOpacity(0.9) : bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isHovered
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  (Color, Color, String) _chipStyle() {
    if (schedule.isCritical) {
      return (
        AppColors.shiftCritical,
        AppColors.danger,
        '! ${schedule.user?.initials ?? 'CRIT'}',
      );
    }
    if (schedule.isCovered) {
      return (
        AppColors.shiftCovered,
        AppColors.success,
        schedule.user?.initials ?? 'OK',
      );
    }
    return (
      AppColors.shiftOpen,
      const Color(0xFF92400E),
      'Open',
    );
  }
}

class _EmptyGridState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(48),
      child: const Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No schedules for this week',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Create a new shift to get started',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile weekly grid (scrollable cards per day)
// ---------------------------------------------------------------------------
class _MobileWeeklyGrid extends ConsumerWidget {
  final WeeklySchedule weekly;

  const _MobileWeeklyGrid({required this.weekly});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (weekly.grid.isEmpty) {
      return const Center(
        child: Text(
          'No schedules this week',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weekly.days.length,
      itemBuilder: (context, dayIndex) {
        final day = weekly.days[dayIndex];
        final daySchedules = <StationWeekRow>[];
        for (final row in weekly.grid) {
          if ((row.days[day.index] ?? []).isNotEmpty) {
            daySchedules.add(row);
          }
        }

        return _MobileDayCard(
          day: day,
          stationRows: daySchedules,
          allRows: weekly.grid,
          onScheduleTap: (schedule) {
            ref.read(assignmentPanelProvider.notifier).open(schedule);
          },
        );
      },
    );
  }
}

class _MobileDayCard extends StatelessWidget {
  final DayInfo day;
  final List<StationWeekRow> stationRows;
  final List<StationWeekRow> allRows;
  final ValueChanged<Schedule> onScheduleTap;

  const _MobileDayCard({
    required this.day,
    required this.stationRows,
    required this.allRows,
    required this.onScheduleTap,
  });

  bool get _isToday {
    final now = DateTime.now();
    return day.date.year == now.year &&
        day.date.month == now.month &&
        day.date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isToday ? AppColors.accent : AppColors.border,
          width: _isToday ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _isToday
                  ? AppColors.accent.withOpacity(0.08)
                  : AppColors.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Text(
                  '${day.dayName}, ${DateFormat('MMM d').format(day.date)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        _isToday ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
                if (_isToday) ...
                  [
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Today',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          ),
          // Schedules for this day
          ...allRows.map((row) {
            final schedules = row.days[day.index] ?? [];
            if (schedules.isEmpty) return const SizedBox.shrink();
            return _MobileScheduleRow(
              station: row.station,
              schedules: schedules,
              onTap: () => onScheduleTap(schedules.first),
            );
          }),
          if (allRows.every((r) => (r.days[day.index] ?? []).isEmpty))
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No shifts scheduled',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MobileScheduleRow extends StatelessWidget {
  final StationInfo station;
  final List<Schedule> schedules;
  final VoidCallback onTap;

  const _MobileScheduleRow({
    required this.station,
    required this.schedules,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final schedule = schedules.first;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: schedule.isCritical
                    ? AppColors.danger
                    : schedule.isCovered
                        ? AppColors.success
                        : AppColors.warning,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    schedule.shiftTimeLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Assignee chip
            _ShiftChip(schedule: schedule, isHovered: false),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading shimmer
// ---------------------------------------------------------------------------
class _GridShimmer extends StatelessWidget {
  const _GridShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          6,
          (i) => Container(
            height: 64,
            margin: const EdgeInsets.only(bottom: 1),
            child: const LoadingShimmer(),
          ),
        ),
      ),
    );
  }
}
