import 'package:flutter/material.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../entities/availability_window.dart';
import '../../../entities/shift.dart';
import '../../../entities/training_session.dart';
import '../../../managers/org_filter_manager.dart';
import '../../../managers/shifts_manager.dart';
import '../../../managers/statistics_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/l10n_util.dart';
import '../../../utils/time_util.dart';
import '../../stat_card.dart';

/// Reporting dashboard (Interface 1): per-user station time for a browsable
/// week, training totals for a browsable month, and the availability report.
/// All figures respect the sidebar org filter; the week/month anchors live in
/// [StatisticsManager] so browsing here never moves the scheduler grid.
class StatisticsScreen extends StatefulWidget {
  static const ROUTE_PATH = '/statistics';
  static const ROUTE_NAME = 'statistics';

  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final orgFilter = locator<OrgFilterManager>();
  final statistics = locator<StatisticsManager>();
  final shiftsManager = locator<ShiftsManager>();

  /// '12.5' / '8' — hours with a decimal only when it carries information.
  static String formatHours(Duration duration) {
    final hours = duration.inMinutes / 60;
    return hours == hours.roundToDouble()
        ? hours.round().toString()
        : hours.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              l10n.statisticsTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<void>(
              stream: orgFilter.changesStream,
              builder: (context, _) => StreamBuilder<List<AppUser>>(
                initialData: shiftsManager.employees,
                stream: shiftsManager.employeesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final visible =
                      snapshot.data!.where(orgFilter.matchesUser).toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      _KpiRow(users: visible),
                      const SizedBox(height: 16),
                      _WeeklyStationSection(users: visible),
                      const SizedBox(height: 16),
                      _MonthlyTrainingSection(users: visible),
                      const SizedBox(height: 16),
                      _AvailabilitySection(users: visible),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Headline figures: the weekly ones follow the report week, the training
/// ones the report month.
class _KpiRow extends StatelessWidget {
  final List<AppUser> users;

  const _KpiRow({required this.users});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statistics = locator<StatisticsManager>();
    return StreamBuilder<List<Shift>>(
      initialData: statistics.weekShifts,
      stream: statistics.weekShiftsStream,
      builder: (context, shiftsSnapshot) =>
          StreamBuilder<List<TrainingSession>>(
        initialData: statistics.monthSessions,
        stream: statistics.monthSessionsStream,
        builder: (context, sessionsSnapshot) {
          final visibleIds = users.map((u) => u.id).toSet();
          final shifts = (shiftsSnapshot.data ?? const <Shift>[])
              .where((s) => s.userId != null && visibleIds.contains(s.userId))
              .toList();
          final sessions =
              sessionsSnapshot.data ?? const <TrainingSession>[];
          final stationTime = shifts.fold(
              Duration.zero, (Duration sum, s) => sum + s.duration);
          final trainingTime = sessions.fold(
              Duration.zero, (Duration sum, s) => sum + s.duration);
          final openSlots =
              sessions.where((s) => s.traineeId == null).length;
          final cards = [
            StatCard(
              label: l10n.statWeeklyStationHours,
              value:
                  _StatisticsScreenState.formatHours(stationTime),
              icon: Icons.schedule,
              accentColor: AppColors.accent,
              iconBgColor: AppColors.tableRowHover,
            ),
            StatCard(
              label: l10n.statActiveStaffWeek,
              value:
                  shifts.map((s) => s.userId).toSet().length.toString(),
              icon: Icons.people_outline,
              accentColor: AppColors.success,
              iconBgColor: AppColors.shiftCovered,
            ),
            StatCard(
              label: l10n.statTrainingHoursMonth,
              value:
                  _StatisticsScreenState.formatHours(trainingTime),
              icon: Icons.school_outlined,
              accentColor: AppColors.trainingText,
              iconBgColor: AppColors.training,
            ),
            StatCard(
              label: l10n.statOpenTrainingSlotsMonth,
              value: openSlots.toString(),
              icon: Icons.pending_actions_outlined,
              accentColor: AppColors.warning,
              iconBgColor: AppColors.shiftOpen,
            ),
          ];
          return LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 4
                  : constraints.maxWidth >= 500
                      ? 2
                      : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final card in cards)
                    SizedBox(width: width, child: card),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

/// Per-user station time of the report week, longest first.
class _WeeklyStationSection extends StatelessWidget {
  final List<AppUser> users;

  const _WeeklyStationSection({required this.users});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statistics = locator<StatisticsManager>();
    return StreamBuilder<DateTime>(
      initialData: statistics.weekStart,
      stream: statistics.weekStartStream,
      builder: (context, weekSnapshot) => _SectionCard(
        title: l10n.weeklyStationTimeTitle,
        periodLabel:
            l10n.weekOf(TimeUtil.formatDayLabel(weekSnapshot.data!)),
        previousTooltip: l10n.previousWeek,
        nextTooltip: l10n.nextWeek,
        onPrevious: statistics.previousWeek,
        onNext: statistics.nextWeek,
        child: StreamBuilder<List<Shift>>(
          initialData: statistics.weekShifts,
          stream: statistics.weekShiftsStream,
          builder: (context, snapshot) {
            final shifts = snapshot.data ?? const <Shift>[];
            final time = StatisticsManager.stationTimeByUser(shifts);
            final counts = StatisticsManager.shiftCountByUser(shifts);
            final rows = users
                .where((u) => (time[u.id] ?? Duration.zero) > Duration.zero)
                .toList()
              ..sort((a, b) => time[b.id]!.compareTo(time[a.id]!));
            if (rows.isEmpty) return const _EmptyPeriod();
            final max = time[rows.first.id]!;
            return Column(
              children: [
                for (final user in rows)
                  _BarRow(
                    label: user.displayName,
                    value: time[user.id]!,
                    max: max,
                    color: AppColors.accent,
                    valueText: l10n.hoursValue(
                        _StatisticsScreenState.formatHours(time[user.id]!)),
                    detailText: l10n.shiftsTally(counts[user.id] ?? 0),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Training totals of the report month plus per-participant time.
class _MonthlyTrainingSection extends StatelessWidget {
  final List<AppUser> users;

  const _MonthlyTrainingSection({required this.users});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statistics = locator<StatisticsManager>();
    return StreamBuilder<DateTime>(
      initialData: statistics.monthStart,
      stream: statistics.monthStartStream,
      builder: (context, monthSnapshot) => _SectionCard(
        title: l10n.monthlyTrainingTitle,
        periodLabel: TimeUtil.formatMonthLabel(monthSnapshot.data!),
        previousTooltip: l10n.previousMonth,
        nextTooltip: l10n.nextMonth,
        onPrevious: statistics.previousMonth,
        onNext: statistics.nextMonth,
        child: StreamBuilder<List<TrainingSession>>(
          initialData: statistics.monthSessions,
          stream: statistics.monthSessionsStream,
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? const <TrainingSession>[];
            if (sessions.isEmpty) return const _EmptyPeriod();
            final total = sessions.fold(
                Duration.zero, (Duration sum, s) => sum + s.duration);
            final filled =
                sessions.where((s) => s.traineeId != null).length;
            final time = StatisticsManager.trainingTimeByUser(sessions);
            final counts = StatisticsManager.sessionCountByUser(sessions);
            final rows = users
                .where((u) => (time[u.id] ?? Duration.zero) > Duration.zero)
                .toList()
              ..sort((a, b) => time[b.id]!.compareTo(time[a.id]!));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    _SummaryItem(text: l10n.sessionsTally(sessions.length)),
                    _SummaryItem(
                        text: l10n.traineesAssignedTally(
                            filled, sessions.length)),
                    _SummaryItem(
                        text: l10n.hoursValue(
                            _StatisticsScreenState.formatHours(total))),
                    for (final type in TrainingType.values)
                      if (sessions.any((s) => s.type == type))
                        _SummaryItem(
                          text: '${L10nUtil.trainingTypeLabel(l10n, type)}'
                              ' · '
                              '${sessions.where((s) => s.type == type).length}',
                        ),
                  ],
                ),
                if (rows.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 4),
                  for (final user in rows)
                    _BarRow(
                      label: user.displayName,
                      value: time[user.id]!,
                      max: time[rows.first.id]!,
                      color: AppColors.trainingText,
                      valueText: l10n.hoursValue(
                          _StatisticsScreenState.formatHours(time[user.id]!)),
                      detailText: l10n.sessionsTally(counts[user.id] ?? 0),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// On-site hours per user for the report week. Users without any presence
/// window are always-present by the legacy semantics and are listed last.
class _AvailabilitySection extends StatelessWidget {
  final List<AppUser> users;

  const _AvailabilitySection({required this.users});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statistics = locator<StatisticsManager>();
    return StreamBuilder<DateTime>(
      initialData: statistics.weekStart,
      stream: statistics.weekStartStream,
      builder: (context, weekSnapshot) {
        final weekStart = weekSnapshot.data!;
        return _SectionCard(
          title: l10n.availabilityReportTitle,
          periodLabel: l10n.weekOf(TimeUtil.formatDayLabel(weekStart)),
          previousTooltip: l10n.previousWeek,
          nextTooltip: l10n.nextWeek,
          onPrevious: statistics.previousWeek,
          onNext: statistics.nextWeek,
          child: StreamBuilder<List<AvailabilityWindow>>(
            initialData: statistics.weekWindows,
            stream: statistics.weekWindowsStream,
            builder: (context, snapshot) {
              final windows =
                  snapshot.data ?? const <AvailabilityWindow>[];
              final weekEnd = weekStart.add(const Duration(days: 7));
              final presence = StatisticsManager.presenceByUser(
                  windows, weekStart, weekEnd);
              final windowCounts = <String, int>{};
              for (final window in windows) {
                windowCounts[window.userId] =
                    (windowCounts[window.userId] ?? 0) + 1;
              }
              final withWindows = users
                  .where((u) => presence.containsKey(u.id))
                  .toList()
                ..sort((a, b) => presence[b.id]!.compareTo(presence[a.id]!));
              final alwaysPresent =
                  users.where((u) => !presence.containsKey(u.id)).toList();
              if (users.isEmpty) return const _EmptyPeriod();
              final max = withWindows.isEmpty
                  ? Duration.zero
                  : presence[withWindows.first.id]!;
              return Column(
                children: [
                  for (final user in withWindows)
                    _BarRow(
                      label: user.displayName,
                      value: presence[user.id]!,
                      max: max,
                      color: AppColors.success,
                      valueText: l10n.hoursValue(
                          _StatisticsScreenState.formatHours(
                              presence[user.id]!)),
                      detailText: l10n
                          .presenceWindowsTally(windowCounts[user.id] ?? 0),
                    ),
                  for (final user in alwaysPresent)
                    _BarRow(
                      label: user.displayName,
                      value: null,
                      max: max,
                      color: AppColors.success,
                      valueText: l10n.alwaysPresent,
                      detailText: L10nUtil.statusLabel(l10n, user.status),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// A white report card with a title, a period label and prev/next arrows.
class _SectionCard extends StatelessWidget {
  final String title;
  final String periodLabel;
  final String previousTooltip;
  final String nextTooltip;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.periodLabel,
    required this.previousTooltip,
    required this.nextTooltip,
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                tooltip: previousTooltip,
                icon: const Icon(Icons.chevron_left),
                visualDensity: VisualDensity.compact,
                onPressed: onPrevious,
              ),
              Text(
                periodLabel,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: nextTooltip,
                icon: const Icon(Icons.chevron_right),
                visualDensity: VisualDensity.compact,
                onPressed: onNext,
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// One report line: name, a thin magnitude bar (square at the baseline,
/// rounded data-end), and the exact value in text tokens beside it. A null
/// [value] renders no bar — the value text carries the state instead.
class _BarRow extends StatelessWidget {
  final String label;
  final Duration? value;
  final Duration max;
  final Color color;
  final String valueText;
  final String detailText;

  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.valueText,
    required this.detailText,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = value == null || max == Duration.zero
        ? 0.0
        : value!.inMinutes / max.inMinutes;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: value == null
                ? const SizedBox(height: 10)
                : ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 10,
                      color: color.withValues(alpha: 0.12),
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: fraction.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadiusDirectional
                                .horizontal(end: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 170,
            child: Row(
              children: [
                Text(
                  valueText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    detailText,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

class _SummaryItem extends StatelessWidget {
  final String text;

  const _SummaryItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
    );
  }
}

class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          l10n.noDataForPeriod,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
