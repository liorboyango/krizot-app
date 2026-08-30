import 'package:flutter/material.dart';

import '../../../../app_config/l10n/gen/app_localizations.dart';
import '../../../../app_config/service_locator.dart';
import '../../../../entities/app_user.dart';
import '../../../../entities/certification.dart';
import '../../../../entities/training_session.dart';
import '../../../../managers/shifts_manager.dart';
import '../../../../managers/stations_manager.dart';
import '../../../../managers/training_manager.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/l10n_util.dart';
import '../../../../utils/snackbar_util.dart';
import '../../../../utils/time_util.dart';

/// Create or edit a training session: pick the target certification, the
/// session type (simulation / spectation / tutoring), times, trainee and
/// trainers. Priority defaults to the certification's level and stays
/// editable. Trainer selection is validated against the staffing rule of
/// the chosen type before saving.
class TrainingEditorDialog extends StatefulWidget {
  final DateTime day;
  final TrainingSession? session;
  final TimeOfDay? initialStart;

  const TrainingEditorDialog({
    super.key,
    required this.day,
    this.session,
    this.initialStart,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime day,
    TrainingSession? session,
    TimeOfDay? initialStart,
  }) =>
      showDialog(
        context: context,
        routeSettings: const RouteSettings(name: 'training_editor_dialog'),
        builder: (_) => TrainingEditorDialog(
            day: day, session: session, initialStart: initialStart),
      );

  @override
  State<TrainingEditorDialog> createState() => _TrainingEditorDialogState();
}

class _TrainingEditorDialogState extends State<TrainingEditorDialog> {
  final trainingManager = locator<TrainingManager>();
  final stationsManager = locator<StationsManager>();
  final shiftsManager = locator<ShiftsManager>();

  String? certificationId;
  TrainingType type = TrainingType.tutoring;
  late TimeOfDay start;
  late TimeOfDay end;
  int priority = 0;
  bool priorityOverridden = false;
  String? traineeId;
  late Set<String> trainerIds;
  bool isBusy = false;

  bool get isEditing => widget.session != null;

  Certification? get certification => certificationId == null
      ? null
      : stationsManager.certificationById(certificationId!);

  @override
  void initState() {
    super.initState();
    final session = widget.session;
    if (session != null) {
      certificationId = session.certificationId;
      type = session.type;
      start = TimeOfDay.fromDateTime(session.start);
      end = TimeOfDay.fromDateTime(session.end);
      priority = session.priority;
      priorityOverridden =
          priority != trainingManager.defaultPriorityFor(session.certificationId);
      traineeId = session.traineeId;
      trainerIds = {...session.trainerIds};
    } else {
      start = widget.initialStart ?? const TimeOfDay(hour: 8, minute: 0);
      final endMinutes = (start.hour * 60 + start.minute + 120) % (24 * 60);
      end = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
      trainerIds = {};
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

  (DateTime, DateTime) get _timeRange {
    final startAt = _toDateTime(start);
    var endAt = _toDateTime(end);
    if (!endAt.isAfter(startAt)) {
      endAt = _toDateTime(end, rollToNextDay: true);
    }
    return (startAt, endAt);
  }

  /// A throwaway session carrying the dialog's current times — lets the
  /// manager's conflict checks run before the session exists.
  TrainingSession get _probe {
    final (startAt, endAt) = _timeRange;
    return TrainingSession(
      id: widget.session?.id ?? '',
      certificationId: certificationId ?? '',
      type: type,
      start: startAt,
      end: endAt,
      dayKey: TimeUtil.dayKey(startAt),
    );
  }

  void onCertificationChanged(String? id) => setState(() {
        certificationId = id;
        if (!priorityOverridden && id != null) {
          priority = trainingManager.defaultPriorityFor(id);
        }
        // The trainer pool changes with the certification.
        final pool = _trainerPool().map((user) => user.id).toSet();
        trainerIds.removeWhere((uid) => !pool.contains(uid));
        if (traineeId != null &&
            id != null &&
            !trainingManager
                .uncertifiedCandidates(id)
                .any((u) => u.id == traineeId)) {
          traineeId = null;
        }
      });

  /// Users allowed as trainers for the current cert+type: holders of the
  /// target certification, or — for staffed simulations — holders of any
  /// certification in the staffing definition.
  List<AppUser> _trainerPool() {
    final cert = certification;
    if (cert == null) return const [];
    final wantedCertIds = trainingManager
        .requiredStaff(cert, type)
        .map((r) => r.certificationId)
        .toSet();
    return shiftsManager.employees
        .where((u) => u.certifications.any(wantedCertIds.contains))
        .toList();
  }

  String _staffingRule(AppLocalizations l10n) {
    final cert = certification;
    if (cert == null) return '';
    if (type == TrainingType.simulation && cert.simulationStaff.isNotEmpty) {
      final parts = cert.simulationStaff.map((r) =>
          '${r.count}× ${stationsManager.certificationById(r.certificationId)?.name ?? r.certificationId}');
      return l10n.simulationStaffingRule(parts.join(', '));
    }
    return l10n.oneTrainerRule;
  }

  Future<void> onSavePressed() async {
    final l10n = AppLocalizations.of(context)!;
    final cert = certification;
    if (cert == null) return;

    final trainers = shiftsManager.employees
        .where((u) => trainerIds.contains(u.id))
        .toList();
    if (!trainingManager.trainersSatisfy(cert, type, trainers)) {
      SnackBarUtil.showSnackBar(
          context, l10n.staffingUnsatisfied, Variant.ERROR);
      return;
    }

    final (startAt, endAt) = _timeRange;
    setState(() => isBusy = true);
    final bool success;
    if (isEditing) {
      success = await trainingManager.updateSession(widget.session!.id, {
        'certificationId': cert.id,
        'type': type.name,
        'traineeId': traineeId,
        'trainerIds': trainerIds.toList(),
        'start': startAt,
        'end': endAt,
        'dayKey': TimeUtil.dayKey(startAt),
        'priority': priority,
      });
    } else {
      success = await trainingManager.createSession(TrainingSession(
            id: '',
            certificationId: cert.id,
            type: type,
            traineeId: traineeId,
            trainerIds: trainerIds.toList(),
            start: startAt,
            end: endAt,
            dayKey: TimeUtil.dayKey(startAt),
            priority: priority,
          )) !=
          null;
    }
    if (!mounted) return;
    setState(() => isBusy = false);
    if (success) {
      Navigator.pop(context);
    } else {
      SnackBarUtil.showSnackBar(context, l10n.failedToSaveTraining, Variant.ERROR);
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

  String _participantSuffix(AppLocalizations l10n, AppUser user) {
    if (!trainingManager.isFreeForSession(user, _probe)) {
      return ' ${l10n.busyTag}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final certifications = stationsManager.certifications;
    final trainees = certificationId == null
        ? <AppUser>[]
        : trainingManager.uncertifiedCandidates(certificationId!);
    // Keep the currently-set trainee/trainers selectable even if they no
    // longer match the pool (e.g. the trainee got certified meanwhile).
    if (traineeId != null && !trainees.any((u) => u.id == traineeId)) {
      final current =
          shiftsManager.employees.where((u) => u.id == traineeId).firstOrNull;
      if (current != null) trainees.add(current);
    }
    final trainerPool = _trainerPool();
    for (final uid in trainerIds) {
      if (!trainerPool.any((u) => u.id == uid)) {
        final current =
            shiftsManager.employees.where((u) => u.id == uid).firstOrNull;
        if (current != null) trainerPool.add(current);
      }
    }
    final certKnown = certifications.any((c) => c.id == certificationId);
    return AlertDialog(
      title: Text(
          isEditing ? l10n.editTrainingSession : l10n.newTrainingSession),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                TimeUtil.formatDayLabel(widget.day),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: certKnown ? certificationId : null,
                decoration: InputDecoration(
                  labelText: l10n.certificationLabel,
                  isDense: true,
                ),
                items: [
                  for (final cert in certifications)
                    DropdownMenuItem(value: cert.id, child: Text(cert.name)),
                ],
                onChanged: isBusy ? null : onCertificationChanged,
              ),
              const SizedBox(height: 16),
              Text(l10n.trainingTypeLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<TrainingType>(
                segments: [
                  for (final value in TrainingType.values)
                    ButtonSegment(
                      value: value,
                      label: Text(L10nUtil.trainingTypeLabel(l10n, value)),
                    ),
                ],
                selected: {type},
                onSelectionChanged: (selection) =>
                    setState(() => type = selection.first),
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(l10n.priorityLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: priority <= 0
                        ? null
                        : () => setState(() {
                              priority--;
                              priorityOverridden = true;
                            }),
                  ),
                  Text('$priority',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => setState(() {
                      priority++;
                      priorityOverridden = true;
                    }),
                  ),
                ],
              ),
              if (certification != null)
                Text(
                  l10n.defaultFromCertLevel(certification!.level),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: traineeId,
                decoration: InputDecoration(
                  labelText: l10n.traineeLabel,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(l10n.noTraineeYet)),
                  for (final user in trainees)
                    DropdownMenuItem(
                      value: user.id,
                      child: Text(
                          '${user.displayName}${_participantSuffix(l10n, user)}'),
                    ),
                ],
                onChanged: certificationId == null || isBusy
                    ? null
                    : (value) => setState(() => traineeId = value),
              ),
              if (certificationId != null && trainees.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.noUncertifiedUsers,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 16),
              Text(l10n.trainersLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (certification != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _staffingRule(l10n),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final user in trainerPool)
                    FilterChip(
                      label: Text(
                          '${user.displayName}${_participantSuffix(l10n, user)}'),
                      selected: trainerIds.contains(user.id),
                      onSelected: (selected) => setState(() {
                        if (selected) {
                          if (type.isOneOnOne) trainerIds.clear();
                          trainerIds.add(user.id);
                        } else {
                          trainerIds.remove(user.id);
                        }
                      }),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: isBusy || certificationId == null ? null : onSavePressed,
          child: Text(
              isBusy ? l10n.saving : (isEditing ? l10n.save : l10n.create)),
        ),
      ],
    );
  }
}
