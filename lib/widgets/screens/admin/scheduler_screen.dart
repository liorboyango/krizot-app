import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../entities/shift.dart';
import '../../../entities/station.dart';
import '../../../managers/shifts_manager.dart';
import '../../../managers/stations_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/breakpoints.dart';
import '../../../utils/l10n_util.dart';
import '../../../utils/snackbar_util.dart';
import '../../../utils/time_util.dart';
import 'scheduler/assign_sheet.dart';
import 'scheduler/auto_fill_dialog.dart';
import 'scheduler/employee_roster_panel.dart';
import 'scheduler/shift_editor_dialog.dart';

/// Interface 1: the weekly scheduling grid — stations as rows, the seven
/// days of the selected week as columns. Desktop gets a draggable staff
/// roster; everything also works tap-first for mobile browsers.
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
    final showRoster =
        MediaQuery.of(context).size.width >= Breakpoints.desktop;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: _Header(shiftsManager: shiftsManager),
                ),
                Expanded(
                  child: StreamBuilder<List<Station>>(
                    initialData: stationsManager.stations,
                    stream: stationsManager.stationsStream,
                    builder: (context, stationsSnapshot) {
                      if (!stationsSnapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final stations = stationsSnapshot.data!
                          .where((s) => s.status == StationStatus.active)
                          .toList();
                      if (stations.isEmpty) {
                        return Center(
                          child: Text(
                            AppLocalizations.of(context)!.noActiveStations,
                            style: const TextStyle(
                                color: AppColors.textSecondary),
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
                                shifts:
                                    shiftsSnapshot.data ?? const [],
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
          ),
          if (showRoster) const EmployeeRosterPanel(),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ShiftsManager shiftsManager;

  const _Header({required this.shiftsManager});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return StreamBuilder<DateTime>(
      initialData: shiftsManager.selectedDate,
      stream: shiftsManager.selectedDateStream,
      builder: (context, snapshot) {
        final selected = snapshot.data ?? DateTime.now();
        final monday = TimeUtil.startOfWeek(selected);
        final sunday = monday.add(const Duration(days: 6));
        return Row(
          children: [
            Text(
              l10n.schedulerTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 24),
            IconButton(
              tooltip: l10n.previousWeek,
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
              tooltip: l10n.nextWeek,
              icon: const Icon(Icons.chevron_right),
              onPressed: shiftsManager.nextWeek,
            ),
            TextButton(
              onPressed: () => shiftsManager.selectDate(DateTime.now()),
              child: Text(l10n.today),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () async {
                final day = await showDatePicker(
                  context: context,
                  initialDate: shiftsManager.selectedDate,
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  helpText: l10n.autoFillWhichDay,
                );
                if (day == null || !context.mounted) return;
                await AutoFillDialog.show(context, day);
              },
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: Text(l10n.autoFill),
            ),
          ],
        );
      },
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
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(AppLocalizations.of(context)!.stationColumn,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
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
                                  ? AppLocalizations.of(context)!
                                      .twentyFourSeven
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
          for (final shift in dayShifts)
            _ShiftChip(shift: shift, station: station, day: day),
          SizedBox(
            height: 24,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () =>
                  ShiftEditorDialog.show(context, station: station, day: day),
              child: const Center(
                child: Icon(Icons.add, size: 14, color: AppColors.textMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One shift block: tap for actions, drop target for roster drags, with
/// ack-checkmark and "needs healing" flag when the assignee is sick or
/// unavailable.
class _ShiftChip extends StatelessWidget {
  final Shift shift;
  final Station station;
  final DateTime day;

  const _ShiftChip({
    required this.shift,
    required this.station,
    required this.day,
  });

  @override
  Widget build(BuildContext context) {
    final shiftsManager = locator<ShiftsManager>();
    final assignee = shift.userId == null
        ? null
        : shiftsManager.employees
            .where((u) => u.id == shift.userId)
            .firstOrNull;
    final needsHealing = assignee != null && !assignee.isAvailable;

    return DragTarget<AppUser>(
      onWillAcceptWithDetails: (details) =>
          shiftsManager.isEligible(details.data, station, shift),
      onAcceptWithDetails: (details) async {
        final success = await shiftsManager.assignShift(
          shift.id,
          details.data.id,
          source:
              needsHealing ? ShiftSource.healing : ShiftSource.manual,
        );
        if (!success && context.mounted) {
          SnackBarUtil.showSnackBar(context,
              AppLocalizations.of(context)!.assignmentFailed, Variant.ERROR);
        }
      },
      builder: (context, candidates, rejected) {
        final Color background;
        final Color foreground;
        if (candidates.isNotEmpty) {
          background = AppColors.shiftCovered;
          foreground = AppColors.shiftCoveredText;
        } else if (rejected.isNotEmpty) {
          background = AppColors.shiftCritical;
          foreground = AppColors.shiftCriticalText;
        } else if (needsHealing) {
          background = AppColors.shiftCritical;
          foreground = AppColors.shiftCriticalText;
        } else if (shift.isAssigned) {
          background = AppColors.shiftCovered;
          foreground = AppColors.shiftCoveredText;
        } else {
          background = AppColors.shiftOpen;
          foreground = AppColors.shiftOpenText;
        }
        return InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () => _showActions(context, assignee, needsHealing),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(6),
              border: candidates.isNotEmpty
                  ? Border.all(color: AppColors.success, width: 2)
                  : null,
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
                            (shift.isAssigned
                                ? shift.userId!
                                : AppLocalizations.of(context)!
                                    .openShiftShort),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(fontSize: 11, color: foreground),
                      ),
                    ],
                  ),
                ),
                if (needsHealing)
                  const Icon(Icons.priority_high,
                      size: 14, color: AppColors.danger)
                // Acknowledgement loop: green check once the assignee has
                // confirmed the latest change.
                else if (shift.isAssigned && shift.acknowledged)
                  const Icon(Icons.check_circle,
                      size: 14, color: AppColors.success),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActions(
      BuildContext context, AppUser? assignee, bool needsHealing) {
    final shiftsManager = locator<ShiftsManager>();
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      routeSettings: const RouteSettings(name: 'shift_actions_sheet'),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '${station.name} · ${TimeUtil.formatDayLabel(day)} · '
                '${TimeUtil.formatRange(shift.start, shift.end)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(assignee == null
                  ? l10n.openShift
                  : '${l10n.assignedTo(assignee.displayName)}'
                      '${needsHealing ? ' (${L10nUtil.statusLabel(l10n, assignee.status)}!)' : ''}'
                      ' · ${shift.acknowledged ? l10n.acknowledgedCheck : l10n.notAcknowledgedYet}'),
            ),
            const Divider(height: 1),
            if (needsHealing)
              ListTile(
                leading:
                    const Icon(Icons.healing, color: AppColors.danger),
                title: Text(l10n.findReplacementAi),
                onTap: () {
                  Navigator.pop(sheetContext);
                  AssignSheet.show(context,
                      shift: shift, station: station, healing: true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.person_add_alt),
              title: Text(shift.isAssigned ? l10n.reassign : l10n.assign),
              onTap: () {
                Navigator.pop(sheetContext);
                AssignSheet.show(context, shift: shift, station: station);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(l10n.editTimes),
              onTap: () {
                Navigator.pop(sheetContext);
                ShiftEditorDialog.show(context,
                    station: station, day: day, shift: shift);
              },
            ),
            if (shift.isAssigned)
              ListTile(
                leading: const Icon(Icons.person_remove_outlined),
                title: Text(l10n.unassign),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await shiftsManager.unassignShift(shift.id);
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(l10n.deleteShift,
                  style: const TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(sheetContext);
                await shiftsManager.deleteShift(shift.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
