/// Global error handling utilities for the Krizot app.
library;

import 'package:flutter/material.dart';
import '../models/api_response.dart';

/// Centralised error handling for API and network errors.
class ErrorHandler {
  ErrorHandler._();

  /// Convert any exception to a user-friendly message string.
  static String getMessage(Object error) {
    if (error is ApiException) return _getApiExceptionMessage(error);
    if (error is NetworkException) return error.message;
    return 'An unexpected error occurred. Please try again.';
  }

  static String _getApiExceptionMessage(ApiException e) {
    if (e.isUnauthorized) return 'Your session has expired. Please log in again.';
    if (e.isForbidden) return 'You do not have permission to perform this action.';
    if (e.isNotFound) return 'The requested resource was not found.';
    if (e.isConflict) {
      return e.userMessage.isNotEmpty
          ? e.userMessage
          : 'A conflict was detected. Please check for overlapping schedules.';
    }
    if (e.isValidationError) {
      final details = e.error.details;
      if (details != null && details.isNotEmpty) {
        final messages = details
            .map((d) => d['message'] as String? ?? '')
            .where((m) => m.isNotEmpty)
            .join(', ');
        if (messages.isNotEmpty) return messages;
      }
      return e.userMessage;
    }
    if (e.isRateLimited) return 'Too many requests. Please wait a moment and try again.';
    return e.userMessage.isNotEmpty ? e.userMessage : 'An unexpected server error occurred.';
  }

  /// Show an error SnackBar using the nearest [ScaffoldMessenger].
  static void showSnackbar(
    BuildContext context,
    Object error, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final message = getMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: action,
      ),
    );
  }

  /// Show a success SnackBar.
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: const Color(0xFF00B087),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Show an error AlertDialog.
  static Future<void> showErrorDialog(
    BuildContext context,
    Object error, {
    String title = 'Error',
    VoidCallback? onRetry,
  }) async {
    final message = getMessage(error);
    await showAdaptiveDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () { Navigator.of(ctx).pop(); onRetry(); },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Returns true if the error is a schedule conflict (409).
  static bool isScheduleConflict(Object error) =>
      error is ApiException && error.isConflict;

  /// Returns true if the error is an authentication error (401).
  static bool isAuthError(Object error) =>
      error is ApiException && error.isUnauthorized;

  /// Returns true if the error is a network connectivity error.
  static bool isNetworkError(Object error) => error is NetworkException;
}
