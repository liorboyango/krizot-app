import 'package:flutter/material.dart';

import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../managers/shifts_manager.dart';
import '../../../utils/app_colors.dart';

/// Staff management: certifications tagging, availability status and roles.
/// Phase A shows the roster read-only; editing lands in Phase B.
class UsersScreen extends StatelessWidget {
  static const ROUTE_PATH = '/users';
  static const ROUTE_NAME = 'users';

  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shiftsManager = locator<ShiftsManager>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'Staff',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              initialData: shiftsManager.employees,
              stream: shiftsManager.employeesStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!;
                if (users.isEmpty) {
                  return const Center(
                    child: Text('No staff yet — users appear here after '
                        'their first sign-in.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.photoUrl != null
                              ? NetworkImage(user.photoUrl!)
                              : null,
                          child: user.photoUrl == null
                              ? Text(user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(user.displayName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${user.email}  ·  ${user.role.name}  ·  '
                            '${user.status.name}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
