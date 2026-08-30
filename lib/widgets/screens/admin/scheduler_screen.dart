import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../entities/day_requirement.dart';
import '../../../entities/shift.dart';
import '../../../entities/station.dart';
import '../../../entities/training_session.dart';
import '../../../managers/shifts_manager.dart';
import '../../../managers/stations_manager.dart';
import '../../../managers/training_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/breakpoints.dart';
import '../../../utils/l10n_util.dart';
import '../../../utils/snackbar_util.dart';
import '../../../utils/time_util.dart';
import 'scheduler/assign_sheet.dart';
import 'scheduler/auto_fill_dialog.dart';
import 'scheduler/day_requirements_dialog.dart';
import 'scheduler/employee_roster_panel.dart';
import 'scheduler/shift_editor_dialog.dart';
import 'scheduler/training_editor_dialog.dart';
import 'scheduler/user_schedule_dialog.dart';

/// Interface 1: the scheduling grid. Default is the day view — stations as
/// rows, the 24 hours of the selected day as columns, with each station's
/// manning laid out along the timeline. A toggle switches to the weekly
/// grid (stations × days). Desktop gets a draggable staff roster;
/// everything also works tap-first for mobile browsers.
class SchedulerScreen extends StatefulWidget {
  static const ROUTE_PATH = '/scheduler';
  static const ROUTE_NAME = 'scheduler';

  const SchedulerScreen({super.key});

  @override
  State<SchedulerScreen> createState() => _SchedulerScreenState();
}

enum _SchedulerView { day, week }

class _SchedulerScreenState extends State<SchedulerScreen> {
  final shiftsManager = locator<ShiftsManager>();
  final stationsManager = locator<StationsManager>();
  final trainingManager = locator<TrainingManager>();

  _SchedulerView _view = _SchedulerView.day;

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
                  child: _Header(
                    shiftsManager: shiftsManager,
                    view: _view,
                    onViewChanged: (view) => setState(() => _view = view),
                  ),
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
                          return StreamBuilder<List<TrainingSession>>(
                            initialData: trainingManager.weekSessions,
                            stream: trainingManager.weekSessionsStream,
                            builder: (context, sessionsSnapshot) {
                              return StreamBuilder<DateTime>(
                                initialData: shiftsManager.selectedDate,
                                stream: shiftsManager.selectedDateStream,
                                builder: (context, dateSnapshot) {
                                  final selected =
                                      dateSnapshot.data ?? DateTime.now();
                                  final shifts =
                                      shiftsSnapshot.data ?? const <Shift>[];
                                  final sessions = sessionsSnapshot.data ??
                                      const <TrainingSession>[];
                                  if (_view == _SchedulerView.day) {
                                    final day = TimeUtil.startOfDay(selected);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _DayRequirementsBar(day: day),
                                        Expanded(
                                          child: _DayGrid(
                                            stations: stations,
                                            day: day,
                                            shifts: shifts,
                                            sessions: sessions,
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return _WeekGrid(
                                    stations: stations,
                                    days: TimeUtil.weekDays(selected),
                                    shifts: shifts,
                                    sessions: sessions,
                                  );
                                },
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
  final _SchedulerView view;
  final ValueChanged<_SchedulerView> onViewChanged;

  const _Header({
    required this.shiftsManager,
    required this.view,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDayView = view == _SchedulerView.day;
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
              tooltip: isDayView ? l10n.previousDay : l10n.previousWeek,
              icon: const Icon(Icons.chevron_left),
              onPressed: isDayView
                  ? shiftsManager.previousDay
                  : shiftsManager.previousWeek,
            ),
            Text(
              isDayView
                  ? DateFormat('EEE d MMM yyyy').format(selected)
                  : '${DateFormat('d MMM').format(monday)} – '
                      '${DateFormat('d MMM yyyy').format(sunday)}',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              tooltip: isDayView ? l10n.nextDay : l10n.nextWeek,
              icon: const Icon(Icons.chevron_right),
              onPressed:
                  isDayView ? shiftsManager.nextDay : shiftsManager.nextWeek,
            ),
            TextButton(
              onPressed: () => shiftsManager.selectDate(DateTime.now()),
              child: Text(l10n.today),
            ),
            const SizedBox(width: 12),
            SegmentedButton<_SchedulerView>(
              segments: [
                ButtonSegment(
                    value: _SchedulerView.day, label: Text(l10n.dayView)),
                ButtonSegment(
                    value: _SchedulerView.week, label: Text(l10n.weekView)),
              ],
              selected: {view},
              onSelectionChanged: (selection) =>
                  onViewChanged(selection.first),
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: l10n.findUserSchedule,
              icon: const Icon(Icons.person_search_outlined),
              onPressed: () => UserScheduleDialog.search(context),
            ),
            IconButton(
              tooltip: l10n.editRequirements,
              icon: const Icon(Icons.checklist_outlined),
              onPressed: () => DayRequirementsDialog.show(
                  context, TimeUtil.startOfDay(shiftsManager.selectedDate)),
            ),
            IconButton(
              tooltip: l10n.newTrainingSession,
              icon: const Icon(Icons.school_outlined),
              onPressed: () => TrainingEditorDialog.show(context,
                  day: TimeUtil.startOfDay(shiftsManager.selectedDate)),
            ),
            const SizedBox(width: 4),
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
  final List<TrainingSession> sessions;

  const _WeekGrid({
    required this.stations,
    required this.days,
    required this.shifts,
    required this.sessions,
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
                TableRow(
                  decoration:
                      const BoxDecoration(color: AppColors.training),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Icon(Icons.school_outlined,
                              size: 16, color: AppColors.trainingText),
                          const SizedBox(width: 6),
                          Text(
                            AppLocalizations.of(context)!.trainingRowTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.trainingText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    for (final day in days)
                      _TrainingDayCell(day: day, sessions: sessions),
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

/// Default view: one day as a timeline — columns are the 24 hours, rows are
/// the stations with their manning (shift chips) placed along the hours they
/// cover. Overlapping shifts stack into lanes within the station row.
class _DayGrid extends StatelessWidget {
  final List<Station> stations;
  final DateTime day;
  final List<Shift> shifts;
  final List<TrainingSession> sessions;

  static const double _hourWidth = 60;
  static const double _stationColWidth = 170;
  static const double _laneHeight = 50;
  static const double _timelineWidth = _hourWidth * 24;

  const _DayGrid({
    required this.stations,
    required this.day,
    required this.shifts,
    required this.sessions,
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
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _hourHeaderRow(context),
                  for (final station in stations)
                    _StationTimelineRow(
                      station: station,
                      day: day,
                      shifts: shifts,
                      hourWidth: _hourWidth,
                      stationColWidth: _stationColWidth,
                      laneHeight: _laneHeight,
                    ),
                  _TrainingTimelineRow(
                    day: day,
                    sessions: sessions,
                    hourWidth: _hourWidth,
                    stationColWidth: _stationColWidth,
                    laneHeight: _laneHeight,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hourHeaderRow(BuildContext context) {
    return Container(
      color: AppColors.tableHeader,
      child: Row(
        children: [
          SizedBox(
            width: _stationColWidth,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(AppLocalizations.of(context)!.stationColumn,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(
            width: _timelineWidth,
            child: Row(
              children: [
                for (var hour = 0; hour < 24; hour++)
                  Container(
                    width: _hourWidth,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 10),
                    decoration: const BoxDecoration(
                      border: BorderDirectional(
                        start:
                            BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Text(
                      '${hour.toString().padLeft(2, '0')}:00',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TimeUtil.isSameDay(day, DateTime.now()) &&
                                DateTime.now().hour == hour
                            ? AppColors.accent
                            : AppColors.textPrimary,
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

/// One station's row in the day grid: info cell + a 24-hour timeline with
/// the station's shifts positioned by start/end. Empty hour cells create a
/// shift at that hour; chips keep their tap-actions and roster drag-drop.
class _StationTimelineRow extends StatelessWidget {
  final Station station;
  final DateTime day;
  final List<Shift> shifts;
  final double hourWidth;
  final double stationColWidth;
  final double laneHeight;

  /// Keeps a one-lane row tall enough for the two-line station cell.
  static const double _minRowHeight = 60;

  const _StationTimelineRow({
    required this.station,
    required this.day,
    required this.shifts,
    required this.hourWidth,
    required this.stationColWidth,
    required this.laneHeight,
  });

  @override
  Widget build(BuildContext context) {
    final dayEnd = day.add(const Duration(days: 1));
    final dayShifts = shifts
        .where((s) =>
            s.stationId == station.id &&
            s.start.isBefore(dayEnd) &&
            s.end.isAfter(day))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final lanes = _assignLanes(dayShifts);
    final laneCount =
        lanes.isEmpty ? 1 : lanes.reduce((a, b) => a > b ? a : b) + 1;
    // Explicit height: the row lives inside a vertically-unbounded scroll
    // view, so a stretch Row without a bounded height cannot lay out.
    final contentHeight = laneCount * laneHeight + 4;
    final rowHeight = contentHeight < _minRowHeight ? _minRowHeight : contentHeight;
    final now = DateTime.now();

    return Container(
      height: rowHeight,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: stationColWidth,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(station.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    station.isAroundTheClock
                        ? AppLocalizations.of(context)!.twentyFourSeven
                        : station.activeWindows.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: hourWidth * 24,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      for (var hour = 0; hour < 24; hour++)
                        Container(
                          width: hourWidth,
                          decoration: const BoxDecoration(
                            border: BorderDirectional(
                              start: BorderSide(
                                  color: AppColors.border, width: 1),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => ShiftEditorDialog.show(
                              context,
                              station: station,
                              day: day,
                              initialStart: TimeOfDay(hour: hour, minute: 0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Active-window tint so on-demand stations show when they
                // actually need manning.
                if (!station.isAroundTheClock)
                  for (final window in station.activeWindows)
                    PositionedDirectional(
                      start: window.startMinutes * hourWidth / 60,
                      width: (window.endMinutes - window.startMinutes) *
                          hourWidth /
                          60,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(
                            color:
                                AppColors.accent.withValues(alpha: 0.06)),
                      ),
                    ),
                for (var i = 0; i < dayShifts.length; i++)
                  _positionedChip(dayShifts[i], lanes[i], dayEnd),
                if (TimeUtil.isSameDay(day, now))
                  PositionedDirectional(
                    start:
                        (now.hour * 60 + now.minute) * hourWidth / 60 - 1,
                    width: 2,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(color: AppColors.accent),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _positionedChip(Shift shift, int lane, DateTime dayEnd) {
    final startMinutes = shift.start.isBefore(day)
        ? 0
        : shift.start.difference(day).inMinutes;
    final endMinutes = shift.end.isAfter(dayEnd)
        ? 24 * 60
        : shift.end.difference(day).inMinutes;
    final width = (endMinutes - startMinutes) * hourWidth / 60;
    return PositionedDirectional(
      start: startMinutes * hourWidth / 60,
      // Keep very short shifts tappable/readable.
      width: width < 44 ? 44 : width,
      top: lane * laneHeight + 4,
      height: laneHeight - 4,
      child: _ShiftChip(shift: shift, station: station, day: day),
    );
  }

  /// Greedy interval packing: each shift takes the first lane whose last
  /// shift ended before it starts.
  static List<int> _assignLanes(List<Shift> sortedShifts) {
    final laneEnds = <DateTime>[];
    final lanes = <int>[];
    for (final shift in sortedShifts) {
      var lane = laneEnds.indexWhere((end) => !end.isAfter(shift.start));
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(shift.end);
      } else {
        laneEnds[lane] = shift.end;
      }
      lanes.add(lane);
    }
    return lanes;
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

/// Day-view coverage bar: one chip per required certification for the day
/// showing assigned-holders vs required count, plus the requirements editor.
class _DayRequirementsBar extends StatelessWidget {
  final DateTime day;

  const _DayRequirementsBar({required this.day});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shiftsManager = locator<ShiftsManager>();
    final stationsManager = locator<StationsManager>();
    return StreamBuilder<List<DayRequirement>>(
      initialData: shiftsManager.weekRequirements,
      stream: shiftsManager.weekRequirementsStream,
      builder: (context, snapshot) {
        final requirement = shiftsManager.requirementForDay(day);
        final requirements = requirement?.requirements ?? const [];
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Row(
            children: [
              const Icon(Icons.checklist_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: requirements.isEmpty
                    ? Text(
                        l10n.noDayRequirements,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      )
                    : Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final req in requirements)
                            _coverageChip(
                              stationsManager
                                      .certificationById(req.certificationId)
                                      ?.name ??
                                  req.certificationId,
                              shiftsManager.certCoverageForDay(
                                  req.certificationId, day),
                              req.count,
                            ),
                        ],
                      ),
              ),
              IconButton(
                tooltip: l10n.editRequirements,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.edit_outlined, size: 16),
                onPressed: () => DayRequirementsDialog.show(context, day),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _coverageChip(String name, int covered, int required) {
    final met = covered >= required;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: met ? AppColors.shiftCovered : AppColors.shiftCritical,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$name $covered/$required',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color:
              met ? AppColors.shiftCoveredText : AppColors.shiftCriticalText,
        ),
      ),
    );
  }
}

/// The training lane of the day grid: sessions of the day positioned along
/// the 24-hour timeline. Empty hour cells create a session at that hour.
class _TrainingTimelineRow extends StatelessWidget {
  final DateTime day;
  final List<TrainingSession> sessions;
  final double hourWidth;
  final double stationColWidth;
  final double laneHeight;

  static const double _minRowHeight = 60;

  const _TrainingTimelineRow({
    required this.day,
    required this.sessions,
    required this.hourWidth,
    required this.stationColWidth,
    required this.laneHeight,
  });

  @override
  Widget build(BuildContext context) {
    final dayEnd = day.add(const Duration(days: 1));
    final daySessions = sessions
        .where((s) => s.start.isBefore(dayEnd) && s.end.isAfter(day))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final lanes = _assignLanes(daySessions);
    final laneCount =
        lanes.isEmpty ? 1 : lanes.reduce((a, b) => a > b ? a : b) + 1;
    final contentHeight = laneCount * laneHeight + 4;
    final rowHeight =
        contentHeight < _minRowHeight ? _minRowHeight : contentHeight;

    return Container(
      height: rowHeight,
      decoration: const BoxDecoration(
        color: AppColors.training,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: stationColWidth,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined,
                      size: 16, color: AppColors.trainingText),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.trainingRowTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.trainingText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: hourWidth * 24,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      for (var hour = 0; hour < 24; hour++)
                        Container(
                          width: hourWidth,
                          decoration: const BoxDecoration(
                            border: BorderDirectional(
                              start: BorderSide(
                                  color: AppColors.border, width: 1),
                            ),
                          ),
                          child: InkWell(
                            onTap: () => TrainingEditorDialog.show(
                              context,
                              day: day,
                              initialStart: TimeOfDay(hour: hour, minute: 0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (var i = 0; i < daySessions.length; i++)
                  _positionedChip(daySessions[i], lanes[i], dayEnd),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _positionedChip(TrainingSession session, int lane, DateTime dayEnd) {
    final startMinutes = session.start.isBefore(day)
        ? 0
        : session.start.difference(day).inMinutes;
    final endMinutes = session.end.isAfter(dayEnd)
        ? 24 * 60
        : session.end.difference(day).inMinutes;
    final width = (endMinutes - startMinutes) * hourWidth / 60;
    return PositionedDirectional(
      start: startMinutes * hourWidth / 60,
      width: width < 44 ? 44 : width,
      top: lane * laneHeight + 4,
      height: laneHeight - 4,
      child: _TrainingChip(session: session),
    );
  }

  static List<int> _assignLanes(List<TrainingSession> sortedSessions) {
    final laneEnds = <DateTime>[];
    final lanes = <int>[];
    for (final session in sortedSessions) {
      var lane = laneEnds.indexWhere((end) => !end.isAfter(session.start));
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(session.end);
      } else {
        laneEnds[lane] = session.end;
      }
      lanes.add(lane);
    }
    return lanes;
  }
}

/// A week-grid cell listing the day's training sessions by priority.
class _TrainingDayCell extends StatelessWidget {
  final DateTime day;
  final List<TrainingSession> sessions;

  const _TrainingDayCell({required this.day, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final daySessions = sessions
        .where((s) => TimeUtil.isSameDay(s.start, day))
        .toList()
      ..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        return byPriority != 0 ? byPriority : a.start.compareTo(b.start);
      });
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final session in daySessions)
            _TrainingChip(session: session),
          SizedBox(
            height: 24,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => TrainingEditorDialog.show(context, day: day),
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

/// One training session block: certification, type, trainee and priority.
/// Tap for edit/delete actions.
class _TrainingChip extends StatelessWidget {
  final TrainingSession session;

  const _TrainingChip({required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stationsManager = locator<StationsManager>();
    final shiftsManager = locator<ShiftsManager>();
    final certName =
        stationsManager.certificationById(session.certificationId)?.name ??
            session.certificationId;
    final trainee = session.traineeId == null
        ? null
        : shiftsManager.employees
            .where((u) => u.id == session.traineeId)
            .firstOrNull;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => _showActions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.trainingText, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${TimeUtil.formatRange(session.start, session.end)} · '
                    '${L10nUtil.trainingTypeLabel(l10n, session.type)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.trainingText,
                    ),
                  ),
                  Text(
                    '$certName · '
                    '${trainee?.displayName ?? l10n.noTraineeYet}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.trainingText),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.training,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'P${session.priority}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.trainingText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trainingManager = locator<TrainingManager>();
    final stationsManager = locator<StationsManager>();
    final shiftsManager = locator<ShiftsManager>();
    final certName =
        stationsManager.certificationById(session.certificationId)?.name ??
            session.certificationId;
    final names = {
      for (final user in shiftsManager.employees) user.id: user.displayName,
    };
    final trainerNames = session.trainerIds
        .map((id) => names[id] ?? id)
        .join(', ');
    showModalBottomSheet(
      context: context,
      routeSettings: const RouteSettings(name: 'training_actions_sheet'),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '$certName · ${L10nUtil.trainingTypeLabel(l10n, session.type)} · '
                '${TimeUtil.formatDayLabel(session.start)} · '
                '${TimeUtil.formatRange(session.start, session.end)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${l10n.traineeLabel}: '
                '${session.traineeId == null ? l10n.noTraineeYet : names[session.traineeId] ?? session.traineeId}'
                ' · ${l10n.trainersLabel}: $trainerNames'
                ' · ${l10n.priorityLabel}: ${session.priority}',
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.editTrainingSession),
              onTap: () {
                Navigator.pop(sheetContext);
                TrainingEditorDialog.show(
                  context,
                  day: TimeUtil.startOfDay(session.start),
                  session: session,
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: Text(l10n.deleteTrainingSession,
                  style: const TextStyle(color: AppColors.danger)),
              onTap: () async {
                Navigator.pop(sheetContext);
                await trainingManager.deleteSession(session.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
