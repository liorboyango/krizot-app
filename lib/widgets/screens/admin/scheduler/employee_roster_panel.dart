import 'package:flutter/material.dart';

import '../../../../app_config/l10n/gen/app_localizations.dart';
import '../../../../app_config/service_locator.dart';
import '../../../../entities/app_user.dart';
import '../../../../managers/availability_manager.dart';
import '../../../../managers/org_filter_manager.dart';
import '../../../../managers/shifts_manager.dart';
import '../../../../managers/stations_manager.dart';
import '../../../../utils/app_colors.dart';
import '../../../../utils/l10n_util.dart';
import '../../../../utils/time_util.dart';
import 'user_schedule_dialog.dart';

/// Desktop drag-and-drop source: staff chips draggable onto shift cells.
/// Sick/unavailable staff are shown flagged and are not draggable.
/// Searchable; tapping a chip opens the user's weekly schedule.
class EmployeeRosterPanel extends StatefulWidget {
  const EmployeeRosterPanel({super.key});

  @override
  State<EmployeeRosterPanel> createState() => _EmployeeRosterPanelState();
}

class _EmployeeRosterPanelState extends State<EmployeeRosterPanel> {
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shiftsManager = locator<ShiftsManager>();
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              AppLocalizations.of(context)!.staffTitle,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context)!.dragToAssign,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchStaffHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (value) => setState(() => query = value),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<void>(
              stream: locator<OrgFilterManager>().changesStream,
              builder: (context, _) => StreamBuilder<List<AppUser>>(
                initialData: shiftsManager.employees,
                stream: shiftsManager.employeesStream,
                builder: (context, snapshot) {
                  final orgFilter = locator<OrgFilterManager>();
                  final users = (snapshot.data ?? const <AppUser>[]).where(
                    orgFilter.matchesUser,
                  );
                  final trimmed = query.trim().toLowerCase();
                  final visible = trimmed.isEmpty
                      ? users.toList()
                      : users
                            .where(
                              (u) =>
                                  u.displayName.toLowerCase().contains(
                                    trimmed,
                                  ) ||
                                  u.email.toLowerCase().contains(trimmed),
                            )
                            .toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    children: [
                      for (final user in visible) _RosterChip(user: user),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterChip extends StatelessWidget {
  final AppUser user;

  const _RosterChip({required this.user});

  @override
  Widget build(BuildContext context) {
    final chip = _chipContent(context, dragging: false);
    if (!user.isAvailable) return chip;
    return Draggable<AppUser>(
      data: user,
      feedback: Material(
        color: Colors.transparent,
        child: _chipContent(context, dragging: true),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: chip,
    );
  }

  Widget _chipContent(BuildContext context, {required bool dragging}) {
    final l10n = AppLocalizations.of(context)!;
    final certCount = user.certifications.length;
    final statusColor = switch (user.status) {
      UserStatus.available => AppColors.success,
      UserStatus.sick => AppColors.warning,
      UserStatus.unavailable => AppColors.danger,
    };
    final shiftsManager = locator<ShiftsManager>();
    final availabilityManager = locator<AvailabilityManager>();
    final selectedDay = TimeUtil.startOfDay(shiftsManager.selectedDate);
    // Off-site on the selected day: the user keeps a presence calendar but
    // has no window touching that day.
    final offSite =
        availabilityManager.windowsForUser(user.id).isNotEmpty &&
        availabilityManager.windowsForUserDay(user.id, selectedDay).isEmpty;
    final subtitle = [
      if (user.courseNumber != null) l10n.courseTag(user.courseNumber!),
      user.isAvailable
          ? l10n.certificationCount(certCount)
          : L10nUtil.statusLabel(l10n, user.status),
      if (offSite) l10n.offSiteTag,
    ].join(' · ');
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => UserScheduleDialog.show(context, user),
      child: Container(
        width: 206,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: dragging ? AppColors.tableRowHover : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          boxShadow: dragging
              ? [const BoxShadow(color: Colors.black26, blurRadius: 8)]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (offSite)
              const Padding(
                padding: EdgeInsetsDirectional.only(end: 4),
                child: Icon(
                  Icons.event_busy,
                  size: 16,
                  color: AppColors.warning,
                ),
              ),
            _CertBadges(user: user),
          ],
        ),
      ),
    );
  }
}

class _CertBadges extends StatelessWidget {
  final AppUser user;

  const _CertBadges({required this.user});

  @override
  Widget build(BuildContext context) {
    final stationsManager = locator<StationsManager>();
    final names = user.certifications
        .map((id) => stationsManager.certificationById(id)?.name ?? id)
        .join('\n');
    if (names.isEmpty) return const SizedBox.shrink();
    return Tooltip(
      message: names,
      child: const Icon(
        Icons.workspace_premium_outlined,
        size: 16,
        color: AppColors.accent,
      ),
    );
  }
}
