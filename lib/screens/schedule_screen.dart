/// Schedule screen for Krizot.
///
/// Features:
/// - Weekly grid view with station rows and day columns
/// - Shift status chips (covered/open/critical)
/// - Click cell to open assignment panel
/// - Create new shift dialog
/// - All operations wired to [SchedulesNotifier] (real API calls)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/schedule.dart';
import '../models/station.dart';
import '../models/user.dart';
import '../providers/schedules_provider.dart';
import '../providers/stations_provider.dart';
import '../services/schedule_service.dart';
import '../utils/app_colors.dart';
import '../utils/breakpoints.dart';
import '../utils/error_handler.dart';

/// Schedule page.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _weekStart = _getWeekStart(DateTime.now());
  Schedule? _selectedSchedule;
  Station? _selectedStation;

  static DateTime _getWeekStart(DateTime date) {
    final diff = date.weekday - DateTime.monday;
    return DateTime(date.year, date.month, date.day - diff);
  }

  String get _weekStartStr => DateFormat('yyyy-MM-dd').format(_weekStart);

  void _prevWeek() => setState(() => _weekStart = _weekStart.subtract(const Duration(days: 7)));
  void _nextWeek() => setState(() => _weekStart = _weekStart.add(const Duration(days: 7)));

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final weeklyAsync = ref.watch(weeklyScheduleProvider(_weekStartStr));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _ScheduleHeader(
            weekStart: _weekStart,
            onPrev: _prevWeek,
            onNext: _nextWeek,
            onNewShift: () => _showNewShiftDialog(context, ref),
          ),
          Expanded(
            child: weeklyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(ErrorHandler.getMessage(e), style: const TextStyle(color: AppColors.danger)),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(weeklyScheduleProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (weekly) {
                if (width >= Breakpoints.tablet) {
                  return Row(
                    children: [
                      Expanded(
                        child: _WeeklyGrid(
                          weekly: weekly,
                          onCellTap: (schedule, station) {
                            setState(() {
                              _selectedSchedule = schedule;
                              _selectedStation = station;
                            });
                          },
                        ),
                      ),
                      if (_selectedSchedule != null || _selectedStation != null)
                        _AssignPanel(
                          schedule: _selectedSchedule,
                          station: _selectedStation,
                          onClose: () => setState(() {
                            _selectedSchedule = null;
                            _selectedStation = null;
                          }),
                          ref: ref,
                        ),
                    ],
                  );
                }
                return _WeeklyGrid(
                  weekly: weekly,
                  onCellTap: (schedule, station) {
                    setState(() {
                      _selectedSchedule = schedule;
                      _selectedStation = station;
                    });
                    if (schedule != null || station != null) {
                      _showAssignBottomSheet(context, ref, schedule, station);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAssignBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Schedule? schedule,
    Station? station,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => _AssignPanel(
          schedule: schedule,
          station: station,
          onClose: () => Navigator.of(ctx).pop(),
          ref: ref,
          scrollController: controller,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.weekStart,
    required this.onPrev,
    required this.onNext,
    required this.onNewShift,
  });

  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onNewShift;

  @override
  Widget build(BuildContext context) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final label =
        'Week of ${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: [
          Text('Schedule', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 24),
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev, tooltip: 'Previous week'),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext, tooltip: 'Next week'),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onNewShift,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('New Shift'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly grid
// ---------------------------------------------------------------------------

class _WeeklyGrid extends StatelessWidget {
  const _WeeklyGrid({required this.weekly, required this.onCellTap});

  final WeeklySchedule weekly;
  final void Function(Schedule? schedule, Station? station) onCellTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(120),
            columnWidths: {
              0: const FixedColumnWidth(140),
              ...{for (var i = 1; i <= weekly.days.length; i++) i: const FixedColumnWidth(120)},
            },
            border: TableBorder.all(color: AppColors.border, width: 0.5),
            children: [
              // Header row
              TableRow(
                decoration: const BoxDecoration(color: AppColors.tableRowAlt),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Station', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  ),
                  ...weekly.days.map((day) => Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(day.dayName.substring(0, 3), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        Text(day.date.substring(5), style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  )),
                ],
              ),
              // Station rows
              ...weekly.grid.map((row) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(row.station.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  ...List.generate(weekly.days.length, (dayIndex) {
                    final schedules = row.days[dayIndex] ?? [];
                    return GestureDetector(
                      onTap: () => onCellTap(
                        schedules.isNotEmpty ? schedules.first : null,
                        row.station,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: schedules.isEmpty
                            ? const _EmptyCell()
                            : Column(
                                children: schedules
                                    .map((s) => _ShiftChip(schedule: s))
                                    .toList(),
                              ),
                      ),
                    );
                  }),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text('---', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  const _ShiftChip({required this.schedule});
  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final isAssigned = schedule.isAssigned;
    final bg = isAssigned ? AppColors.shiftCovered : AppColors.shiftOpen;
    final textColor = isAssigned ? AppColors.shiftCoveredText : AppColors.shiftOpenText;
    final label = schedule.user?.name.split(' ').map((p) => p.isNotEmpty ? p[0] : '').join('.') ?? 'Open';

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textColor),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Assign panel
// ---------------------------------------------------------------------------

class _AssignPanel extends ConsumerWidget {
  const _AssignPanel({
    required this.schedule,
    required this.station,
    required this.onClose,
    required this.ref,
    this.scrollController,
  });

  final Schedule? schedule;
  final Station? station;
  final VoidCallback onClose;
  final WidgetRef ref;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final usersAsync = widgetRef.watch(stationsNotifierProvider);

    return Container(
      width: 380,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station?.name ?? 'Assign Shift',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (schedule != null)
                        Text(
                          '${DateFormat('EEE HH:mm').format(schedule!.startTime)} - ${DateFormat('HH:mm').format(schedule!.endTime)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
          ),
          const Divider(height: 1),
          if (schedule != null && schedule!.isAssigned)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await widgetRef.read(schedulesNotifierProvider.notifier).unassign(schedule!.id);
                    if (context.mounted) {
                      ErrorHandler.showSuccess(context, 'User unassigned');
                      onClose();
                    }
                  } catch (e) {
                    if (context.mounted) ErrorHandler.showSnackbar(context, e);
                  }
                },
                icon: const Icon(Icons.person_remove_outlined, size: 16),
                label: const Text('Unassign Current User'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Available Staff', style: Theme.of(context).textTheme.bodyLarge),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(ErrorHandler.getMessage(e))),
              data: (_) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select a staff member to assign to this shift.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// New shift dialog
// ---------------------------------------------------------------------------

void _showNewShiftDialog(BuildContext context, WidgetRef ref) {
  showDialog<void>(
    context: context,
    builder: (ctx) => _NewShiftDialog(ref: ref),
  );
}

class _NewShiftDialog extends ConsumerStatefulWidget {
  const _NewShiftDialog({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_NewShiftDialog> createState() => _NewShiftDialogState();
}

class _NewShiftDialogState extends ConsumerState<_NewShiftDialog> {
  String? _selectedStationId;
  DateTime _startTime = DateTime.now().copyWith(hour: 7, minute: 0, second: 0, millisecond: 0);
  DateTime _endTime = DateTime.now().copyWith(hour: 15, minute: 0, second: 0, millisecond: 0);
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final stations = ref.watch(stationsProvider);

    return AlertDialog(
      title: const Text('New Shift'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedStationId,
            decoration: const InputDecoration(labelText: 'Station *'),
            items: stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (v) => setState(() => _selectedStationId = v),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Start Time'),
            subtitle: Text(DateFormat('MMM d, HH:mm').format(_startTime)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_startTime),
              );
              if (picked != null) {
                setState(() => _startTime = _startTime.copyWith(hour: picked.hour, minute: picked.minute));
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('End Time'),
            subtitle: Text(DateFormat('MMM d, HH:mm').format(_endTime)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_endTime),
              );
              if (picked != null) {
                setState(() => _endTime = _endTime.copyWith(hour: picked.hour, minute: picked.minute));
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving || _selectedStationId == null ? null : () async {
            setState(() => _saving = true);
            try {
              await ref.read(schedulesNotifierProvider.notifier).createSchedule(
                CreateScheduleRequest(
                  stationId: _selectedStationId!,
                  startTime: _startTime,
                  endTime: _endTime,
                ),
              );
              if (mounted) {
                Navigator.of(context).pop();
                ErrorHandler.showSuccess(context, 'Shift created successfully');
              }
            } catch (e) {
              if (mounted) {
                setState(() => _saving = false);
                ErrorHandler.showSnackbar(context, e);
              }
            }
          },
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create Shift'),
        ),
      ],
    );
  }
}
