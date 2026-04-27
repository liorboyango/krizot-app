/// Responsive breakpoint constants for the Krizot application.
///
/// Usage:
/// ```dart
/// final width = MediaQuery.of(context).size.width;
/// if (width >= Breakpoints.desktop) return _DesktopLayout();
/// if (width >= Breakpoints.tablet)  return _TabletLayout();
/// return _MobileLayout();
/// ```
library;

/// Pixel-width thresholds that define the three layout tiers.
class Breakpoints {
  Breakpoints._();

  /// Mobile layout – card-based UI, bottom navigation bar.
  static const double mobile = 600.0;

  /// Tablet layout – condensed / icon-only sidebar.
  static const double tablet = 900.0;

  /// Desktop layout – full 220 px sidebar + data tables.
  static const double desktop = 1280.0;

  /// Returns `true` when [width] qualifies as a desktop viewport.
  static bool isDesktop(double width) => width >= desktop;

  /// Returns `true` when [width] qualifies as a tablet viewport.
  static bool isTablet(double width) => width >= tablet && width < desktop;

  /// Returns `true` when [width] qualifies as a mobile viewport.
  static bool isMobile(double width) => width < tablet;
}
