import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

/// Error banner with retry button
class ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.shiftCritical,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 40,
              color: AppColors.danger,
            ),
            const SizedBox(height: 12),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...
              [
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}

/// Inline error message
class InlineError extends StatelessWidget {
  final String message;

  const InlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.shiftCritical,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 14,
            color: AppColors.danger,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
