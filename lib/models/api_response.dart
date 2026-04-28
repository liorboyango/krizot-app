/// Generic API response wrapper matching the backend envelope:
/// { success: bool, message?: string, data: any, meta?: { pagination } }
/// Error: { success: false, error: { code, message, details? } }
library;

/// Pagination metadata returned by list endpoints. Supports both the legacy
/// page-based shape (page/total/totalPages) and the newer cursor-based shape
/// (limit/nextCursor) — all classic fields are nullable.
class Pagination {
  const Pagination({
    required this.limit,
    this.page,
    this.total,
    this.totalPages,
    this.hasNextPage,
    this.hasPrevPage,
    this.perPage,
    this.nextCursor,
  });

  final int limit;
  final int? page;
  final int? total;
  final int? totalPages;
  final bool? hasNextPage;
  final bool? hasPrevPage;
  final int? perPage;
  final String? nextCursor;

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      limit: (json['limit'] as num?)?.toInt() ??
          (json['perPage'] as num?)?.toInt() ??
          20,
      page: (json['page'] as num?)?.toInt(),
      total: (json['total'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      hasNextPage: json['hasNextPage'] as bool?,
      hasPrevPage: json['hasPrevPage'] as bool?,
      perPage: (json['perPage'] as num?)?.toInt(),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  @override
  String toString() =>
      'Pagination(page: $page, limit: $limit, total: $total, totalPages: $totalPages, nextCursor: $nextCursor)';
}

/// Typed API response for list endpoints.
class ApiListResponse<T> {
  const ApiListResponse({
    required this.data,
    required this.pagination,
    this.message,
  });

  final List<T> data;
  final Pagination pagination;
  final String? message;
}

/// Typed API response for single-item endpoints.
class ApiDataResponse<T> {
  const ApiDataResponse({
    required this.data,
    this.message,
  });

  final T data;
  final String? message;
}

/// Structured API error.
class ApiError {
  const ApiError({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final List<Map<String, dynamic>>? details;

  factory ApiError.fromJson(Map<String, dynamic> json) {
    final errorJson = json['error'] as Map<String, dynamic>?;
    if (errorJson != null) {
      return ApiError(
        code: (errorJson['code'] as String?) ?? 'UNKNOWN_ERROR',
        message: (errorJson['message'] as String?) ?? 'An unknown error occurred',
        details: errorJson['details'] != null
            ? (errorJson['details'] as List<dynamic>)
                .map((e) => e as Map<String, dynamic>)
                .toList()
            : null,
      );
    }
    return ApiError(
      code: 'UNKNOWN_ERROR',
      message: (json['message'] as String?) ?? 'An unknown error occurred',
    );
  }

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}

/// Exception thrown when an API call fails.
class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.error,
    this.originalError,
  });

  final int statusCode;
  final ApiError error;
  final Object? originalError;

  /// Whether this is an authentication error.
  bool get isUnauthorized => statusCode == 401;

  /// Whether this is a permission error.
  bool get isForbidden => statusCode == 403;

  /// Whether this is a not-found error.
  bool get isNotFound => statusCode == 404;

  /// Whether this is a conflict error (e.g. schedule conflict).
  bool get isConflict => statusCode == 409;

  /// Whether this is a validation error.
  bool get isValidationError =>
      statusCode == 400 && error.code == 'VALIDATION_ERROR';

  /// Whether this is a rate-limit error.
  bool get isRateLimited => statusCode == 429;

  /// User-friendly message.
  String get userMessage => error.message;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, error: $error)';
}

/// Exception thrown for network/connectivity errors.
class NetworkException implements Exception {
  const NetworkException({required this.message, this.originalError});

  final String message;
  final Object? originalError;

  @override
  String toString() => 'NetworkException(message: $message)';
}
