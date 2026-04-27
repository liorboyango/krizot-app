/// Krizot design system colour palette.
///
/// All colours are defined as static constants for compile-time safety.
/// Usage: `color: AppColors.primary`
library;

import 'package:flutter/material.dart';

/// Central colour definitions for the Krizot app.
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Primary Brand
  // ---------------------------------------------------------------------------

  /// Deep Navy — primary brand colour, used for sidebar and headers.
  static const Color primary = Color(0xFF1A2B4A);

  /// Navy Light — used for hover states in the sidebar.
  static const Color primaryLight = Color(0xFF2C4270);

  /// Electric Blue — accent / CTA colour.
  static const Color accent = Color(0xFF0D7CFF);

  /// Blue Hover — darker accent for hover/pressed states.
  static const Color accentHover = Color(0xFF0057CC);

  // ---------------------------------------------------------------------------
  // Status
  // ---------------------------------------------------------------------------

  /// Teal Green — success / covered shift.
  static const Color success = Color(0xFF00B087);

  /// Amber — warning / open shift.
  static const Color warning = Color(0xFFFFB020);

  /// Red — danger / critical shift.
  static const Color danger = Color(0xFFE53E3E);

  /// Info Blue — informational elements.
  static const Color info = Color(0xFF3182CE);

  // ---------------------------------------------------------------------------
  // Neutrals
  // ---------------------------------------------------------------------------

  /// Cool Gray — page background.
  static const Color background = Color(0xFFF4F6FA);

  /// White — card / surface background.
  static const Color surface = Color(0xFFFFFFFF);

  /// Divider / border colour.
  static const Color border = Color(0xFFE2E8F0);

  /// Almost Black — primary text.
  static const Color textPrimary = Color(0xFF1A202C);

  /// Muted Gray — secondary text.
  static const Color textSecondary = Color(0xFF718096);

  /// Light Gray — placeholder / muted text.
  static const Color textMuted = Color(0xFFA0AEC0);

  // ---------------------------------------------------------------------------
  // Shift Status Chips
  // ---------------------------------------------------------------------------

  /// Green tint background for covered shifts.
  static const Color shiftCovered = Color(0xFFE6F9F5);

  /// Green text for covered shifts.
  static const Color shiftCoveredText = Color(0xFF00875A);

  /// Yellow tint background for open shifts.
  static const Color shiftOpen = Color(0xFFFFF3CD);

  /// Amber text for open shifts.
  static const Color shiftOpenText = Color(0xFF92600A);

  /// Red tint background for critical shifts.
  static const Color shiftCritical = Color(0xFFFFE5E5);

  /// Red text for critical shifts.
  static const Color shiftCriticalText = Color(0xFFB91C1C);

  // ---------------------------------------------------------------------------
  // Table
  // ---------------------------------------------------------------------------

  /// Alternating row background (even rows).
  static const Color tableRowAlt = Color(0xFFF8FAFC);

  /// Row hover background.
  static const Color tableRowHover = Color(0xFFEBF4FF);
}
