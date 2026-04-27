/// Responsive breakpoints for the Krizot app.
///
/// Usage:
/// ```dart
/// final width = MediaQuery.of(context).size.width;
/// if (width >= Breakpoints.desktop) return _DesktopLayout();
/// if (width >= Breakpoints.tablet)  return _TabletLayout();
/// return _MobileLayout();
/// ```
library;

/// Screen width breakpoints.
class Breakpoints {
  Breakpoints._();

  /// Mobile: card-based layout, bottom navigation bar.
  static const double mobile = 600.0;

  /// Tablet: condensed sidebar (icons only, 64px).
  static const double tablet = 900.0;

  /// Desktop: full sidebar (220px) + data tables.
  static const double desktop = 1280.0;
}
