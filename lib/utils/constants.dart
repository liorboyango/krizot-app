/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// Base URL for the Krizot backend API
  /// Override with KRIZOT_API_URL environment variable in production
  static const String apiBaseUrl =
      String.fromEnvironment('KRIZOT_API_URL', defaultValue: 'http://localhost:3000/api');

  /// App name
  static const String appName = 'Krizot';

  /// App version
  static const String appVersion = '1.0.0';

  /// JWT token storage key
  static const String tokenKey = 'krizot_access_token';

  /// Refresh token storage key
  static const String refreshTokenKey = 'krizot_refresh_token';

  /// User data storage key
  static const String userKey = 'krizot_user';

  /// Default pagination limit
  static const int defaultPageLimit = 20;

  /// Schedule pagination limit
  static const int schedulePageLimit = 50;
}
