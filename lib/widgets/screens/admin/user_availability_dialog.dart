import 'package:flutter/material.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../entities/availability_window.dart';
import '../../../managers/availability_manager.dart';
import '../../../managers/shifts_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/snackbar_util.dart';
import '../../../utils/time_util.dart';

/// One user's availability calendar, week by week: their presence windows
/// per day, with manager add/edit/delete. Opened from the calendar button on
/// a Staff list row.
class UserAvailabilityDialog extends StatefulWidget {
  final AppUser user;

  const UserAvailabilityDialog({super.key, required this.user});

  static Future<void> show(BuildContext context, AppUser user) => showDialog(
        context: context,
        routeSettings: const RouteSettings(name: 'user_availability_dialog'),
        builder: (_) => UserAvailabilityDialog(user: user),
      );

  @override
  State<UserAvailabilityDialog> createState() =>
      _UserAvailabilityDialogState();
}

class _UserAvailabilityDialogState extends State<UserAvailabilityDialog> {
  late DateTime weekStart =
      TimeUtil.startOfWeek(locator<ShiftsManager>().selectedDate);

  /// Live feed of the user's windows; loaded a couple of months back so the
  /// week navigation has data on both sides.
  late final Stream<List<AvailabilityWindow>> windowsStream =
      locator<AvailabilityManager>().userWindowsStream(
          widget.user.id, weekStart.subtract(const Duration(days: 56)));

  Future<DateTime?> _pickMoment({
    required String helpText,
    required DateTime initial,
  }) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      helpText: helpText,
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: helpText,
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Arrival + departure pickers; existing [window] means editing it.
  Future<void> _editWindow({AvailabilityWindow? window, DateTime? day}) async {
    final l10n = AppLocalizations.of(context)!;
    final base = window?.start ??
        DateTime((day ?? weekStart).year, (day ?? weekStart).month,
            (day ?? weekStart).day, 8);
    final start =
        await _pickMoment(helpText: l10n.arrivalLabel, initial: base);
    if (start == null || !mounted) return;
    final end = await _pickMoment(
      helpText: l10n.departureLabel,
      initial: window?.end ?? start.add(const Duration(hours: 9)),
    );
    if (end == null || !mounted) return;
    if (!end.isAfter(start)) {
      SnackBarUtil.showSnackBar(
          context, l10n.departureAfterArrival, Variant.WARNING);
      return;
    }
    final availabilityManager = locator<AvailabilityManager>();
    final success = window == null
        ? await availabilityManager.createWindowFor(
                widget.user.id, start, end) !=
            null
        : await availabilityManager.updateWindow(window.id, start, end);
    if (!success && mounted) {
      SnackBarUtil.showSnackBar(
          context, l10n.failedToSaveAvailability, Variant.ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.userAvailabilityTitle(widget.user.displayName)),
      content: SizedBox(
        width: 460,
        child: StreamBuilder<List<AvailabilityWindow>>(
          stream: windowsStream,
          builder: (context, snapshot) {
            final windows = snapshot.data ?? const <AvailabilityWindow>[];
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: l10n.previousWeek,
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => setState(() => weekStart =
                            weekStart.subtract(const Duration(days: 7))),
                      ),
                      Expanded(
                        child: Text(
                          l10n.weekOf(TimeUtil.formatDayLabel(weekStart)),
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.nextWeek,
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => setState(() => weekStart =
                            weekStart.add(const Duration(days: 7))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < 7; i++)
                    _dayRow(l10n, weekStart.add(Duration(days: i)), windows),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () => _editWindow(),
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.addAvailabilityWindow),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _dayRow(
    AppLocalizations l10n,
    DateTime day,
    List<AvailabilityWindow> windows,
  ) {
    final dayEnd = day.add(const Duration(days: 1));
    final dayWindows = windows.where((w) => w.overlaps(day, dayEnd)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final isToday = TimeUtil.isSameDay(day, DateTime.now());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              TimeUtil.formatDayLabel(day),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isToday ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: dayWindows.isEmpty
                ? InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => _editWindow(day: day),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Icon(Icons.add,
                          size: 14, color: AppColors.textMuted),
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final window in dayWindows)
                        Tooltip(
                          message:
                              '${TimeUtil.formatDayLabel(window.start)} '
                              '${TimeUtil.formatTime(window.start)} → '
                              '${TimeUtil.formatDayLabel(window.end)} '
                              '${TimeUtil.formatTime(window.end)}',
                          child: InputChip(
                            avatar: const Icon(Icons.event_available,
                                size: 16, color: AppColors.success),
                            label: Text(
                              _chipLabel(window, day, dayEnd),
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: () => _editWindow(window: window),
                            deleteButtonTooltipMessage:
                                l10n.deleteWindowAction,
                            onDeleted: () => locator<AvailabilityManager>()
                                .deleteWindow(window.id),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// The window's extent within [day]: full range when contained, arrows
  /// when it continues into neighboring days.
  static String _chipLabel(
      AvailabilityWindow window, DateTime day, DateTime dayEnd) {
    final startsToday = !window.start.isBefore(day);
    final endsToday = !window.end.isAfter(dayEnd);
    if (startsToday && endsToday) {
      return TimeUtil.formatRange(window.start, window.end);
    }
    if (startsToday) return '${TimeUtil.formatTime(window.start)} →';
    if (endsToday) return '→ ${TimeUtil.formatTime(window.end)}';
    return '→ →';
  }
}
