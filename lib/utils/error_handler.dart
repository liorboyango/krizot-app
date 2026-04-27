/// Centralised error-handling utilities for Krizot.
///
/// Converts [DioException] and generic [Exception] objects into
/// human-readable messages suitable for display in the UI.
library;

import 'package:dio/dio.dart';

/// Severity level of an application error.
enum ErrorSeverity { info, warning, error }

/// A structured application error with a user-facing message.
class AppError {
  const AppError({
    required this.message,
    this.severity = ErrorSeverity.error,
    this.statusCode,
    this.raw,
  });

  /// Human-readable message to display in the UI.
  final String message;

  /// Severity level.
  final ErrorSeverity severity;

  /// HTTP status code (if applicable).
  final int? statusCode;

  /// Original exception for logging.
  final Object? raw;

  @override
  String toString() => 'AppError($statusCode): $message';
}

/// Converts any exception into an [AppError].
class ErrorHandler {
  ErrorHandler._();

  /// Parses [exception] and returns a structured [AppError].
  static AppError handle(Object exception) {
    if (exception is DioException) {
      return _handleDio(exception);
    }
    return AppError(
      message: 'An unexpected error occurred. Please try again.',
      raw: exception,
    );
  }

  static AppError _handleDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppError(
          message: 'Connection timed out. Check your network and try again.',
          severity: ErrorSeverity.warning,
        );

      case DioExceptionType.connectionError:
        return const AppError(
          message: 'Unable to reach the server. Check your connection.',
          severity: ErrorSeverity.warning,
        );

      case DioExceptionType.badResponse:
        return _handleHttpStatus(e);

      case DioExceptionType.cancel:
        return const AppError(
          message: 'Request was cancelled.',
          severity: ErrorSeverity.info,
        );

      default:
        return AppError(
          message: 'Network error: ${e.message ?? "Unknown"}',
          raw: e,
        );
    }
  }

  static AppError _handleHttpStatus(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    // Try to extract a server-provided message.
    String? serverMessage;
    if (data is Map<String, dynamic>) {
      serverMessage = data['message'] as String? ??
          data['error'] as String?;
    }

    switch (statusCode) {
      case 400:
        return AppError(
          message: serverMessage ?? 'Invalid request. Please check your input.',
          statusCode: 400,
          raw: e,
        );
      case 401:
        return AppError(
          message: serverMessage ?? 'Session expired. Please sign in again.',
          statusCode: 401,
          raw: e,
        );
      case 403:
        return AppError(
          message: serverMessage ?? 'You do not have permission to do that.',
          statusCode: 403,
          raw: e,
        );
      case 404:
        return AppError(
          message: serverMessage ?? 'The requested resource was not found.',
          statusCode: 404,
          raw: e,
        );
      case 409:
        return AppError(
          message: serverMessage ?? 'Conflict: this record already exists.',
          statusCode: 409,
          raw: e,
        );
      case 422:
        return AppError(
          message: serverMessage ?? 'Validation failed. Please check your input.',
          statusCode: 422,
          raw: e,
        );
      case 429:
        return const AppError(
          message: 'Too many requests. Please wait a moment and try again.',
          statusCode: 429,
          severity: ErrorSeverity.warning,
        );
      case 500:
      case 502:
      case 503:
        return AppError(
          message: serverMessage ?? 'Server error. Please try again later.',
          statusCode: statusCode,
          raw: e,
        );
      default:
        return AppError(
          message: serverMessage ?? 'Unexpected error (HTTP $statusCode).',
          statusCode: statusCode,
          raw: e,
        );
    }
  }
}
