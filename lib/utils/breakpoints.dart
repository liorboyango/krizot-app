/// Responsive breakpoints for Krizot UI.
/// Desktop-first design with graceful mobile degradation.
class Breakpoints {
  Breakpoints._();

  /// Mobile: card-based layout, bottom navigation
  static const double mobile = 600.0;

  /// Tablet: condensed sidebar (icons-only 64px)
  static const double tablet = 900.0;

  /// Desktop: full sidebar (220px) + data tables
  static const double desktop = 1280.0;
}
