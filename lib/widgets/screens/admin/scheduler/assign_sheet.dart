import 'package:flutter/material.dart';

import '../../../../app_config/service_locator.dart';
import '../../../../entities/shift.dart';
import '../../../../entities/station.dart';
import '../../../../managers/shifts_manager.dart';
import '../../../../services/functions_service.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/snackbar_util.dart';

/// Candidate picker for a shift. Lists only validator-eligible staff
/// (certified ∧ available ∧ conflict-free); the "Smart Healing" button asks
/// the backend's LLM to rank replacements with reasons.
class AssignSheet extends StatefulWidget {
  final Shift shift;
  final Station station;

  /// True when replacing a dropped-out assignee (enables AI suggestions
  /// and stamps the assignment source as healing).
  final bool healing;

  const AssignSheet({
    super.key,
    required this.shift,
    required this.station,
    this.healing = false,
  });

  static Future<void> show(
    BuildContext context, {
    required Shift shift,
    required Station station,
    bool healing = false,
  }) =>
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        routeSettings: const RouteSettings(name: 'assign_sheet'),
        builder: (_) =>
            AssignSheet(shift: shift, station: station, healing: healing),
      );

  @override
  State<AssignSheet> createState() => _AssignSheetState();
}

class _AssignSheetState extends State<AssignSheet> {
  final shiftsManager = locator<ShiftsManager>();
  bool isSuggesting = false;

  /// userId → LLM reason, ordered by rank (null until requested).
  List<({String userId, String displayName, String reason})>? suggestions;

  Future<void> onSuggestPressed() async {
    setState(() => isSuggesting = true);
    final result = await locator<FunctionsService>()
        .suggestReplacement(widget.shift.id);
    if (!mounted) return;
    setState(() {
      isSuggesting = false;
      if (result != null) {
        suggestions = [
          for (final candidate in (result['candidates'] as List? ?? const []))
            (
              userId: candidate['userId'] as String,
              displayName: candidate['displayName'] as String? ?? '',
              reason: candidate['reason'] as String? ?? '',
            ),
        ];
      }
    });
    if (suggestions == null) {
      SnackBarUtil.showSnackBar(
          context, 'Suggestion service unavailable.', Variant.ERROR);
    }
  }

  Future<void> onAssign(String userId) async {
    final success = await shiftsManager.assignShift(
      widget.shift.id,
      userId,
      source: widget.healing ? ShiftSource.healing : ShiftSource.manual,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
    } else {
      SnackBarUtil.showSnackBar(context, 'Assignment failed.', Variant.ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    final candidates =
        shiftsManager.eligibleCandidates(widget.station, widget.shift);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.healing
                        ? 'Find replacement — ${widget.station.name}'
                        : 'Assign — ${widget.station.name}',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: isSuggesting ? null : onSuggestPressed,
                  icon: isSuggesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(isSuggesting ? 'Thinking…' : 'AI suggest'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Only certified, available, conflict-free staff are listed.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            if (suggestions != null) ...[
              for (final suggestion in suggestions!)
                _CandidateTile(
                  title: suggestion.displayName,
                  subtitle: suggestion.reason,
                  highlighted: true,
                  onTap: () => onAssign(suggestion.userId),
                ),
              if (suggestions!.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('AI found no eligible replacement.'),
                ),
              const Divider(height: 24),
            ],
            if (candidates.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Nobody is eligible for this shift — check certifications, '
                  'availability and overlapping assignments.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final candidate in candidates)
                    _CandidateTile(
                      title: candidate.displayName,
                      subtitle: candidate.email,
                      onTap: () => onAssign(candidate.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool highlighted;
  final VoidCallback onTap;

  const _CandidateTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: highlighted ? AppColors.shiftCovered : null,
      child: ListTile(
        dense: true,
        leading: Icon(
          highlighted ? Icons.auto_awesome : Icons.person_outline,
          color: highlighted ? AppColors.success : AppColors.textSecondary,
          size: 20,
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
