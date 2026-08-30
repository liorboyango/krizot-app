import 'package:flutter/material.dart';
import '../app_config/l10n/gen/app_localizations.dart';
import '../entities/station.dart';
import '../utils/app_colors.dart';

/// A colored status chip widget for displaying station or shift status.
///
/// Follows the Krizot design system with pill-shaped chips.
class StatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  /// Create a chip from a [StationStatus].
  factory StatusChip.fromStationStatus(
      BuildContext context, StationStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case StationStatus.active:
        return StatusChip(
          label: l10n.stationActive,
          backgroundColor: AppColors.shiftCovered,
          textColor: AppColors.success,
        );
      case StationStatus.closed:
        return StatusChip(
          label: l10n.stationClosed,
          backgroundColor: AppColors.shiftCritical,
          textColor: AppColors.danger,
        );
    }
  }

  /// Create a chip for shift coverage status.
  factory StatusChip.covered(BuildContext context) {
    return StatusChip(
      label: AppLocalizations.of(context)!.chipCovered,
      backgroundColor: AppColors.shiftCovered,
      textColor: AppColors.success,
    );
  }

  factory StatusChip.open(BuildContext context) {
    return StatusChip(
      label: AppLocalizations.of(context)!.chipOpen,
      backgroundColor: AppColors.shiftOpen,
      textColor: AppColors.warning,
    );
  }

  factory StatusChip.critical(BuildContext context) {
    return StatusChip(
      label: AppLocalizations.of(context)!.chipCritical,
      backgroundColor: AppColors.shiftCritical,
      textColor: AppColors.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
