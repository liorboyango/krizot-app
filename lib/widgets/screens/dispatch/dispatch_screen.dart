import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../utils/app_colors.dart';
import 'event_types_screen.dart';

/// Interface 3: emergency dispatch. Trigger buttons and live ack tallies
/// land in Phase D.
class DispatchScreen extends StatelessWidget {
  static const ROUTE_PATH = '/dispatch';
  static const ROUTE_NAME = 'dispatch';

  const DispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                const Text(
                  'Emergency Dispatch',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => context.go(
                      '${DispatchScreen.ROUTE_PATH}/${EventTypesScreen.ROUTE_SUB_PATH}'),
                  icon: const Icon(Icons.tune, size: 18),
                  label: const Text('Event Types'),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Emergency triggering arrives in Phase D.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
