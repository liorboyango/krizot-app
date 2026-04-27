import 'package:flutter/material.dart';

/// Krizot application color system
/// Military-grade clarity meets modern admin UX
class AppColors {
  AppColors._();

  // Primary Brand
  static const primary = Color(0xFF1A2B4A); // Deep Navy
  static const primaryLight = Color(0xFF2C4270); // Navy Light
  static const accent = Color(0xFF0D7CFF); // Electric Blue
  static const accentHover = Color(0xFF0057CC); // Blue Hover

  // Status
  static const success = Color(0xFF00B087); // Teal Green
  static const warning = Color(0xFFFFB020); // Amber
  static const danger = Color(0xFFE53E3E); // Red
  static const info = Color(0xFF3182CE); // Info Blue

  // Neutrals
  static const background = Color(0xFFF4F6FA); // Cool Gray BG
  static const surface = Color(0xFFFFFFFF); // White Cards
  static const border = Color(0xFFE2E8F0); // Dividers
  static const textPrimary = Color(0xFF1A202C); // Almost Black
  static const textSecondary = Color(0xFF718096); // Muted Gray
  static const textMuted = Color(0xFFA0AEC0); // Light Gray

  // Shift Status Chips
  static const shiftCovered = Color(0xFFE6F9F5); // Green tint
  static const shiftOpen = Color(0xFFFFF3CD); // Yellow tint
  static const shiftCritical = Color(0xFFFFE5E5); // Red tint

  // Sidebar
  static const sidebarBg = primary;
  static const sidebarText = Color(0xFFFFFFFF);
  static const sidebarTextMuted = Color(0xB3FFFFFF); // white 70%
  static const sidebarSelected = accent;
  static const sidebarHover = primaryLight;
}
