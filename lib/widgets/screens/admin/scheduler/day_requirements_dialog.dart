import 'package:flutter/material.dart';

import '../../../../app_config/l10n/gen/app_localizations.dart';
import '../../../../app_config/service_locator.dart';
import '../../../../entities/cert_requirement.dart';
import '../../../../entities/day_requirement.dart';
import '../../../../managers/shifts_manager.dart';
import '../../../../managers/stations_manager.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/snackbar_util.dart';
import '../../../../utils/time_util.dart';

/// Define exactly how many holders of which certifications a day requires —
/// one row per certification with a count stepper.
class DayRequirementsDialog extends StatefulWidget {
  final DateTime day;

  const DayRequirementsDialog({super.key, required this.day});

  static Future<void> show(BuildContext context, DateTime day) => showDialog(
        context: context,
        routeSettings: const RouteSettings(name: 'day_requirements_dialog'),
        builder: (_) => DayRequirementsDialog(day: day),
      );

  @override
  State<DayRequirementsDialog> createState() => _DayRequirementsDialogState();
}

class _DayRequirementsDialogState extends State<DayRequirementsDialog> {
  final shiftsManager = locator<ShiftsManager>();
  final stationsManager = locator<StationsManager>();

  /// certId → required count; 0 rows are dropped on save.
  late final Map<String, int> counts = {
    for (final requirement
        in shiftsManager.requirementForDay(widget.day)?.requirements ??
            const <CertRequirement>[])
      requirement.certificationId: requirement.count,
  };
  bool isBusy = false;

  Future<void> onSavePressed() async {
    setState(() => isBusy = true);
    final success = await shiftsManager.setDayRequirement(DayRequirement(
      dayKey: TimeUtil.dayKey(widget.day),
      requirements: [
        for (final entry in counts.entries)
          if (entry.value > 0)
            CertRequirement(certificationId: entry.key, count: entry.value),
      ],
    ));
    if (!mounted) return;
    setState(() => isBusy = false);
    if (success) {
      Navigator.pop(context);
    } else {
      SnackBarUtil.showSnackBar(context,
          AppLocalizations.of(context)!.failedToSaveRequirements, Variant.ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final certifications = stationsManager.certifications;
    return AlertDialog(
      title: Text(
          l10n.dayRequirementsFor(TimeUtil.formatDayLabel(widget.day))),
      content: SizedBox(
        width: 420,
        child: certifications.isEmpty
            ? Text(
                l10n.noCertificationsInCatalog,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final cert in certifications)
                      Row(
                        children: [
                          Expanded(child: Text(cert.name)),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: (counts[cert.id] ?? 0) <= 0
                                ? null
                                : () => setState(() =>
                                    counts[cert.id] = counts[cert.id]! - 1),
                          ),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '${counts[cert.id] ?? 0}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() =>
                                counts[cert.id] = (counts[cert.id] ?? 0) + 1),
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
          onPressed: isBusy || certifications.isEmpty ? null : onSavePressed,
          child: Text(isBusy ? l10n.saving : l10n.save),
        ),
      ],
    );
  }
}
