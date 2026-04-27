/// Application-wide constants for the Krizot app.
class AppConstants {
  AppConstants._();

  /// Default API base URL. Override via KRIZOT_API_URL environment variable.
  static const String apiBaseUrl =
      String.fromEnvironment('KRIZOT_API_URL', defaultValue: 'http://localhost:3000/api');

  /// JWT token storage key.
  static const String tokenKey = 'krizot_access_token';

  /// Refresh token storage key.
  static const String refreshTokenKey = 'krizot_refresh_token';

  /// User data storage key.
  static const String userKey = 'krizot_user';

  /// Default page size for paginated lists.
  static const int defaultPageSize = 20;

  /// Maximum station capacity.
  static const int maxCapacity = 20;

  /// Minimum station capacity.
  static const int minCapacity = 1;

  /// App name.
  static const String appName = 'Krizot';

  /// App tagline.
  static const String appTagline = 'Shift Operations Platform';
}
