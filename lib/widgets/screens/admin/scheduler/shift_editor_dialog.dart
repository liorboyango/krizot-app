import 'package:flutter/material.dart';

import '../../../../app_config/l10n/gen/app_localizations.dart';
import '../../../../app_config/service_locator.dart';
import '../../../../entities/shift.dart';
import '../../../../entities/station.dart';
import '../../../../managers/shifts_manager.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/snackbar_util.dart';
import '../../../../utils/time_util.dart';

/// Create or edit a shift's time block. Shift length defaults to the
/// station's `defaultShiftMinutes` but is fully editable (DESIGN.md:
/// "default 2-hour blocks, fully editable").
class ShiftEditorDialog extends StatefulWidget {
  final Station station;
  final DateTime day;
  final Shift? shift;

  /// Pre-selected start time for a new shift (e.g. the tapped hour cell).
  final TimeOfDay? initialStart;

  const ShiftEditorDialog({
    super.key,
    required this.station,
    required this.day,
    this.shift,
    this.initialStart,
  });

  static Future<void> show(
    BuildContext context, {
    required Station station,
    required DateTime day,
    Shift? shift,
    TimeOfDay? initialStart,
  }) =>
      showDialog(
        context: context,
        routeSettings: const RouteSettings(name: 'shift_editor_dialog'),
        builder: (_) => ShiftEditorDialog(
            station: station, day: day, shift: shift, initialStart: initialStart),
      );

  @override
  State<ShiftEditorDialog> createState() => _ShiftEditorDialogState();
}

class _ShiftEditorDialogState extends State<ShiftEditorDialog> {
  late TimeOfDay start;
  late TimeOfDay end;
  bool isBusy = false;

  bool get isEditing => widget.shift != null;

  @override
  void initState() {
    super.initState();
    if (widget.shift != null) {
      start = TimeOfDay.fromDateTime(widget.shift!.start);
      end = TimeOfDay.fromDateTime(widget.shift!.end);
    } else {
      // Default: caller-provided start (tapped hour), else first active
      // window start for on-demand stations, 08:00 otherwise — plus the
      // station's default shift length.
      start = widget.initialStart ??
          (widget.station.isAroundTheClock ||
                  widget.station.activeWindows.isEmpty
              ? const TimeOfDay(hour: 8, minute: 0)
              : widget.station.activeWindows.first.startTime);
      final startMinutes = start.hour * 60 + start.minute;
      final endMinutes =
          (startMinutes + widget.station.defaultShiftMinutes) % (24 * 60);
      end = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
    }
  }

  DateTime _toDateTime(TimeOfDay time, {bool rollToNextDay = false}) {
    final base = DateTime(
      widget.day.year,
      widget.day.month,
      widget.day.day,
      time.hour,
      time.minute,
    );
    return rollToNextDay ? base.add(const Duration(days: 1)) : base;
  }

  Future<void> onSavePressed() async {
    final startAt = _toDateTime(start);
    // An end at/before the start means the shift crosses midnight.
    var endAt = _toDateTime(end);
    if (!endAt.isAfter(startAt)) {
      endAt = _toDateTime(end, rollToNextDay: true);
    }

    setState(() => isBusy = true);
    final shiftsManager = locator<ShiftsManager>();
    final bool success;
    if (isEditing) {
      success = await shiftsManager.updateShiftTimes(
          widget.shift!.id, startAt, endAt);
    } else {
      success = await shiftsManager.createShift(Shift(
            id: '',
            stationId: widget.station.id,
            start: startAt,
            end: endAt,
            dayKey: TimeUtil.dayKey(startAt),
          )) !=
          null;
    }
    if (!mounted) return;
    setState(() => isBusy = false);
    if (success) {
      Navigator.pop(context);
    } else {
      SnackBarUtil.showSnackBar(context,
          AppLocalizations.of(context)!.failedToSaveShift, Variant.ERROR);
    }
  }

  Future<void> pickTime({required bool isStart}) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? start : end,
      helpText: isStart ? l10n.shiftStart : l10n.shiftEnd,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        start = picked;
      } else {
        end = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(isEditing
          ? l10n.editShiftTitle(widget.station.name)
          : l10n.newShiftTitle(widget.station.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TimeUtil.formatDayLabel(widget.day),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => pickTime(isStart: true),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(l10n.startAt(start.format(context))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => pickTime(isStart: false),
                  icon: const Icon(Icons.schedule, size: 18),
                  label: Text(l10n.endAt(end.format(context))),
                ),
              ),
            ],
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
