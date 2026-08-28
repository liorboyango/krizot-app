import 'package:flutter/material.dart';

import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../entities/shift.dart';
import '../../../managers/shifts_manager.dart';
import '../../../managers/stations_manager.dart';
import '../../../managers/user_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/snackbar_util.dart';
import '../../../utils/time_util.dart';

/// Interface 2: the employee's personal dashboard — Focus View (current +
/// upcoming assignment), schedule list, and the Acknowledge action.
class EmployeeHomeScreen extends StatefulWidget {
  static const ROUTE_PATH = '/home';
  static const ROUTE_NAME = 'home';

  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final shiftsManager = locator<ShiftsManager>();
  final userManager = locator<UserManager>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: StreamBuilder<AppUser?>(
          initialData: userManager.user,
          stream: userManager.onUserChanged,
          builder: (context, snapshot) =>
              Text('Hi, ${snapshot.data?.displayName ?? ''}'),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => userManager.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<Shift>>(
        initialData: shiftsManager.myShifts,
        stream: shiftsManager.myShiftsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final shifts = snapshot.data!;
          final current = shiftsManager.currentShift;
          final next = shiftsManager.nextShift;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (current != null)
                _FocusCard(
                  title: 'CURRENT ASSIGNMENT',
                  shift: current,
                  color: AppColors.success,
                ),
              if (next != null) ...[
                const SizedBox(height: 12),
                _FocusCard(
                  title: 'UPCOMING ASSIGNMENT',
                  shift: next,
                  color: AppColors.accent,
                ),
              ],
              if (current == null && next == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No upcoming assignments.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'My schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final shift in shifts) _ShiftListTile(shift: shift),
            ],
          );
        },
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  final String title;
  final Shift shift;
  final Color color;

  const _FocusCard({
    required this.title,
    required this.shift,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final station = locator<StationsManager>().stationById(shift.stationId);
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              station?.name ?? shift.stationId,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (station != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.place,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      station.location,
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text(
              '${TimeUtil.formatDayLabel(shift.start)}  ·  '
              '${TimeUtil.formatRange(shift.start, shift.end)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (!shift.acknowledged) ...[
              const SizedBox(height: 14),
              _AcknowledgeButton(shift: shift),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShiftListTile extends StatelessWidget {
  final Shift shift;

  const _ShiftListTile({required this.shift});

  @override
  Widget build(BuildContext context) {
    final station = locator<StationsManager>().stationById(shift.stationId);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          shift.acknowledged ? Icons.check_circle : Icons.pending_actions,
          color:
              shift.acknowledged ? AppColors.success : AppColors.warning,
        ),
        title: Text(station?.name ?? shift.stationId,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${TimeUtil.formatDayLabel(shift.start)}  ·  '
          '${TimeUtil.formatRange(shift.start, shift.end)}'
          '${station != null ? '\n${station.location}' : ''}',
        ),
        isThreeLine: station != null,
        trailing: shift.acknowledged ? null : _AcknowledgeButton(shift: shift),
      ),
    );
  }
}

class _AcknowledgeButton extends StatefulWidget {
  final Shift shift;

  const _AcknowledgeButton({required this.shift});

  @override
  State<_AcknowledgeButton> createState() => _AcknowledgeButtonState();
}

class _AcknowledgeButtonState extends State<_AcknowledgeButton> {
  bool isBusy = false;

  Future<void> onPressed() async {
    setState(() => isBusy = true);
    final success =
        await locator<ShiftsManager>().acknowledgeShift(widget.shift.id);
    if (!mounted) return;
    setState(() => isBusy = false);
    if (!success) {
      SnackBarUtil.showSnackBar(
          context, 'Failed to acknowledge — try again.', Variant.ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isBusy ? null : onPressed,
      style: FilledButton.styleFrom(backgroundColor: AppColors.success),
      icon: const Icon(Icons.check, size: 18),
      label: Text(isBusy ? '…' : 'Acknowledge'),
    );
  }
}
