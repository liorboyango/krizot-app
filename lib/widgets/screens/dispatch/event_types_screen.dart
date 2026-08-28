import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';

/// Pre-defined emergency scenarios (CRUD lands in Phase D).
class EventTypesScreen extends StatelessWidget {
  static const ROUTE_SUB_PATH = 'event-types';
  static const ROUTE_NAME = 'event-types';

  const EventTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Event type configuration arrives in Phase D.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
