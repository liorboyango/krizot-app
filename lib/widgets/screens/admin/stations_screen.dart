import 'package:flutter/material.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/certification.dart';
import '../../../entities/org_scope.dart';
import '../../../entities/station.dart';
import '../../../entities/time_window.dart';
import '../../../managers/org_filter_manager.dart';
import '../../../managers/stations_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/snackbar_util.dart';
import '../../empty_state.dart';
import '../../org_scope_picker.dart';
import '../../status_chip.dart';

class StationsScreen extends StatefulWidget {
  static const ROUTE_PATH = '/stations';
  static const ROUTE_NAME = 'stations';

  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  final stationsManager = locator<StationsManager>();
  final orgFilter = locator<OrgFilterManager>();
  String searchQuery = '';

  Future<void> onAddPressed() => _StationEditorDialog.show(context);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onAddPressed,
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.newStation),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              children: [
                Text(
                  l10n.stationsTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: l10n.searchStations,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<void>(
              stream: orgFilter.changesStream,
              builder: (context, _) => StreamBuilder<List<Station>>(
                initialData: stationsManager.stations,
                stream: stationsManager.stationsStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final stations = snapshot.data!
                      .where(
                        (s) =>
                            orgFilter.matchesStation(s) &&
                            (searchQuery.isEmpty ||
                                s.name.toLowerCase().contains(searchQuery)),
                      )
                      .toList();
                  if (stations.isEmpty) {
                    return EmptyState(
                      icon: Icons.location_on_outlined,
                      title: l10n.noStations,
                      description: searchQuery.isEmpty
                          ? l10n.createFirstStation
                          : l10n.noStationsMatch(searchQuery),
                      actionLabel: searchQuery.isEmpty ? l10n.newStation : null,
                      onAction: searchQuery.isEmpty ? onAddPressed : null,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 88),
                    itemCount: stations.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _StationTile(station: stations[index]),
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

class _StationTile extends StatelessWidget {
  final Station station;

  const _StationTile({required this.station});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stationsManager = locator<StationsManager>();
    final certNames = station.requiredCertifications
        .map((id) => stationsManager.certificationById(id)?.name ?? id)
        .toList();
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.accent.withValues(alpha: 0.1),
          child: Icon(
            station.isAroundTheClock ? Icons.all_inclusive : Icons.schedule,
            color: AppColors.accent,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              station.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            StatusChip.fromStationStatus(context, station.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              station.isAroundTheClock
                  ? l10n.manning247
                  : l10n.onDemandWindows(station.activeWindows.join(', ')),
              ?OrgScopePicker.scopeLabel(
                l10n,
                site: station.site,
                department: station.department,
                jobRole: station.jobRole,
              ),
              if (certNames.isNotEmpty)
                l10n.requiresCerts(certNames.join(', ')),
            ].join('  ·  '),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: l10n.edit,
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () =>
                  _StationEditorDialog.show(context, station: station),
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.danger,
              ),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: 'delete_station_dialog'),
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteStationTitle),
        content: Text(l10n.deleteStationBody(station.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final success = await locator<StationsManager>().deleteStation(station.id);
    if (!success && context.mounted) {
      SnackBarUtil.showSnackBar(
        context,
        l10n.failedToDeleteStation,
        Variant.ERROR,
      );
    }
  }
}

/// Create/edit dialog covering all DESIGN.md station fields: manning type,
/// on-demand activity windows, and required certifications.
class _StationEditorDialog extends StatefulWidget {
  final Station? station;

  const _StationEditorDialog({this.station});

  static Future<void> show(BuildContext context, {Station? station}) =>
      showDialog(
        context: context,
        routeSettings: const RouteSettings(name: 'station_editor_dialog'),
        builder: (_) => _StationEditorDialog(station: station),
      );

  @override
  State<_StationEditorDialog> createState() => _StationEditorDialogState();
}

class _StationEditorDialogState extends State<_StationEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final nameController = TextEditingController(text: widget.station?.name);
  late final notesController = TextEditingController(
    text: widget.station?.notes,
  );
  late StationStatus status = widget.station?.status ?? StationStatus.active;
  late ManningType manningType =
      widget.station?.manningType ?? ManningType.aroundTheClock;
  late List<TimeWindow> windows = [...?widget.station?.activeWindows];
  late Set<String> requiredCerts = {...?widget.station?.requiredCertifications};
  late Site? site = widget.station?.site;
  late Department? department = widget.station?.department;
  late JobRole? jobRole = widget.station?.jobRole;
  bool isBusy = false;

  /// A certification is offered when its scope could apply to someone in
  /// the station's scope (each layer unpinned on either side, or equal).
  bool _certVisible(Certification certification) =>
      requiredCerts.contains(certification.id) ||
      ((certification.site == null ||
              site == null ||
              certification.site == site) &&
          (certification.department == null ||
              department == null ||
              certification.department == department) &&
          (certification.jobRole == null ||
              jobRole == null ||
              certification.jobRole == jobRole));

  bool get isEditing => widget.station != null;

  @override
  void dispose() {
    nameController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> onSavePressed() async {
    if (!formKey.currentState!.validate()) return;
    if (manningType == ManningType.onDemand && windows.isEmpty) {
      SnackBarUtil.showSnackBar(
        context,
        AppLocalizations.of(context)!.onDemandNeedsWindow,
        Variant.WARNING,
      );
      return;
    }
    setState(() => isBusy = true);
    final station = Station(
      id: widget.station?.id ?? '',
      name: nameController.text.trim(),
      status: status,
      manningType: manningType,
      activeWindows: manningType == ManningType.onDemand ? windows : const [],
      requiredCertifications: requiredCerts.toList(),
      site: site,
      department: department,
      jobRole: jobRole,
      capacity: widget.station?.capacity ?? 1,
      notes: notesController.text.trim().isEmpty
          ? null
          : notesController.text.trim(),
      createdAt: widget.station?.createdAt,
    );
    final stationsManager = locator<StationsManager>();
    final success = isEditing
        ? await stationsManager.updateStation(station)
        : await stationsManager.createStation(station) != null;
    if (!mounted) return;
    setState(() => isBusy = false);
    if (success) {
      Navigator.pop(context);
    } else {
      SnackBarUtil.showSnackBar(
        context,
        AppLocalizations.of(context)!.failedToSaveStation,
        Variant.ERROR,
      );
    }
  }

  Future<void> onAddWindowPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final start = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: l10n.windowStart,
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (start.hour + 2) % 24, minute: start.minute),
      helpText: l10n.windowEnd,
    );
    if (end == null || !mounted) return;
    setState(
      () => windows.add(TimeWindow(start: _hhmm(start), end: _hhmm(end))),
    );
  }

  static String _hhmm(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stationsManager = locator<StationsManager>();
    return AlertDialog(
      title: Text(isEditing ? l10n.editStation : l10n.newStation),
      content: SizedBox(
        width: 440,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.nameLabel),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? l10n.nameRequired
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.orgPlacementTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
                SegmentedButton<StationStatus>(
                  segments: [
                    ButtonSegment(
                      value: StationStatus.active,
                      label: Text(l10n.stationActive),
                    ),
                    ButtonSegment(
                      value: StationStatus.closed,
                      label: Text(l10n.stationClosed),
                    ),
                  ],
                  selected: {status},
                  onSelectionChanged: (selection) =>
                      setState(() => status = selection.first),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.manningLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                SegmentedButton<ManningType>(
                  segments: [
                    ButtonSegment(
                      value: ManningType.aroundTheClock,
                      label: Text(l10n.twentyFourSeven),
                    ),
                    ButtonSegment(
                      value: ManningType.onDemand,
                      label: Text(l10n.onDemand),
                    ),
                  ],
                  selected: {manningType},
                  onSelectionChanged: (selection) =>
                      setState(() => manningType = selection.first),
                ),
                if (manningType == ManningType.onDemand) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < windows.length; i++)
                        InputChip(
                          label: Text('${windows[i]}'),
                          onDeleted: () => setState(() => windows.removeAt(i)),
                        ),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(l10n.addWindow),
                        onPressed: onAddWindowPressed,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  l10n.requiredCertificationsLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
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
                        l10n.noCertsDefinedAddOnStaff,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final certification in certifications)
                          FilterChip(
                            label: Text(certification.name),
                            selected: requiredCerts.contains(certification.id),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                requiredCerts.add(certification.id);
                              } else {
                                requiredCerts.remove(certification.id);
                              }
                            }),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: l10n.notesLabel),
                  maxLines: 2,
                ),
              ],
            ),
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
          child: Text(
            isBusy ? l10n.saving : (isEditing ? l10n.save : l10n.create),
          ),
        ),
      ],
    );
  }
}
