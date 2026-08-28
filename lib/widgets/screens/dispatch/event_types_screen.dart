import 'package:flutter/material.dart';

import '../../../app_config/service_locator.dart';
import '../../../entities/certification.dart';
import '../../../entities/event_type.dart';
import '../../../entities/station.dart';
import '../../../managers/dispatch_manager.dart';
import '../../../managers/stations_manager.dart';
import '../../../managers/user_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/snackbar_util.dart';

/// Pre-defined emergency scenarios: which certifications mark a responder
/// and which stations are tied to the event.
class EventTypesScreen extends StatelessWidget {
  static const ROUTE_SUB_PATH = 'event-types';
  static const ROUTE_NAME = 'event-types';

  const EventTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dispatchManager = locator<DispatchManager>();
    final canEdit = locator<UserManager>().role?.canManage ?? false;
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _EventTypeEditorDialog.show(context),
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('New Event Type'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              'Event Types',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<EventType>>(
              initialData: dispatchManager.eventTypes,
              stream: dispatchManager.eventTypesStream,
              builder: (context, snapshot) {
                final types = snapshot.data ?? const <EventType>[];
                if (types.isEmpty) {
                  return const Center(
                    child: Text(
                      'No scenarios yet — e.g. "Event Type C" alerting all '
                      'Type C Responders.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 88),
                  itemCount: types.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _EventTypeTile(
                    eventType: types[index],
                    canEdit: canEdit,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EventTypeTile extends StatelessWidget {
  final EventType eventType;
  final bool canEdit;

  const _EventTypeTile({required this.eventType, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final stationsManager = locator<StationsManager>();
    final certNames = eventType.responderCertifications
        .map((id) => stationsManager.certificationById(id)?.name ?? id)
        .join(', ');
    final stationNames = eventType.stationIds
        .map((id) => stationsManager.stationById(id)?.name ?? id)
        .join(', ');
    final isCritical = eventType.priority == EventPriority.critical;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(
          Icons.campaign,
          color: isCritical ? AppColors.danger : AppColors.warning,
        ),
        title: Row(
          children: [
            Text(eventType.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            if (!eventType.active)
              const Text('(inactive)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
        subtitle: Text(
          [
            'Responders: ${certNames.isEmpty ? '—' : certNames}',
            if (stationNames.isNotEmpty) 'Stations: $stationNames',
          ].join('  ·  '),
        ),
        trailing: canEdit
            ? IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () =>
                    _EventTypeEditorDialog.show(context, eventType: eventType),
              )
            : null,
      ),
    );
  }
}

class _EventTypeEditorDialog extends StatefulWidget {
  final EventType? eventType;

  const _EventTypeEditorDialog({this.eventType});

  static Future<void> show(BuildContext context, {EventType? eventType}) =>
      showDialog(
        context: context,
        routeSettings: const RouteSettings(name: 'event_type_editor_dialog'),
        builder: (_) => _EventTypeEditorDialog(eventType: eventType),
      );

  @override
  State<_EventTypeEditorDialog> createState() => _EventTypeEditorDialogState();
}

class _EventTypeEditorDialogState extends State<_EventTypeEditorDialog> {
  final formKey = GlobalKey<FormState>();
  late final nameController =
      TextEditingController(text: widget.eventType?.name);
  late final descriptionController =
      TextEditingController(text: widget.eventType?.description);
  late Set<String> certIds = {...?widget.eventType?.responderCertifications};
  late Set<String> stationIds = {...?widget.eventType?.stationIds};
  late EventPriority priority =
      widget.eventType?.priority ?? EventPriority.high;
  late bool active = widget.eventType?.active ?? true;
  bool isBusy = false;

  bool get isEditing => widget.eventType != null;

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> onSavePressed() async {
    if (!formKey.currentState!.validate()) return;
    if (certIds.isEmpty) {
      SnackBarUtil.showSnackBar(
          context,
          'Pick at least one responder certification.',
          Variant.WARNING);
      return;
    }
    setState(() => isBusy = true);
    final eventType = EventType(
      id: widget.eventType?.id ?? '',
      name: nameController.text.trim(),
      description: descriptionController.text.trim().isEmpty
          ? null
          : descriptionController.text.trim(),
      responderCertifications: certIds.toList(),
      stationIds: stationIds.toList(),
      priority: priority,
      active: active,
      createdAt: widget.eventType?.createdAt,
    );
    final dispatchManager = locator<DispatchManager>();
    final success = isEditing
        ? await dispatchManager.updateEventType(eventType)
        : await dispatchManager.createEventType(eventType) != null;
    if (!mounted) return;
    setState(() => isBusy = false);
    if (success) {
      Navigator.pop(context);
    } else {
      SnackBarUtil.showSnackBar(
          context, 'Failed to save event type.', Variant.ERROR);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stationsManager = locator<StationsManager>();
    return AlertDialog(
      title: Text(isEditing ? 'Edit Event Type' : 'New Event Type'),
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
                  decoration:
                      const InputDecoration(labelText: 'Name (e.g. Event Type C)'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Priority',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                SegmentedButton<EventPriority>(
                  segments: const [
                    ButtonSegment(
                        value: EventPriority.high, label: Text('High')),
                    ButtonSegment(
                        value: EventPriority.critical,
                        label: Text('Critical')),
                  ],
                  selected: {priority},
                  onSelectionChanged: (selection) =>
                      setState(() => priority = selection.first),
                ),
                const SizedBox(height: 16),
                const Text('Responder certifications (holder of ANY)',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                StreamBuilder<List<Certification>>(
                  initialData: stationsManager.certifications,
                  stream: stationsManager.certificationsStream,
                  builder: (context, snapshot) {
                    final certifications = snapshot.data ?? const [];
                    if (certifications.isEmpty) {
                      return const Text(
                        'No certifications defined — add them on the Staff '
                        'screen first.',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      );
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final certification in certifications)
                          FilterChip(
                            label: Text(certification.name),
                            selected: certIds.contains(certification.id),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                certIds.add(certification.id);
                              } else {
                                certIds.remove(certification.id);
                              }
                            }),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text('Stations involved',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                StreamBuilder<List<Station>>(
                  initialData: stationsManager.stations,
                  stream: stationsManager.stationsStream,
                  builder: (context, snapshot) {
                    final stations = snapshot.data ?? const [];
                    return Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final station in stations)
                          FilterChip(
                            label: Text(station.name),
                            selected: stationIds.contains(station.id),
                            onSelected: (selected) => setState(() {
                              if (selected) {
                                stationIds.add(station.id);
                              } else {
                                stationIds.remove(station.id);
                              }
                            }),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  subtitle: const Text(
                      'Inactive scenarios are hidden from the dispatch board'),
                  value: active,
                  onChanged: (value) => setState(() => active = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isBusy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isBusy ? null : onSavePressed,
          child: Text(isBusy ? 'Saving…' : (isEditing ? 'Save' : 'Create')),
        ),
      ],
    );
  }
}
