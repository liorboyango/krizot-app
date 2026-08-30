import 'package:flutter/material.dart';

import '../../../../app_config/l10n/gen/app_localizations.dart';
import '../../../../app_config/service_locator.dart';
import '../../../../entities/app_user.dart';
import '../../../../managers/availability_manager.dart';
import '../../../../managers/shifts_manager.dart';
import '../../../../managers/stations_manager.dart';
import '../../../../managers/training_manager.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/l10n_util.dart';
import '../../../../utils/time_util.dart';

/// One user's schedule for the scheduler's selected week: presence windows,
/// station shifts, and training sessions (as trainer or trainee). Opened by
/// tapping a roster chip or via the staff search in the scheduler header.
class UserScheduleDialog extends StatelessWidget {
  final AppUser user;

  const UserScheduleDialog({super.key, required this.user});

  static Future<void> show(BuildContext context, AppUser user) => showDialog(
        context: context,
        routeSettings: const RouteSettings(name: 'user_schedule_dialog'),
        builder: (_) => UserScheduleDialog(user: user),
      );

  /// Search staff by name, then open the picked user's schedule.
  static Future<void> search(BuildContext context) async {
    final picked = await showDialog<AppUser>(
      context: context,
      routeSettings: const RouteSettings(name: 'user_search_dialog'),
      builder: (_) => const _UserSearchDialog(),
    );
    if (picked == null || !context.mounted) return;
    await show(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shiftsManager = locator<ShiftsManager>();
    final stationsManager = locator<StationsManager>();
    final trainingManager = locator<TrainingManager>();
    final availabilityManager = locator<AvailabilityManager>();

    final monday = TimeUtil.startOfWeek(shiftsManager.selectedDate);
    final shifts = shiftsManager.weekShifts
        .where((s) => s.userId == user.id)
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final sessions = trainingManager.weekSessions
        .where((s) => s.involves(user.id))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final windows = availabilityManager.windowsForUser(user.id)
      ..sort((a, b) => a.start.compareTo(b.start));

    final certNames = user.certifications
        .map((id) => stationsManager.certificationById(id)?.name ?? id)
        .join(', ');

    return AlertDialog(
      title: Text(l10n.userScheduleTitle(user.displayName)),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  l10n.weekOf(TimeUtil.formatDayLabel(monday)),
                  if (user.courseNumber != null)
                    l10n.courseTag(user.courseNumber!),
                  if (certNames.isNotEmpty) certNames,
                ].join('  ·  '),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _SectionTitle(title: l10n.availabilityLabel),
              if (windows.isEmpty)
                _EmptyLine(text: l10n.noAvailabilityThisWeek)
              else
                for (final window in windows)
                  _Line(
                    icon: Icons.event_available,
                    color: AppColors.success,
                    text: '${TimeUtil.formatDayLabel(window.start)} '
                        '${TimeUtil.formatTime(window.start)} → '
                        '${TimeUtil.formatDayLabel(window.end)} '
                        '${TimeUtil.formatTime(window.end)}',
                  ),
              const SizedBox(height: 12),
              _SectionTitle(title: l10n.shiftsSectionTitle),
              if (shifts.isEmpty)
                _EmptyLine(text: l10n.noShiftsThisWeek)
              else
                for (final shift in shifts)
                  _Line(
                    icon: Icons.location_on_outlined,
                    color: AppColors.accent,
                    text: '${TimeUtil.formatDayLabel(shift.start)}  ·  '
                        '${TimeUtil.formatRange(shift.start, shift.end)}  ·  '
                        '${stationsManager.stationById(shift.stationId)?.name ?? shift.stationId}',
                  ),
              const SizedBox(height: 12),
              _SectionTitle(title: l10n.trainingRowTitle),
              if (sessions.isEmpty)
                _EmptyLine(text: l10n.noTrainingThisWeek)
              else
                for (final session in sessions)
                  _Line(
                    icon: Icons.school_outlined,
                    color: AppColors.warning,
                    text: '${TimeUtil.formatDayLabel(session.start)}  ·  '
                        '${TimeUtil.formatRange(session.start, session.end)}  ·  '
                        '${stationsManager.certificationById(session.certificationId)?.name ?? session.certificationId}'
                        ' (${L10nUtil.trainingTypeLabel(l10n, session.type)})'
                        '  ·  ${session.traineeId == user.id ? l10n.traineeLabel : l10n.trainerLabel}',
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      );
}

class _Line extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Line({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

class _EmptyLine extends StatelessWidget {
  final String text;

  const _EmptyLine({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style:
              const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
}

/// Type-ahead staff search returning the picked [AppUser].
class _UserSearchDialog extends StatefulWidget {
  const _UserSearchDialog();

  @override
  State<_UserSearchDialog> createState() => _UserSearchDialogState();
}

class _UserSearchDialogState extends State<_UserSearchDialog> {
  final controller = TextEditingController();
  String query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final users = locator<ShiftsManager>().employees;
    final matches = query.trim().isEmpty
        ? users
        : users
            .where((u) =>
                u.displayName.toLowerCase().contains(query.toLowerCase()) ||
                u.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return AlertDialog(
      title: Text(l10n.findUserSchedule),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.searchStaffHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
              ),
              onChanged: (value) => setState(() => query = value),
              onSubmitted: (_) {
                if (matches.length == 1) Navigator.pop(context, matches.first);
              },
            ),
            const SizedBox(height: 8),
            Flexible(
              child: matches.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.noUsersMatch(query),
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final user in matches)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline, size: 20),
                            title: Text(user.displayName),
                            subtitle: user.courseNumber != null
                                ? Text(l10n.courseTag(user.courseNumber!))
                                : null,
                            onTap: () => Navigator.pop(context, user),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
