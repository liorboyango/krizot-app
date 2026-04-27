import 'package:flutter/material.dart';
import '../models/station.dart';
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
  factory StatusChip.fromStationStatus(StationStatus status) {
    switch (status) {
      case StationStatus.active:
        return StatusChip(
          label: 'Active',
          backgroundColor: AppColors.shiftCovered,
          textColor: AppColors.success,
        );
      case StationStatus.closed:
        return StatusChip(
          label: 'Closed',
          backgroundColor: AppColors.shiftCritical,
          textColor: AppColors.danger,
        );
    }
  }

  /// Create a chip for shift coverage status.
  factory StatusChip.covered() {
    return const StatusChip(
      label: 'Covered',
      backgroundColor: AppColors.shiftCovered,
      textColor: AppColors.success,
    );
  }

  factory StatusChip.open() {
    return const StatusChip(
      label: 'Open',
      backgroundColor: AppColors.shiftOpen,
      textColor: AppColors.warning,
    );
  }

  factory StatusChip.critical() {
    return const StatusChip(
      label: 'Critical',
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
