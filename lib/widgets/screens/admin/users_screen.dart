import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/app_user.dart';
import '../../../entities/cert_requirement.dart';
import '../../../entities/certification.dart';
import '../../../managers/shifts_manager.dart';
import '../../../managers/stations_manager.dart';
import '../../../managers/user_manager.dart';
import '../../../services/functions_service.dart';
import '../../../services/user_service.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/l10n_util.dart';
import '../../../utils/snackbar_util.dart';

/// Staff management: certification tagging, availability status, roles
/// (admin only), and the certification catalog itself.
class UsersScreen extends StatelessWidget {
  static const ROUTE_PATH = '/users';
  static const ROUTE_NAME = 'users';

  const UsersScreen({super.key});

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
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
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
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _CertificationCatalogDialog.show(context),
                  icon: const Icon(Icons.workspace_premium_outlined, size: 18),
                  label: Text(l10n.certificationsTitle),
                ),
              ],
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
                  return Center(child: Text(l10n.noStaffYet));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _UserTile(user: users[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
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
            if (certNames.isNotEmpty)
              certNames.join(', ')
            else
              l10n.noCertifications,
          ].join('  ·  '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          tooltip: l10n.editStaffMember,
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => _UserEditorDialog.show(context, user),
        ),
      ),
    );
  }
}

/// Edit certifications, availability status, and (admin only) role.
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
                  final certifications = snapshot.data ?? const [];
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
                          subtitle: Text(
                              '${l10n.certLevelLabel} ${certification.level}'),
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
    final success = await locator<StationsManager>().updateCertification(
      widget.certification.copyWith(
        name: nameController.text.trim().isEmpty
            ? widget.certification.name
            : nameController.text.trim(),
        level: level,
        simulationStaff: [
          for (final entry in staffCounts.entries)
            if (entry.value > 0)
              CertRequirement(
                  certificationId: entry.key, count: entry.value),
        ],
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
