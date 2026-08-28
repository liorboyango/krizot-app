import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

class SplashScreen extends StatelessWidget {
  static const ROUTE_PATH = '/splash';
  static const ROUTE_NAME = 'splash';

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Krizot',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 32),
            SizedBox(
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
