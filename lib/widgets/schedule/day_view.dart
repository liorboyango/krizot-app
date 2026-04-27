import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/app_colors.dart';
import '../common/loading_shimmer.dart';
import '../common/error_banner.dart';

/// Day view showing all schedules for a selected day
class DayView extends ConsumerWidget {
  final bool isDesktop;

  const DayView({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final schedulesState = ref.watch(schedulesListProvider);

    // Filter schedules for selected day
    final daySchedules = schedulesState.schedules.where((s) {
      return s.startTime.year == selectedDay.year &&
          s.startTime.month == selectedDay.month &&
          s.startTime.day == selectedDay.day;
    }).toList();

    return Column(
      children: [
        // Day selector
        _DaySelector(selectedDay: selectedDay),
        // Content
        Expanded(
          child: schedulesState.isLoading
              ? const _DayShimmer()
              : schedulesState.error != null
                  ? ErrorBanner(
                      message: schedulesState.error!,
                      onRetry: () => ref
                          .read(schedulesListProvider.notifier)
                          .loadSchedules(),
                    )
                  : daySchedules.isEmpty
                      ? _EmptyDayState(day: selectedDay)
                      : isDesktop
                          ? _DesktopDayTable(schedules: daySchedules)
                          : _MobileDayList(schedules: daySchedules),
        ),
      ],
    );
  }
}

class _DaySelector extends ConsumerWidget {
  final DateTime selectedDay;

  const _DaySelector({required this.selectedDay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekProvider);
    final days = List.generate(
      7,
      (i) => weekStart.add(Duration(days: i)),
    );

    return Container(
      height: 72,
      color: AppColors.surface,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: days.length,
        itemBuilder: (context, i) {
          final day = days[i];
          final isSelected = day.year == selectedDay.year &&
              day.month == selectedDay.month &&
              day.day == selectedDay.day;
          final isToday = day.year == DateTime.now().year &&
              day.month == DateTime.now().month &&
              day.day == DateTime.now().day;

          return GestureDetector(
            onTap: () {
              ref.read(selectedDayProvider.notifier).state = day;
              ref
                  .read(schedulesListProvider.notifier)
                  .loadSchedules(startDate: day, endDate: day);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent
                      : isToday
                          ? AppColors.accent.withOpacity(0.4)
                          : AppColors.border,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.accent
                              : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DesktopDayTable extends ConsumerWidget {
  final List<Schedule> schedules;

  const _DesktopDayTable({required this.schedules});

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
            // Table header
            Container(
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  _HeaderCell(label: 'Station', flex: 2),
                  _HeaderCell(label: 'Shift Time', flex: 2),
                  _HeaderCell(label: 'Assigned To', flex: 2),
                  _HeaderCell(label: 'Status', flex: 1),
                  _HeaderCell(label: 'Actions', flex: 1),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Rows
            ...schedules.map(
              (s) => _DayTableRow(
                schedule: s,
                onAssign: () =>
                    ref.read(assignmentPanelProvider.notifier).open(s),
                onDelete: () async {
                  final confirm = await _confirmDelete(context);
                  if (confirm == true) {
                    await ref
                        .read(schedulesListProvider.notifier)
                        .deleteSchedule(s.id);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shift'),
        content: const Text('Are you sure you want to delete this shift?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _HeaderCell({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _DayTableRow extends StatefulWidget {
  final Schedule schedule;
  final VoidCallback onAssign;
  final VoidCallback onDelete;

  const _DayTableRow({
    required this.schedule,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  State<_DayTableRow> createState() => _DayTableRowState();
}

class _DayTableRowState extends State<_DayTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.accent.withOpacity(0.04)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            // Station
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  s.station?.name ?? s.stationId,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            // Shift time
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  s.shiftTimeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Assigned to
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: s.user != null
                    ? Row(
                        children: [
                          _UserAvatar(user: s.user!),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.user!.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Unassigned',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
            ),
            // Status
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatusChip(schedule: s),
              ),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    children: [
                      Tooltip(
                        message: s.isCovered ? 'Edit assignment' : 'Assign',
                        child: IconButton(
                          icon: Icon(
                            s.isCovered ? Icons.edit : Icons.person_add,
                            size: 18,
                            color: AppColors.accent,
                          ),
                          onPressed: widget.onAssign,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Delete shift',
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.danger,
                          ),
                          onPressed: widget.onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileDayList extends ConsumerWidget {
  final List<Schedule> schedules;

  const _MobileDayList({required this.schedules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, i) {
        final s = schedules[i];
        return _MobileScheduleCard(
          schedule: s,
          onAssign: () =>
              ref.read(assignmentPanelProvider.notifier).open(s),
          onDelete: () async {
            await ref
                .read(schedulesListProvider.notifier)
                .deleteSchedule(s.id);
          },
        );
      },
    );
  }
}

class _MobileScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onAssign;
  final VoidCallback onDelete;

  const _MobileScheduleCard({
    required this.schedule,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = schedule;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Status bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: s.isCritical
                  ? AppColors.danger
                  : s.isCovered
                      ? AppColors.success
                      : AppColors.warning,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.station?.name ?? s.stationId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _StatusChip(schedule: s),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.shiftTimeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (s.station?.location.isNotEmpty == true) ...
                  [
                    const SizedBox(height: 2),
                    Text(
                      s.station!.location,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (s.user != null) ...
                      [
                        _UserAvatar(user: s.user!),
                        const SizedBox(width: 8),
                        Text(
                          s.user!.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ]
                    else
                      const Text(
                        'Unassigned',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: onAssign,
                      icon: Icon(
                        s.isCovered ? Icons.edit : Icons.person_add,
                        size: 16,
                      ),
                      label: Text(s.isCovered ? 'Edit' : 'Assign'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDayState extends StatelessWidget {
  final DateTime day;

  const _EmptyDayState({required this.day});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_available_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            'No shifts on ${DateFormat('EEEE, MMM d').format(day)}',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to create a new shift',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayShimmer extends StatelessWidget {
  const _DayShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            height: 52,
            margin: const EdgeInsets.only(bottom: 1),
            child: const LoadingShimmer(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------
class _UserAvatar extends StatelessWidget {
  final UserInfo user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Schedule schedule;

  const _StatusChip({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final (bg, textColor, label) = _style();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  (Color, Color, String) _style() {
    if (schedule.isCritical) {
      return (AppColors.shiftCritical, AppColors.danger, 'Critical');
    }
    if (schedule.isCovered) {
      return (AppColors.shiftCovered, AppColors.success, 'Covered');
    }
    return (AppColors.shiftOpen, const Color(0xFF92400E), 'Open');
  }
}
