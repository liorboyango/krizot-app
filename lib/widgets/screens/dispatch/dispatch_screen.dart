import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app_config/l10n/gen/app_localizations.dart';
import '../../../app_config/service_locator.dart';
import '../../../entities/emergency_event.dart';
import '../../../entities/event_type.dart';
import '../../../managers/dispatch_manager.dart';
import '../../../managers/org_filter_manager.dart';
import '../../../managers/user_manager.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/snackbar_util.dart';
import 'event_types_screen.dart';

/// Interface 3: emergency dispatch — one big button per scenario (single
/// confirm, minimal clicks), then live cards tracking responder acks.
class DispatchScreen extends StatelessWidget {
  static const ROUTE_PATH = '/dispatch';
  static const ROUTE_NAME = 'dispatch';

  const DispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dispatchManager = locator<DispatchManager>();
    final orgFilter = locator<OrgFilterManager>();
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
                  l10n.emergencyDispatchTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    '${DispatchScreen.ROUTE_PATH}/${EventTypesScreen.ROUTE_SUB_PATH}',
                  ),
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(l10n.eventTypesTitle),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<void>(
              stream: orgFilter.changesStream,
              builder: (context, _) => ListView(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                children: [
                  Text(
                    l10n.triggerCallout,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<EventType>>(
                    initialData: dispatchManager.eventTypes,
                    stream: dispatchManager.eventTypesStream,
                    builder: (context, snapshot) {
                      final types = (snapshot.data ?? const <EventType>[])
                          .where(
                            (type) =>
                                type.active && orgFilter.matchesSite(type.site),
                          )
                          .toList();
                      if (types.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(l10n.noEventTypesConfigured),
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final type in types)
                            _TriggerButton(eventType: type),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.activeEvents,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<EmergencyEvent>>(
                    initialData: dispatchManager.activeEvents,
                    stream: dispatchManager.activeEventsStream,
                    builder: (context, snapshot) {
                      final events = (snapshot.data ?? const <EmergencyEvent>[])
                          .where((event) => orgFilter.matchesSite(event.site))
                          .toList();
                      if (events.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(l10n.noActiveEmergencies),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final event in events)
                            _ActiveEventCard(event: event),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TriggerButton extends StatefulWidget {
  final EventType eventType;

  const _TriggerButton({required this.eventType});

  @override
  State<_TriggerButton> createState() => _TriggerButtonState();
}

class _TriggerButtonState extends State<_TriggerButton> {
  bool isBusy = false;

  Future<void> onPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      routeSettings: const RouteSettings(name: 'trigger_emergency_dialog'),
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.triggerEventConfirmTitle(widget.eventType.name)),
        content: Text(l10n.triggerEventConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.triggerAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => isBusy = true);
    final result = await locator<DispatchManager>().triggerEmergency(
      widget.eventType.id,
    );
    if (!mounted) return;
    setState(() => isBusy = false);
    if (result == null) {
      SnackBarUtil.showSnackBar(context, l10n.failedToTrigger, Variant.ERROR);
    } else {
      SnackBarUtil.showSnackBar(
        context,
        l10n.alertedResponders((result['alertedCount'] as num?)?.toInt() ?? 0),
        Variant.SUCCESS,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCritical = widget.eventType.priority == EventPriority.critical;
    return SizedBox(
      width: 230,
      height: 96,
      child: FilledButton(
        onPressed: isBusy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: isCritical ? AppColors.danger : AppColors.warning,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isBusy)
              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            else ...[
              const Icon(Icons.campaign, size: 28),
              const SizedBox(height: 6),
              Text(
                widget.eventType.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.eventType.site != null)
                Text(
                  '${AppLocalizations.of(context)!.unitLabel} '
                  '${widget.eventType.site!.wireName}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActiveEventCard extends StatelessWidget {
  final EmergencyEvent event;

  const _ActiveEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dispatchManager = locator<DispatchManager>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<EmergencyAck>>(
          stream: dispatchManager.acksStreamFor(event.id),
          builder: (context, snapshot) {
            final acks = snapshot.data ?? const <EmergencyAck>[];
            final ackedUids = acks.map((ack) => ack.uid).toSet();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.site == null
                            ? event.eventTypeName
                            : '${event.eventTypeName} · '
                                  '${AppLocalizations.of(context)!.unitLabel} '
                                  '${event.site!.wireName}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.acknowledgedTally(
                        ackedUids.length,
                        event.alertedUserIds.length,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () async {
                        final uid = locator<UserManager>().user?.id;
                        if (uid == null) return;
                        await dispatchManager.resolveEvent(event.id, uid);
                      },
                      child: Text(AppLocalizations.of(context)!.resolve),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final responder in event.alertedUsers)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          ackedUids.contains(responder.uid)
                              ? Icons.check_circle
                              : Icons.hourglass_top,
                          size: 16,
                          color: ackedUids.contains(responder.uid)
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        label: Text(
                          responder.displayName,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
