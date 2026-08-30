import 'package:flutter/material.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../entities/availability_window.dart';
import '../../../entities/emergency_event.dart';
import '../../../entities/shift.dart';
import '../../../entities/training_session.dart';
import '../../../managers/availability_manager.dart';
import '../../../managers/dispatch_manager.dart';
import '../../../managers/shifts_manager.dart';
import '../../../managers/stations_manager.dart';
import '../../../managers/training_manager.dart';
import '../../../managers/user_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/l10n_util.dart';
import '../../../utils/snackbar_util.dart';
import '../../../utils/time_util.dart';

/// Interface 2: the employee's personal dashboard — Focus View (current +
/// upcoming assignment), schedule list, and the Acknowledge action.
class EmployeeHomeScreen extends StatefulWidget {
  static const ROUTE_PATH = '/home';
  static const ROUTE_NAME = 'home';

  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final shiftsManager = locator<ShiftsManager>();
  final userManager = locator<UserManager>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: StreamBuilder<AppUser?>(
          initialData: userManager.user,
          stream: userManager.onUserChanged,
          builder: (context, snapshot) =>
              Text(l10n.hiUser(snapshot.data?.displayName ?? '')),
        ),
        actions: [
          IconButton(
            tooltip: l10n.signOut,
            icon: const Icon(Icons.logout),
            onPressed: () => userManager.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Shift>>(
        initialData: shiftsManager.myShifts,
        stream: shiftsManager.myShiftsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final shifts = snapshot.data!;
          final current = shiftsManager.currentShift;
          final next = shiftsManager.nextShift;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _EmergencyBanners(),
              if (current != null)
                _FocusCard(
                  title: l10n.currentAssignment,
                  shift: current,
                  color: AppColors.success,
                ),
              if (next != null) ...[
                const SizedBox(height: 12),
                _FocusCard(
                  title: l10n.upcomingAssignment,
                  shift: next,
                  color: AppColors.accent,
                ),
              ],
              if (current == null && next == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      l10n.noUpcomingAssignments,
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                l10n.mySchedule,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final shift in shifts) _ShiftListTile(shift: shift),
              const _MyTrainingSection(),
              const _MyAvailabilitySection(),
            ],
          );
        },
      ),
    );
  }
}

/// Red persistent banners for active emergencies alerting this user; each
/// disappears from "unacked" state once the responder acknowledges.
class _EmergencyBanners extends StatelessWidget {
  const _EmergencyBanners();

  @override
  Widget build(BuildContext context) {
    final dispatchManager = locator<DispatchManager>();
    final uid = locator<UserManager>().user?.id;
    if (uid == null) return const SizedBox.shrink();
    return StreamBuilder<List<EmergencyEvent>>(
      initialData: dispatchManager.myAlerts,
      stream: dispatchManager.myAlertsStream,
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? const <EmergencyEvent>[];
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (final event in alerts)
              _EmergencyBanner(event: event, uid: uid),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  final EmergencyEvent event;
  final String uid;

  const _EmergencyBanner({required this.event, required this.uid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dispatchManager = locator<DispatchManager>();
    return StreamBuilder<bool>(
      stream: dispatchManager.myAckStreamFor(event.id, uid),
      builder: (context, snapshot) {
        final acked = snapshot.data ?? false;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: AppColors.danger,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.emergencyBanner(event.eventTypeName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        acked ? l10n.ackStandBy : l10n.youAreNeeded,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!acked)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.danger,
                    ),
                    onPressed: () async {
                      final success = await dispatchManager
                          .acknowledgeEmergency(event.id, uid);
                      if (!success && context.mounted) {
                        SnackBarUtil.showSnackBar(context,
                            l10n.failedToAcknowledge, Variant.ERROR);
                      }
                    },
                    child: Text(l10n.acknowledgeAction),
                  )
                else
                  const Icon(Icons.check_circle, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String title;
  final Shift shift;
  final Color color;

  const _FocusCard({
    required this.title,
    required this.shift,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final station = locator<StationsManager>().stationById(shift.stationId);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              station?.name ?? shift.stationId,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${TimeUtil.formatDayLabel(shift.start)}  ·  '
              '${TimeUtil.formatRange(shift.start, shift.end)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (!shift.acknowledged) ...[
              const SizedBox(height: 14),
              _AcknowledgeButton(shift: shift),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShiftListTile extends StatelessWidget {
  final Shift shift;

  const _ShiftListTile({required this.shift});

  @override
  Widget build(BuildContext context) {
    final station = locator<StationsManager>().stationById(shift.stationId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          shift.acknowledged ? Icons.check_circle : Icons.pending_actions,
          color:
              shift.acknowledged ? AppColors.success : AppColors.warning,
        ),
        title: Text(station?.name ?? shift.stationId,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${TimeUtil.formatDayLabel(shift.start)}  ·  '
          '${TimeUtil.formatRange(shift.start, shift.end)}',
        ),
        trailing: shift.acknowledged ? null : _AcknowledgeButton(shift: shift),
      ),
    );
  }
}

class _AcknowledgeButton extends StatefulWidget {
  final Shift shift;

  const _AcknowledgeButton({required this.shift});

  @override
  State<_AcknowledgeButton> createState() => _AcknowledgeButtonState();
}

class _AcknowledgeButtonState extends State<_AcknowledgeButton> {
  bool isBusy = false;

  Future<void> onPressed() async {
    setState(() => isBusy = true);
    final success =
        await locator<ShiftsManager>().acknowledgeShift(widget.shift.id);
    if (!mounted) return;
    setState(() => isBusy = false);
    if (!success) {
      SnackBarUtil.showSnackBar(
          context,
          AppLocalizations.of(context)!.failedToAcknowledgeRetry,
          Variant.ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isBusy ? null : onPressed,
      style: FilledButton.styleFrom(backgroundColor: AppColors.success),
      icon: const Icon(Icons.check, size: 18),
      label: Text(isBusy ? '…' : AppLocalizations.of(context)!.acknowledge),
    );
  }
}

/// The user's upcoming training sessions (as trainee or trainer).
class _MyTrainingSection extends StatelessWidget {
  const _MyTrainingSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trainingManager = locator<TrainingManager>();
    final stationsManager = locator<StationsManager>();
    final uid = locator<UserManager>().user?.id;
    return StreamBuilder<List<TrainingSession>>(
      initialData: trainingManager.mySessions,
      stream: trainingManager.mySessionsStream,
      builder: (context, snapshot) {
        final sessions = snapshot.data ?? const <TrainingSession>[];
        if (sessions.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.trainingRowTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            for (final session in sessions)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.school_outlined,
                      color: AppColors.trainingText),
                  title: Text(
                    '${stationsManager.certificationById(session.certificationId)?.name ?? session.certificationId}'
                    ' · ${L10nUtil.trainingTypeLabel(l10n, session.type)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${TimeUtil.formatDayLabel(session.start)}  ·  '
                    '${TimeUtil.formatRange(session.start, session.end)}  ·  '
                    '${session.traineeId == uid ? l10n.traineeLabel : l10n.trainerLabel}',
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// The user's own availability calendar: presence windows (arrival →
/// departure, possibly spanning days) with add/edit/delete.
class _MyAvailabilitySection extends StatelessWidget {
  const _MyAvailabilitySection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final availabilityManager = locator<AvailabilityManager>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Text(
              l10n.myAvailabilityTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _AvailabilityEditorDialog.show(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addAvailabilityWindow),
            ),
          ],
        ),
        const SizedBox(height: 4),
        StreamBuilder<List<AvailabilityWindow>>(
          initialData: availabilityManager.myWindows,
          stream: availabilityManager.myWindowsStream,
          builder: (context, snapshot) {
            final windows = snapshot.data ?? const <AvailabilityWindow>[];
            if (windows.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.noAvailabilityYet,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              );
            }
            return Column(
              children: [
                for (final window in windows)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.event_available,
                          color: AppColors.success),
                      title: Text(
                        '${TimeUtil.formatDayLabel(window.start)} '
                        '${TimeUtil.formatTime(window.start)} → '
                        '${TimeUtil.formatDayLabel(window.end)} '
                        '${TimeUtil.formatTime(window.end)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: l10n.editWindowAction,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _AvailabilityEditorDialog.show(
                                context,
                                window: window),
                          ),
                          IconButton(
                            tooltip: l10n.deleteWindowAction,
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: AppColors.danger),
                            onPressed: () => locator<AvailabilityManager>()
                                .deleteWindow(window.id),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Pick arrival and departure (each a date + a time; the window may span
/// several days).
class _AvailabilityEditorDialog extends StatefulWidget {
  final AvailabilityWindow? window;

  const _AvailabilityEditorDialog({this.window});

  static Future<void> show(BuildContext context,
          {AvailabilityWindow? window}) =>
      showDialog(
        context: context,
        routeSettings:
            const RouteSettings(name: 'availability_editor_dialog'),
        builder: (_) => _AvailabilityEditorDialog(window: window),
      );

  @override
  State<_AvailabilityEditorDialog> createState() =>
      _AvailabilityEditorDialogState();
}

class _AvailabilityEditorDialogState
    extends State<_AvailabilityEditorDialog> {
  late DateTime start = widget.window?.start ??
      TimeUtil.startOfDay(DateTime.now()).add(const Duration(hours: 8));
  late DateTime end =
      widget.window?.end ?? start.add(const Duration(hours: 8));
  bool isBusy = false;

  bool get isEditing => widget.window != null;

  Future<void> _pick({required bool isStart}) async {
    final current = isStart ? start : end;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        start = picked;
      } else {
        end = picked;
      }
    });
  }

  Future<void> onSavePressed() async {
    final l10n = AppLocalizations.of(context)!;
    if (!end.isAfter(start)) {
      SnackBarUtil.showSnackBar(
          context, l10n.departureAfterArrival, Variant.ERROR);
      return;
    }
    setState(() => isBusy = true);
    final availabilityManager = locator<AvailabilityManager>();
    final bool success;
    if (isEditing) {
      success = await availabilityManager.updateWindow(
          widget.window!.id, start, end);
    } else {
      success = await availabilityManager.createMyWindow(start, end) != null;
    }
    if (!mounted) return;
    setState(() => isBusy = false);
    if (success) {
      Navigator.pop(context);
    } else {
      SnackBarUtil.showSnackBar(
          context, l10n.failedToSaveAvailability, Variant.ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(isEditing ? l10n.editWindowAction : l10n.addAvailabilityWindow),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _pick(isStart: true),
            icon: const Icon(Icons.login, size: 18),
            label: Text(
              '${l10n.arrivalLabel}: ${TimeUtil.formatDayLabel(start)} '
              '${TimeUtil.formatTime(start)}',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pick(isStart: false),
            icon: const Icon(Icons.logout, size: 18),
            label: Text(
              '${l10n.departureLabel}: ${TimeUtil.formatDayLabel(end)} '
              '${TimeUtil.formatTime(end)}',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: isBusy ? null : onSavePressed,
          child: Text(
              isBusy ? l10n.saving : (isEditing ? l10n.save : l10n.create)),
        ),
      ],
    );
  }
}
