/// Application-wide constants for Krizot.
///
/// Centralises magic strings, durations, and numeric values so they can be
/// updated in one place without hunting through the codebase.
library;

/// General application constants.
class AppConstants {
  AppConstants._();

  // ---------------------------------------------------------------------------
  // App metadata
  // ---------------------------------------------------------------------------

  static const String appName = 'Krizot';
  static const String appTagline = 'Shift Operations Platform';
  static const String appVersion = '1.0.0';

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  /// Base URL for the REST API.
  /// Override via the `KRIZOT_API_URL` environment variable at build time:
  /// ```
  /// flutter run --dart-define=KRIZOT_API_URL=https://api.example.com/api
  /// ```
  static const String apiBaseUrl = String.fromEnvironment(
    'KRIZOT_API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  /// Default HTTP request timeout.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Auth / JWT
  // ---------------------------------------------------------------------------

  /// Secure-storage key for the access token.
  static const String tokenKey = 'krizot_access_token';

  /// Secure-storage key for the refresh token.
  static const String refreshTokenKey = 'krizot_refresh_token';

  /// Secure-storage key for the cached user JSON.
  static const String userKey = 'krizot_user';

  // ---------------------------------------------------------------------------
  // UI / Layout
  // ---------------------------------------------------------------------------

  /// Width of the expanded desktop sidebar.
  static const double sidebarWidth = 220.0;

  /// Width of the collapsed tablet sidebar (icons only).
  static const double sidebarCollapsedWidth = 64.0;

  /// Standard card border radius.
  static const double cardRadius = 12.0;

  /// Standard modal border radius.
  static const double modalRadius = 12.0;

  /// Standard page padding.
  static const double pagePadding = 24.0;

  /// Standard card padding.
  static const double cardPadding = 20.0;

  // ---------------------------------------------------------------------------
  // Animation durations
  // ---------------------------------------------------------------------------

  static const Duration fadeTransition = Duration(milliseconds: 200);
  static const Duration modalTransition = Duration(milliseconds: 250);
  static const Duration panelTransition = Duration(milliseconds: 300);
  static const Duration hoverTransition = Duration(milliseconds: 150);

  // ---------------------------------------------------------------------------
  // Pagination
  // ---------------------------------------------------------------------------

  static const int defaultPageSize = 20;

  // ---------------------------------------------------------------------------
  // Station constraints
  // ---------------------------------------------------------------------------

  static const int minCapacity = 1;
  static const int maxCapacity = 20;
}
