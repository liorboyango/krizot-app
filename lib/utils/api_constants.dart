/// API-related constants for the Krizot app.
library;

/// Base URL and endpoint path constants.
class ApiConstants {
  ApiConstants._();

  /// Default API base URL (development).
  /// Override at build time with --dart-define=KRIZOT_API_URL=...
  static const String defaultBaseUrl = 'http://localhost:3000/api';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String register = '/auth/register';

  // Station endpoints
  static const String stations = '/stations';
  static String stationById(String id) => '/stations/$id';

  // Schedule endpoints
  static const String schedules = '/schedules';
  static const String scheduleWeek = '/schedules/week';
  static const String scheduleWeekly = '/schedules/weekly';
  static const String scheduleAssign = '/schedules/assign';
  static String scheduleById(String id) => '/schedules/$id';
  static String scheduleUnassign(String id) => '/schedules/$id/unassign';

  // User endpoints
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // Health check
  static const String health = '/health';

  // Pagination defaults
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
}

/// HTTP status code constants.
class HttpStatus {
  HttpStatus._();

  static const int ok = 200;
  static const int created = 201;
  static const int noContent = 204;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int conflict = 409;
  static const int unprocessableEntity = 422;
  static const int tooManyRequests = 429;
  static const int internalServerError = 500;
}

/// Error code constants matching the backend.
class ApiErrorCodes {
  ApiErrorCodes._();

  static const String validationError = 'VALIDATION_ERROR';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String invalidToken = 'INVALID_TOKEN';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String conflict = 'CONFLICT';
  static const String scheduleConflict = 'SCHEDULE_CONFLICT';
  static const String rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
  static const String serverError = 'SERVER_ERROR';
}
