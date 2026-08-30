import 'package:flutter/material.dart';

import '../../app_config/l10n/gen/app_localizations.dart';
import '../../utils/app_colors.dart';

class SplashScreen extends StatelessWidget {
  static const ROUTE_PATH = '/splash';
  static const ROUTE_NAME = 'splash';

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.appName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
