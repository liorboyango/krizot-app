import 'package:flutter/material.dart';

import '../../../../app_config/service_locator.dart';
import '../../../../services/functions_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/time_util.dart';

/// Runs the AI Auto-Fill callable for one day and shows the outcome.
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
  bool isRunning = false;
  Map<String, dynamic>? result;
  bool failed = false;

  Future<void> onRunPressed() async {
    setState(() {
      isRunning = true;
      failed = false;
    });
    final response = await locator<FunctionsService>()
        .autoFillSchedule(TimeUtil.dayKey(widget.day));
    if (!mounted) return;
    setState(() {
      isRunning = false;
      result = response;
      failed = response == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unfilled = (result?['unfilled'] as List?) ?? const [];
    return AlertDialog(
      title: const Text('AI Auto-Fill'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fill all open shifts on '
              '${TimeUtil.formatDayLabel(widget.day)} using staff '
              'availability and certifications.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (isRunning)
              const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Planning schedule…'),
                ],
              ),
            if (failed)
              const Text(
                'Auto-fill failed — check that the Cloud Function is deployed '
                'and an LLM API key is configured.',
                style: TextStyle(color: AppColors.danger),
              ),
            if (result != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Filled ${result!['filled']} shift(s)'
                    '${unfilled.isEmpty ? '' : ', ${unfilled.length} left open'}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
          child: Text(result == null ? 'Cancel' : 'Close'),
        ),
        if (result == null)
          FilledButton.icon(
            onPressed: isRunning ? null : onRunPressed,
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Run Auto-Fill'),
          ),
      ],
    );
  }
}
