import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../entities/availability_window.dart';
import '../../../entities/cert_requirement.dart';
import '../../../entities/certification.dart';
import '../../../entities/shift.dart';
import '../../../managers/availability_manager.dart';
import '../../../managers/shifts_manager.dart';
import '../../../managers/stations_manager.dart';
import '../../../managers/user_manager.dart';
import '../../../services/functions_service.dart';
import '../../../services/user_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/l10n_util.dart';
import '../../../utils/snackbar_util.dart';
import '../../../utils/time_util.dart';
import '../../org_scope_picker.dart';
import 'scheduler/auto_fill_dialog.dart';
import 'scheduler/user_schedule_dialog.dart';
import 'user_availability_dialog.dart';

/// Staff management: certification tagging, availability status, org
/// placement (unit / department / role), roles (admin only), and the
/// certification catalog. Two views — the sectioned list and a week
/// calendar of everyone's presence and shifts with AI auto-fill.
class UsersScreen extends StatefulWidget {
  static const ROUTE_PATH = '/users';
  static const ROUTE_NAME = 'users';

  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

enum _StaffView { list, calendar }

class _UsersScreenState extends State<UsersScreen> {
  _StaffView view = _StaffView.list;

  /// Unit filter — null shows every site.
  Site? siteFilter;

  /// Department → still-included roles ("checkboxes of Department and
  /// deeper to Role"). Everything starts checked.
  final Map<Department, Set<JobRole>> selectedRoles = {
    for (final department in Department.values)
      department: {...JobRole.values},
  };

  bool _visible(AppUser user) {
    if (siteFilter != null && user.site != siteFilter) return false;
    // Users without a full placement stay visible under "Unassigned".
    if (user.department == null || user.jobRole == null) return true;
    return selectedRoles[user.department]!.contains(user.jobRole);
  }

  Future<void> onAutoFillPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final shiftsManager = locator<ShiftsManager>();
    final day = await showDatePicker(
      context: context,
      initialDate: shiftsManager.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: l10n.autoFillWhichDay,
    );
    if (day == null || !mounted) return;
    await AutoFillDialog.show(context, day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shiftsManager = locator<ShiftsManager>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              children: [
                Text(
                  l10n.staffTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                SegmentedButton<_StaffView>(
                  segments: [
                    ButtonSegment(
                        value: _StaffView.list,
                        label: Text(l10n.listViewLabel)),
                    ButtonSegment(
                        value: _StaffView.calendar,
                        label: Text(l10n.calendarViewLabel)),
                  ],
                  selected: {view},
                  onSelectionChanged: (selection) =>
                      setState(() => view = selection.first),
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const Spacer(),
                if (view == _StaffView.calendar) ...[
                  FilledButton.icon(
                    onPressed: onAutoFillPressed,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(l10n.autoFill),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: () => _CertificationCatalogDialog.show(context),
                  icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                  label: Text(l10n.certificationsTitle),
                ),
              ],
            ),
          ),
          _filterBar(l10n),
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
                  return Center(child: Text(l10n.noStaffYet));
                }
                final visible = users.where(_visible).toList();
                if (view == _StaffView.calendar) {
                  return _StaffCalendarView(users: _sectionOrder(visible));
                }
                return _buildList(l10n, visible);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Department → role order used by both the list sections and the
  /// calendar rows; unassigned users sink to the end.
  static List<AppUser> _sectionOrder(List<AppUser> users) => [...users]..sort(
      (a, b) {
        final byDept = (a.department?.index ?? Department.values.length)
            .compareTo(b.department?.index ?? Department.values.length);
        if (byDept != 0) return byDept;
        final byRole = (a.jobRole?.index ?? JobRole.values.length)
            .compareTo(b.jobRole?.index ?? JobRole.values.length);
        if (byRole != 0) return byRole;
        return a.displayName.compareTo(b.displayName);
      },
    );

  Widget _filterBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 4,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${l10n.unitLabel}:',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              SegmentedButton<Site?>(
                segments: [
                  ButtonSegment<Site?>(
                      value: null, label: Text(l10n.allUnits)),
                  for (final site in Site.values)
                    ButtonSegment<Site?>(
                        value: site, label: Text(site.wireName)),
                ],
                selected: {siteFilter},
                onSelectionChanged: (selection) =>
                    setState(() => siteFilter = selection.first),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          for (final department in Department.values)
            _departmentFilter(l10n, department),
        ],
      ),
    );
  }

  /// One department's checkbox with its role checkboxes nested after it.
  Widget _departmentFilter(AppLocalizations l10n, Department department) {
    final selected = selectedRoles[department]!;
    final allSelected = selected.length == JobRole.values.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          tristate: true,
          value: allSelected ? true : (selected.isEmpty ? false : null),
          visualDensity: VisualDensity.compact,
          onChanged: (_) => setState(() {
            if (allSelected) {
              selected.clear();
            } else {
              selected.addAll(JobRole.values);
            }
          }),
        ),
        Text(L10nUtil.departmentLabel(l10n, department),
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        for (final jobRole in JobRole.values) ...[
          Checkbox(
            value: selected.contains(jobRole),
            visualDensity: VisualDensity.compact,
            onChanged: (checked) => setState(() {
              if (checked == true) {
                selected.add(jobRole);
              } else {
                selected.remove(jobRole);
              }
            }),
          ),
          Text(L10nUtil.jobRoleLabel(l10n, jobRole),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ],
    );
  }

  /// The list view: sections per department, subsections per role, and an
  /// "Unassigned" tail for users without a full placement.
  Widget _buildList(AppLocalizations l10n, List<AppUser> visible) {
    if (visible.isEmpty) {
      return Center(child: Text(l10n.noStaffYet));
    }
    final children = <Widget>[];
    void addGroup(List<AppUser> group) => children.addAll([
          for (final user in group)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _UserTile(user: user),
            ),
        ]);

    for (final department in Department.values) {
      final inDepartment =
          visible.where((u) => u.department == department).toList();
      if (inDepartment.isEmpty) continue;
      children.add(_sectionHeader(
          L10nUtil.departmentLabel(l10n, department),
          major: true));
      for (final jobRole in JobRole.values) {
        final group = inDepartment
            .where((u) => u.jobRole == jobRole)
            .toList()
          ..sort((a, b) => a.displayName.compareTo(b.displayName));
        if (group.isEmpty) continue;
        children.add(_sectionHeader(L10nUtil.jobRoleLabel(l10n, jobRole)));
        addGroup(group);
      }
      final noRole = inDepartment.where((u) => u.jobRole == null).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      if (noRole.isNotEmpty) {
        children.add(_sectionHeader(l10n.noJobRoleSection));
        addGroup(noRole);
      }
    }
    final unassigned = visible.where((u) => u.department == null).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    if (unassigned.isNotEmpty) {
      children.add(_sectionHeader(l10n.unassignedSection, major: true));
      addGroup(unassigned);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: children,
    );
  }

  Widget _sectionHeader(String title, {bool major = false}) => Padding(
        padding: EdgeInsets.only(top: major ? 12 : 4, bottom: 6),
        child: Text(
          title,
          style: TextStyle(
            fontSize: major ? 16 : 13,
            fontWeight: FontWeight.w700,
            color: major ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      );
}

/// The calendar view: one row per user, one column per day of the selected
/// week, cells showing presence windows and assigned shifts. Cells open the
/// user's availability calendar; names open the full weekly schedule.
class _StaffCalendarView extends StatelessWidget {
  final List<AppUser> users;

  const _StaffCalendarView({required this.users});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final shiftsManager = locator<ShiftsManager>();
    final availabilityManager = locator<AvailabilityManager>();
    return StreamBuilder<DateTime>(
      initialData: shiftsManager.selectedDate,
      stream: shiftsManager.selectedDateStream,
      builder: (context, dateSnapshot) {
        final selected = dateSnapshot.data ?? DateTime.now();
        final days = TimeUtil.weekDays(selected);
        return StreamBuilder<List<Shift>>(
          initialData: shiftsManager.weekShifts,
          stream: shiftsManager.weekShiftsStream,
          builder: (context, shiftsSnapshot) {
            return StreamBuilder<List<AvailabilityWindow>>(
              initialData: availabilityManager.weekWindows,
              stream: availabilityManager.weekWindowsStream,
              builder: (context, windowsSnapshot) {
                final shifts = shiftsSnapshot.data ?? const <Shift>[];
                final windows =
                    windowsSnapshot.data ?? const <AvailabilityWindow>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: l10n.previousWeek,
                            icon: const Icon(Icons.chevron_left),
                            onPressed: shiftsManager.previousWeek,
                          ),
                          Text(
                            l10n.weekOf(
                                TimeUtil.formatDayLabel(days.first)),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.nextWeek,
                            icon: const Icon(Icons.chevron_right),
                            onPressed: shiftsManager.nextWeek,
                          ),
                          TextButton(
                            onPressed: () =>
                                shiftsManager.selectDate(DateTime.now()),
                            child: Text(l10n.today),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Table(
                                defaultColumnWidth:
                                    const FixedColumnWidth(150),
                                columnWidths: const {
                                  0: FixedColumnWidth(170)
                                },
                                border: TableBorder.all(
                                    color: AppColors.border, width: 1),
                                defaultVerticalAlignment:
                                    TableCellVerticalAlignment.top,
                                children: [
                                  TableRow(
                                    decoration: const BoxDecoration(
                                        color: AppColors.tableHeader),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Text(l10n.staffColumn,
                                            style: const TextStyle(
                                                fontWeight:
                                                    FontWeight.w700)),
                                      ),
                                      for (final day in days)
                                        Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            TimeUtil.formatDayLabel(day),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: TimeUtil.isSameDay(
                                                      day, DateTime.now())
                                                  ? AppColors.accent
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  for (final user in users)
                                    TableRow(
                                      children: [
                                        _nameCell(context, l10n, user),
                                        for (final day in days)
                                          _dayCell(context, user, day,
                                              windows, shifts),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _nameCell(BuildContext context, AppLocalizations l10n, AppUser user) {
    final placement = [
      if (user.site != null) user.site!.wireName,
      if (user.department != null)
        L10nUtil.departmentLabel(l10n, user.department!),
      if (user.jobRole != null) L10nUtil.jobRoleLabel(l10n, user.jobRole!),
    ].join(' · ');
    return InkWell(
      onTap: () => UserScheduleDialog.show(context, user),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            if (placement.isNotEmpty)
              Text(
                placement,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _dayCell(
    BuildContext context,
    AppUser user,
    DateTime day,
    List<AvailabilityWindow> windows,
    List<Shift> shifts,
  ) {
    final stationsManager = locator<StationsManager>();
    final dayEnd = day.add(const Duration(days: 1));
    final userWindows = windows
        .where((w) => w.userId == user.id && w.overlaps(day, dayEnd))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final userShifts = shifts
        .where((s) =>
            s.userId == user.id &&
            s.start.isBefore(dayEnd) &&
            s.end.isAfter(day))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    return InkWell(
      onTap: () => UserAvailabilityDialog.show(context, user),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final window in userWindows)
              _cellChip(
                text: _clampedRange(window.start, window.end, day, dayEnd),
                background: AppColors.shiftCovered,
                foreground: AppColors.shiftCoveredText,
                icon: Icons.event_available,
              ),
            for (final shift in userShifts)
              _cellChip(
                text: '${TimeUtil.formatRange(shift.start, shift.end)} '
                    '${stationsManager.stationById(shift.stationId)?.name ?? shift.stationId}',
                background: AppColors.accent.withValues(alpha: 0.12),
                foreground: AppColors.accent,
                icon: Icons.location_on_outlined,
              ),
            if (userWindows.isEmpty && userShifts.isEmpty)
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static String _clampedRange(
      DateTime start, DateTime end, DateTime day, DateTime dayEnd) {
    final startsToday = !start.isBefore(day);
    final endsToday = !end.isAfter(dayEnd);
    if (startsToday && endsToday) return TimeUtil.formatRange(start, end);
    if (startsToday) return '${TimeUtil.formatTime(start)} →';
    if (endsToday) return '→ ${TimeUtil.formatTime(end)}';
    return '→ →';
  }

  Widget _cellChip({
    required String text,
    required Color background,
    required Color foreground,
    required IconData icon,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      );
}

class _UserTile extends StatelessWidget {
  final AppUser user;

  const _UserTile({required this.user});

  static const _statusColors = {
    UserStatus.available: AppColors.success,
    UserStatus.sick: AppColors.warning,
    UserStatus.unavailable: AppColors.danger,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stationsManager = locator<StationsManager>();
    final certNames = user.certifications
        .map((id) => stationsManager.certificationById(id)?.name ?? id)
        .toList();
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage:
                  user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? Text(user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?')
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _statusColors[user.status],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(user.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                L10nUtil.roleLabel(l10n, user.role),
                style: const TextStyle(fontSize: 11, color: AppColors.accent),
              ),
            ),
            if (user.site != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${l10n.unitLabel} ${user.site!.wireName}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
            if (user.courseNumber != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.training,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  l10n.courseTag(user.courseNumber!),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.trainingText),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          [
            user.email,
            if (user.department != null)
              L10nUtil.departmentLabel(l10n, user.department!),
            if (user.jobRole != null)
              L10nUtil.jobRoleLabel(l10n, user.jobRole!),
            if (certNames.isNotEmpty)
              certNames.join(', ')
            else
              l10n.noCertifications,
          ].join('  ·  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.openAvailabilityCalendar,
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              onPressed: () => UserAvailabilityDialog.show(context, user),
            ),
            IconButton(
              tooltip: l10n.editStaffMember,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _UserEditorDialog.show(context, user),
            ),
          ],
        ),
      ),
    );
  }
}

/// Edit certifications, availability status, org placement, and (admin
/// only) role.
class _UserEditorDialog extends StatefulWidget {
  final AppUser user;

  const _UserEditorDialog({required this.user});

  static Future<void> show(BuildContext context, AppUser user) => showDialog(
        context: context,
        routeSettings: const RouteSettings(name: 'user_editor_dialog'),
        builder: (_) => _UserEditorDialog(user: user),
      );

  @override
  State<_UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<_UserEditorDialog> {
  late Set<String> certIds = {...widget.user.certifications};
  late Map<String, DateTime> certTimes = {...widget.user.certificationTimes};
  late UserStatus status = widget.user.status;
  late UserRole role = widget.user.role;
  late Site? site = widget.user.site;
  late Department? department = widget.user.department;
  late JobRole? jobRole = widget.user.jobRole;
  late final courseController = TextEditingController(
      text: widget.user.courseNumber?.toString() ?? '');
  bool isBusy = false;

  @override
  void dispose() {
    courseController.dispose();
    super.dispose();
  }

  int? get _courseNumber => int.tryParse(courseController.text.trim());

  void _toggleCert(String certId, bool selected) => setState(() {
        if (selected) {
          certIds.add(certId);
          certTimes.putIfAbsent(certId, () => DateTime.now());
        } else {
          certIds.remove(certId);
          certTimes.remove(certId);
        }
      });

  Future<void> _pickEarnedDate(String certId) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: certTimes[certId] ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => certTimes[certId] = picked);
  }

  bool get _orgChanged =>
      site != widget.user.site ||
      department != widget.user.department ||
      jobRole != widget.user.jobRole;

  /// Certifications are offered per the edited placement: a scoped
  /// certification only shows when every pinned layer matches (already-held
  /// ones stay visible so they can be removed).
  bool _certVisible(Certification certification) =>
      certIds.contains(certification.id) ||
      ((certification.site == null || certification.site == site) &&
          (certification.department == null ||
              certification.department == department) &&
          (certification.jobRole == null ||
              certification.jobRole == jobRole));

  Future<void> onSavePressed() async {
    setState(() => isBusy = true);
    final userService = locator<UserService>();
    certTimes.removeWhere((certId, _) => !certIds.contains(certId));
    var success = await userService.updateCertifications(
        widget.user.id, certIds.toList(), certTimes);
    if (success && _courseNumber != widget.user.courseNumber) {
      success =
          await userService.updateCourseNumber(widget.user.id, _courseNumber);
    }
    if (success && _orgChanged) {
      success = await userService.updateOrgAssignment(widget.user.id,
          site: site, department: department, jobRole: jobRole);
    }
    if (success && status != widget.user.status) {
      success = await userService.updateStatus(widget.user.id, status);
    }
    if (success && role != widget.user.role) {
      success = await locator<FunctionsService>()
          .setUserRole(widget.user.id, role.name);
    }
    if (!mounted) return;
    setState(() => isBusy = false);
    if (success) {
      Navigator.pop(context);
    } else {
      SnackBarUtil.showSnackBar(context,
          AppLocalizations.of(context)!.failedToSaveChanges, Variant.ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stationsManager = locator<StationsManager>();
    final isAdmin = locator<UserManager>().role == UserRole.admin;
    return AlertDialog(
      title: Text(widget.user.displayName),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.availabilityLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<UserStatus>(
                segments: [
                  ButtonSegment(
                      value: UserStatus.available,
                      label: Text(l10n.statusAvailable)),
                  ButtonSegment(
                      value: UserStatus.sick, label: Text(l10n.statusSick)),
                  ButtonSegment(
                      value: UserStatus.unavailable,
                      label: Text(l10n.statusUnavailable)),
                ],
                selected: {status},
                onSelectionChanged: (selection) =>
                    setState(() => status = selection.first),
              ),
              const SizedBox(height: 16),
              Text(l10n.orgPlacementTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OrgScopePicker(
                site: site,
                department: department,
                jobRole: jobRole,
                onSiteChanged: (value) => setState(() => site = value),
                onDepartmentChanged: (value) =>
                    setState(() => department = value),
                onJobRoleChanged: (value) => setState(() => jobRole = value),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: courseController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.courseNumberLabel,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.certificationsTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              StreamBuilder<List<Certification>>(
                initialData: stationsManager.certifications,
                stream: stationsManager.certificationsStream,
                builder: (context, snapshot) {
                  final certifications =
                      (snapshot.data ?? const <Certification>[])
                          .where(_certVisible)
                          .toList();
                  if (certifications.isEmpty) {
                    return Text(
                      l10n.noCertificationsInCatalog,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (final certification in certifications)
                            FilterChip(
                              label: Text(certification.name),
                              selected: certIds.contains(certification.id),
                              onSelected: (selected) =>
                                  _toggleCert(certification.id, selected),
                            ),
                        ],
                      ),
                      // Earned-at date per held certification, editable.
                      for (final certification in certifications)
                        if (certIds.contains(certification.id))
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${certification.name} — '
                                    '${certTimes[certification.id] == null ? '—' : l10n.earnedOnDate(DateFormat('d MMM yyyy').format(certTimes[certification.id]!))}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.edit_calendar_outlined,
                                      size: 16),
                                  onPressed: () =>
                                      _pickEarnedDate(certification.id),
                                ),
                              ],
                            ),
                          ),
                    ],
                  );
                },
              ),
              if (isAdmin) ...[
                const SizedBox(height: 16),
                Text(l10n.roleLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  items: [
                    for (final value in UserRole.values)
                      DropdownMenuItem(
                          value: value,
                          child: Text(L10nUtil.roleLabel(l10n, value))),
                  ],
                  onChanged: (value) =>
                      setState(() => role = value ?? role),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: isBusy ? null : onSavePressed,
          child: Text(isBusy ? l10n.saving : l10n.save),
        ),
      ],
    );
  }
}

/// The certification catalog editor (create/rename/delete).
class _CertificationCatalogDialog extends StatefulWidget {
  const _CertificationCatalogDialog();

  static Future<void> show(BuildContext context) => showDialog(
        context: context,
        routeSettings:
            const RouteSettings(name: 'certification_catalog_dialog'),
        builder: (_) => const _CertificationCatalogDialog(),
      );

  @override
  State<_CertificationCatalogDialog> createState() =>
      _CertificationCatalogDialogState();
}

class _CertificationCatalogDialogState
    extends State<_CertificationCatalogDialog> {
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> onAddPressed() async {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final id = await locator<StationsManager>()
        .createCertification(Certification(id: '', name: name));
    if (!mounted) return;
    if (id == null) {
      SnackBarUtil.showSnackBar(
          context,
          AppLocalizations.of(context)!.failedToAddCertification,
          Variant.ERROR);
    } else {
      nameController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stationsManager = locator<StationsManager>();
    return AlertDialog(
      title: Text(l10n.certificationsTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.newCertification,
                      isDense: true,
                    ),
                    onSubmitted: (_) => onAddPressed(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: StreamBuilder<List<Certification>>(
                initialData: stationsManager.certifications,
                stream: stationsManager.certificationsStream,
                builder: (context, snapshot) {
                  final certifications = snapshot.data ?? const [];
                  if (certifications.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.certCatalogEmptyExample),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final certification in certifications)
                        ListTile(
                          dense: true,
                          title: Text(certification.name),
                          subtitle: Text([
                            '${l10n.certLevelLabel} ${certification.level}',
                            ?OrgScopePicker.scopeLabel(l10n,
                                site: certification.site,
                                department: certification.department,
                                jobRole: certification.jobRole),
                          ].join(' · ')),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.editCertification,
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18),
                                onPressed: () =>
                                    _CertificationEditorDialog.show(
                                        context, certification),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.danger),
                                onPressed: () => stationsManager
                                    .deleteCertification(certification.id),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// Edit a certification's level (the default priority of its training
/// sessions) and the staffing needed to run a simulation for it.
class _CertificationEditorDialog extends StatefulWidget {
  final Certification certification;

  const _CertificationEditorDialog({required this.certification});

  static Future<void> show(
          BuildContext context, Certification certification) =>
      showDialog(
        context: context,
        routeSettings: const RouteSettings(name: 'certification_editor_dialog'),
        builder: (_) =>
            _CertificationEditorDialog(certification: certification),
      );

  @override
  State<_CertificationEditorDialog> createState() =>
      _CertificationEditorDialogState();
}

class _CertificationEditorDialogState
    extends State<_CertificationEditorDialog> {
  late final nameController =
      TextEditingController(text: widget.certification.name);
  late int level = widget.certification.level;
  late Site? site = widget.certification.site;
  late Department? department = widget.certification.department;
  late JobRole? jobRole = widget.certification.jobRole;

  /// certId → count; 0 rows are dropped on save.
  late final Map<String, int> staffCounts = {
    for (final requirement in widget.certification.simulationStaff)
      requirement.certificationId: requirement.count,
  };
  bool isBusy = false;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> onSavePressed() async {
    setState(() => isBusy = true);
    // Built whole (not copyWith): clearing a scope layer back to null must
    // stick.
    final success = await locator<StationsManager>().updateCertification(
      Certification(
        id: widget.certification.id,
        name: nameController.text.trim().isEmpty
            ? widget.certification.name
            : nameController.text.trim(),
        description: widget.certification.description,
        level: level,
        simulationStaff: [
          for (final entry in staffCounts.entries)
            if (entry.value > 0)
              CertRequirement(
                  certificationId: entry.key, count: entry.value),
        ],
        site: site,
        department: department,
        jobRole: jobRole,
        color: widget.certification.color,
        createdAt: widget.certification.createdAt,
      ),
    );
    if (!mounted) return;
    setState(() => isBusy = false);
    if (success) {
      Navigator.pop(context);
    } else {
      SnackBarUtil.showSnackBar(context,
          AppLocalizations.of(context)!.failedToSaveChanges, Variant.ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final certifications = locator<StationsManager>().certifications;
    return AlertDialog(
      title: Text(l10n.editCertification),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.nameLabel,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.orgPlacementTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              OrgScopePicker(
                site: site,
                department: department,
                jobRole: jobRole,
                onSiteChanged: (value) => setState(() => site = value),
                onDepartmentChanged: (value) =>
                    setState(() => department = value),
                onJobRoleChanged: (value) => setState(() => jobRole = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(l10n.certLevelLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: level <= 0
                        ? null
                        : () => setState(() => level--),
                  ),
                  Text('$level',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => setState(() => level++),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(l10n.simulationStaffTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 8),
                child: Text(
                  l10n.simulationStaffHint,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              for (final certification in certifications)
                Row(
                  children: [
                    Expanded(child: Text(certification.name)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: (staffCounts[certification.id] ?? 0) <= 0
                          ? null
                          : () => setState(() =>
                              staffCounts[certification.id] =
                                  staffCounts[certification.id]! - 1),
                    ),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '${staffCounts[certification.id] ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: () => setState(() =>
                          staffCounts[certification.id] =
                              (staffCounts[certification.id] ?? 0) + 1),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: isBusy ? null : onSavePressed,
          child: Text(isBusy ? l10n.saving : l10n.save),
        ),
      ],
    );
  }
}
