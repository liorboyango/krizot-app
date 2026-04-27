/// Krizot design-system colour palette.
///
/// All colours are defined as `static const` so they can be used in
/// `const` widget constructors without allocating new objects at runtime.
library;

import 'package:flutter/material.dart';

/// Central colour constants for the Krizot application.
///
/// Usage:
/// ```dart
/// Container(color: AppColors.primary)
/// ```
class AppColors {
  AppColors._(); // prevent instantiation

  // ---------------------------------------------------------------------------
  // Primary Brand
  // ---------------------------------------------------------------------------

  /// Deep Navy – primary brand colour used for the sidebar and key surfaces.
  static const Color primary = Color(0xFF1A2B4A);

  /// Navy Light – slightly lighter variant used for hover states on the sidebar.
  static const Color primaryLight = Color(0xFF2C4270);

  /// Electric Blue – accent / CTA colour.
  static const Color accent = Color(0xFF0D7CFF);

  /// Blue Hover – darker accent used on button hover.
  static const Color accentHover = Color(0xFF0057CC);

  // ---------------------------------------------------------------------------
  // Status Colours
  // ---------------------------------------------------------------------------

  /// Teal Green – success / covered shift.
  static const Color success = Color(0xFF00B087);

  /// Amber – warning / open shift.
  static const Color warning = Color(0xFFFFB020);

  /// Red – danger / critical shift.
  static const Color danger = Color(0xFFE53E3E);

  /// Info Blue – informational highlights.
  static const Color info = Color(0xFF3182CE);

  // ---------------------------------------------------------------------------
  // Neutrals
  // ---------------------------------------------------------------------------

  /// Cool Gray – main page background.
  static const Color background = Color(0xFFF4F6FA);

  /// White – card / surface background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Divider / border colour.
  static const Color border = Color(0xFFE2E8F0);

  /// Almost Black – primary text.
  static const Color textPrimary = Color(0xFF1A202C);

  /// Muted Gray – secondary / supporting text.
  static const Color textSecondary = Color(0xFF718096);

  /// Light Gray – placeholder / muted text.
  static const Color textMuted = Color(0xFFA0AEC0);

  // ---------------------------------------------------------------------------
  // Shift Status Chip Backgrounds
  // ---------------------------------------------------------------------------

  /// Green tint background for covered-shift chips.
  static const Color shiftCovered = Color(0xFFE6F9F5);

  /// Yellow tint background for open-shift chips.
  static const Color shiftOpen = Color(0xFFFFF3CD);

  /// Red tint background for critical-shift chips.
  static const Color shiftCritical = Color(0xFFFFE5E5);

  // ---------------------------------------------------------------------------
  // Convenience helpers
  // ---------------------------------------------------------------------------

  /// Returns the appropriate chip background colour for a given shift status.
  static Color chipBackground(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.covered:
        return shiftCovered;
      case ShiftStatus.open:
        return shiftOpen;
      case ShiftStatus.critical:
        return shiftCritical;
    }
  }

  /// Returns the appropriate chip text colour for a given shift status.
  static Color chipText(ShiftStatus status) {
    switch (status) {
      case ShiftStatus.covered:
        return success;
      case ShiftStatus.open:
        return warning;
      case ShiftStatus.critical:
        return danger;
    }
  }
}

/// Enumeration of possible shift assignment statuses.
enum ShiftStatus {
  /// Shift is fully staffed.
  covered,

  /// Shift has no assigned staff member.
  open,

  /// Shift is understaffed or has a conflict.
  critical,
}
