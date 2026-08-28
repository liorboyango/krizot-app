import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_config/service_locator.dart';
import '../../../entities/shift.dart';
import '../../../entities/station.dart';
import '../../../managers/shifts_manager.dart';
import '../../../managers/stations_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/time_util.dart';

/// Interface 1: the weekly scheduling grid — stations as rows, the seven
/// days of the selected week as columns.
class SchedulerScreen extends StatefulWidget {
  static const ROUTE_PATH = '/scheduler';
  static const ROUTE_NAME = 'scheduler';

  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

class _SchedulerScreenState extends State<SchedulerScreen> {
  final shiftsManager = locator<ShiftsManager>();
  final stationsManager = locator<StationsManager>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: StreamBuilder<DateTime>(
              initialData: shiftsManager.selectedDate,
              stream: shiftsManager.selectedDateStream,
              builder: (context, snapshot) {
                final selected = snapshot.data ?? DateTime.now();
                final monday = TimeUtil.startOfWeek(selected);
                final sunday = monday.add(const Duration(days: 6));
                return Row(
                  children: [
                    const Text(
                      'Scheduler',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      tooltip: 'Previous week',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: shiftsManager.previousWeek,
                    ),
                    Text(
                      '${DateFormat('d MMM').format(monday)} – '
                      '${DateFormat('d MMM yyyy').format(sunday)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next week',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: shiftsManager.nextWeek,
                    ),
                    TextButton(
                      onPressed: () =>
                          shiftsManager.selectDate(DateTime.now()),
                      child: const Text('Today'),
                    ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Station>>(
              initialData: stationsManager.stations,
              stream: stationsManager.stationsStream,
              builder: (context, stationsSnapshot) {
                if (!stationsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stations = stationsSnapshot.data!
                    .where((s) => s.status == StationStatus.active)
                    .toList();
                if (stations.isEmpty) {
                  return const Center(
                    child: Text(
                      'No active stations — create one on the Stations screen.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return StreamBuilder<List<Shift>>(
                  initialData: shiftsManager.weekShifts,
                  stream: shiftsManager.weekShiftsStream,
                  builder: (context, shiftsSnapshot) {
                    return StreamBuilder<DateTime>(
                      initialData: shiftsManager.selectedDate,
                      stream: shiftsManager.selectedDateStream,
                      builder: (context, dateSnapshot) {
                        final days = TimeUtil.weekDays(
                            dateSnapshot.data ?? DateTime.now());
                        return _WeekGrid(
                          stations: stations,
                          days: days,
                          shifts: shiftsSnapshot.data ?? const [],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  final List<Station> stations;
  final List<DateTime> days;
  final List<Shift> shifts;

  const _WeekGrid({
    required this.stations,
    required this.days,
    required this.shifts,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Table(
              defaultColumnWidth: const FixedColumnWidth(150),
              columnWidths: const {0: FixedColumnWidth(170)},
              border: TableBorder.all(color: AppColors.border, width: 1),
              children: [
                TableRow(
                  decoration:
                      const BoxDecoration(color: AppColors.tableHeader),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text('Station',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    for (final day in days)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          TimeUtil.formatDayLabel(day),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: TimeUtil.isSameDay(day, DateTime.now())
                                ? AppColors.accent
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                for (final station in stations)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(station.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            Text(
                              station.isAroundTheClock
                                  ? '24/7'
                                  : station.activeWindows.join(', '),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (final day in days)
                        _DayCell(station: station, day: day, shifts: shifts),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final Station station;
  final DateTime day;
  final List<Shift> shifts;

  const _DayCell({
    required this.station,
    required this.day,
    required this.shifts,
  });

  @override
  Widget build(BuildContext context) {
    final dayShifts = shifts
        .where((s) =>
            s.stationId == station.id && TimeUtil.isSameDay(s.start, day))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final shift in dayShifts) _ShiftChip(shift: shift),
          if (dayShifts.isEmpty)
            const SizedBox(
              height: 28,
              child: Center(
                child: Text('—',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  final Shift shift;

  const _ShiftChip({required this.shift});

  @override
  Widget build(BuildContext context) {
    final shiftsManager = locator<ShiftsManager>();
    final assignee = shift.userId == null
        ? null
        : shiftsManager.employees
            .where((u) => u.id == shift.userId)
            .firstOrNull;
    final background =
        shift.isAssigned ? AppColors.shiftCovered : AppColors.shiftOpen;
    final foreground =
        shift.isAssigned ? AppColors.shiftCoveredText : AppColors.shiftOpenText;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  TimeUtil.formatRange(shift.start, shift.end),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: foreground,
                  ),
                ),
                Text(
                  assignee?.displayName ??
                      (shift.isAssigned ? shift.userId! : 'Open'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: foreground),
                ),
              ],
            ),
          ),
          // Acknowledgement loop indicator: green check once the assignee
          // has confirmed the (latest) change to this shift.
          if (shift.isAssigned && shift.acknowledged)
            const Icon(Icons.check_circle,
                size: 14, color: AppColors.success),
        ],
      ),
    );
  }
}
