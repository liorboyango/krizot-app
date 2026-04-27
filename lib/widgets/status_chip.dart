import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Shift status types.
enum ShiftStatus { covered, open, critical }

/// A colored status chip for shift/station status display.
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

  /// Creates a chip from a [ShiftStatus] enum value.
  factory StatusChip.fromStatus(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.covered:
        return const StatusChip(
          label: 'Covered',
          backgroundColor: AppColors.shiftCovered,
          textColor: AppColors.shiftCoveredText,
        );
      case ShiftStatus.open:
        return const StatusChip(
          label: 'Open',
          backgroundColor: AppColors.shiftOpen,
          textColor: AppColors.shiftOpenText,
        );
      case ShiftStatus.critical:
        return const StatusChip(
          label: 'Critical',
          backgroundColor: AppColors.shiftCritical,
          textColor: AppColors.shiftCriticalText,
        );
    }
  }

  /// Creates a chip from a string status value.
  factory StatusChip.fromString(String status) {
    switch (status.toLowerCase()) {
      case 'covered':
        return StatusChip.fromStatus(ShiftStatus.covered);
      case 'critical':
        return StatusChip.fromStatus(ShiftStatus.critical);
      case 'active':
        return const StatusChip(
          label: 'Active',
          backgroundColor: AppColors.shiftCovered,
          textColor: AppColors.shiftCoveredText,
        );
      case 'closed':
        return const StatusChip(
          label: 'Closed',
          backgroundColor: Color(0xFFF0F0F0),
          textColor: AppColors.textSecondary,
        );
      default:
        return StatusChip.fromStatus(ShiftStatus.open);
    }
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
