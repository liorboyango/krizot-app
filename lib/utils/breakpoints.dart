/// Responsive breakpoints for the Krizot application.
///
/// Desktop-first design with graceful mobile degradation.
class Breakpoints {
  Breakpoints._();

  /// Mobile breakpoint: card-based layout, bottom navigation.
  static const double mobile = 600.0;

  /// Tablet breakpoint: condensed sidebar, mixed layout.
  static const double tablet = 900.0;

  /// Desktop breakpoint: full sidebar + data tables.
  static const double desktop = 1280.0;
}
