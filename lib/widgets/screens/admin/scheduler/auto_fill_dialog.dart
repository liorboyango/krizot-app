import 'package:flutter/material.dart';

import '../../../../app_config/l10n/gen/app_localizations.dart';
import '../../../../app_config/service_locator.dart';
import '../../../../services/functions_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/time_util.dart';

/// Runs the AI Auto-Fill callable for one day and shows the outcome —
/// the backend first creates every still-missing shift of the day, then
/// assigns staff. An optional free-text prompt is forwarded to the LLM as
/// manager guidance.
class AutoFillDialog extends StatefulWidget {
  final DateTime day;

  const AutoFillDialog({super.key, required this.day});

  static Future<void> show(BuildContext context, DateTime day) => showDialog(
        context: context,
        barrierDismissible: false,
        routeSettings: const RouteSettings(name: 'auto_fill_dialog'),
        builder: (_) => AutoFillDialog(day: day),
      );

  @override
  State<AutoFillDialog> createState() => _AutoFillDialogState();
}

class _AutoFillDialogState extends State<AutoFillDialog> {
  final promptController = TextEditingController();
  bool isRunning = false;
  Map<String, dynamic>? result;
  bool failed = false;

  @override
  void dispose() {
    promptController.dispose();
    super.dispose();
  }

  Future<void> onRunPressed() async {
    setState(() {
      isRunning = true;
      failed = false;
    });
    final instructions = promptController.text.trim();
    final response = await locator<FunctionsService>().autoFillSchedule(
      TimeUtil.dayKey(widget.day),
      instructions: instructions.isEmpty ? null : instructions,
    );
    if (!mounted) return;
    setState(() {
      isRunning = false;
      result = response;
      failed = response == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unfilled = (result?['unfilled'] as List?) ?? const [];
    final createdCount = (result?['created'] as num?)?.toInt() ?? 0;
    return AlertDialog(
      title: Text(l10n.aiAutoFillTitle),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.autoFillExplainer(TimeUtil.formatDayLabel(widget.day)),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (result == null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: promptController,
                enabled: !isRunning,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: l10n.aiInstructionsLabel,
                  hintText: l10n.aiInstructionsHint,
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (isRunning)
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.planningSchedule),
                ],
              ),
            if (failed)
              Text(
                l10n.autoFillFailed,
                style: const TextStyle(color: AppColors.danger),
              ),
            if (result != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        if (createdCount > 0)
                          l10n.createdShiftsNote(createdCount),
                        l10n.filledShifts(
                                (result!['filled'] as num).toInt()) +
                            (unfilled.isEmpty
                                ? ''
                                : l10n.leftOpen(unfilled.length)),
                      ].join(' · '),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if ((result!['notes'] as String? ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  result!['notes'] as String,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isRunning ? null : () => Navigator.pop(context),
          child: Text(result == null ? l10n.cancel : l10n.close),
        ),
        if (result == null)
          FilledButton.icon(
            onPressed: isRunning ? null : onRunPressed,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(l10n.runAutoFill),
          ),
      ],
    );
  }
}
