import 'package:flutter/material.dart';

/// Krizot application color palette.
///
/// Military-grade clarity meets modern admin UX.
/// High-contrast, information-dense color system.
class AppColors {
  AppColors._();

  // ── Primary Brand ──────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A2B4A); // Deep Navy
  static const Color primaryLight = Color(0xFF2C4270); // Navy Light
  static const Color accent = Color(0xFF0D7CFF); // Electric Blue
  static const Color accentHover = Color(0xFF0057CC); // Blue Hover

  // ── Status ─────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00B087); // Teal Green
  static const Color warning = Color(0xFFFFB020); // Amber
  static const Color danger = Color(0xFFE53E3E); // Red
  static const Color info = Color(0xFF3182CE); // Info Blue

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF4F6FA); // Cool Gray BG
  static const Color surface = Color(0xFFFFFFFF); // White Cards
  static const Color border = Color(0xFFE2E8F0); // Dividers
  static const Color textPrimary = Color(0xFF1A202C); // Almost Black
  static const Color textSecondary = Color(0xFF718096); // Muted Gray
  static const Color textMuted = Color(0xFFA0AEC0); // Light Gray

  // ── Shift Status Chips ─────────────────────────────────────────────────────
  static const Color shiftCovered = Color(0xFFE6F9F5); // Green tint
  static const Color shiftOpen = Color(0xFFFFF3CD); // Yellow tint
  static const Color shiftCritical = Color(0xFFFFE5E5); // Red tint

  // ── Sidebar ────────────────────────────────────────────────────────────────
  static const Color sidebarBg = primary;
  static const Color sidebarText = Color(0xFFFFFFFF);
  static const Color sidebarTextMuted = Color(0xB3FFFFFF); // white 70%
  static const Color sidebarSelected = accent;
  static const Color sidebarHover = primaryLight;

  // ── Table ──────────────────────────────────────────────────────────────────
  static const Color tableRowAlt = Color(0xFFF7F9FC); // alternating row
  static const Color tableRowHover = Color(0xFFEBF4FF); // blue-50 hover
  static const Color tableHeader = Color(0xFFF1F5F9); // header bg
}
