/// Stations management screen for Krizot.
///
/// Features:
/// - Desktop: data table with search, filter, pagination
/// - Mobile: card list
/// - Add/Edit station modal
/// - Delete confirmation dialog
/// - All operations wired to [StationsNotifier] (real API calls)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/station.dart';
import '../providers/stations_provider.dart';
import '../services/station_service.dart';
import '../utils/app_colors.dart';
import '../utils/breakpoints.dart';
import '../utils/error_handler.dart';
import '../utils/validators.dart';

/// Stations management page.
class StationsScreen extends ConsumerWidget {
  const StationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    if (width >= Breakpoints.tablet) {
      return const _DesktopStationsLayout();
    }
    return const _MobileStationsLayout();
  }
}

class _DesktopStationsLayout extends ConsumerWidget {
  const _DesktopStationsLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _StationsToolbar(onAdd: () => _showStationModal(context, ref)),
          const Expanded(child: _StationsTable()),
        ],
      ),
    );
  }
}

class _MobileStationsLayout extends ConsumerWidget {
  const _MobileStationsLayout();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stations')),
      backgroundColor: AppColors.background,
      body: const _StationsCardList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStationModal(context, ref),
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _StationsToolbar extends ConsumerWidget {
  const _StationsToolbar({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: [
          Text('Stations', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Station'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search stations...',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (q) => ref.read(stationsNotifierProvider.notifier).search(q),
            ),
          ),
          const SizedBox(width: 12),
          _StatusFilterDropdown(),
        ],
      ),
    );
  }
}

class _StatusFilterDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.watch(stationsNotifierProvider).valueOrNull?.params.status;
    return DropdownButton<StationStatus?>(
      value: currentStatus,
      hint: const Text('All Status'),
      underline: const SizedBox(),
      items: [
        const DropdownMenuItem(value: null, child: Text('All Status')),
        ...StationStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
      ],
      onChanged: (s) => ref.read(stationsNotifierProvider.notifier).filterByStatus(s),
    );
  }
}

class _StationsTable extends ConsumerWidget {
  const _StationsTable();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(stationsNotifierProvider);
    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ErrorHandler.getMessage(e), style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.read(stationsNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (state) {
        if (state.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.error!, style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.read(stationsNotifierProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (state.stations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.layers_outlined, size: 64, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('No stations found', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(100),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FixedColumnWidth(100),
                4: FixedColumnWidth(100),
                5: FixedColumnWidth(120),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: AppColors.tableRowAlt),
                  children: [_TH('ID'), _TH('Name'), _TH('Location'), _TH('Capacity'), _TH('Status'), _TH('Actions')],
                ),
                ...state.stations.asMap().entries.map((entry) {
                  final i = entry.key;
                  final station = entry.value;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: i.isOdd ? AppColors.tableRowAlt : AppColors.surface,
                    ),
                    children: [
                      _TD('ST-${station.id.substring(0, 4).toUpperCase()}'),
                      _TD(station.name),
                      _TD(station.location),
                      _TD(station.capacity.toString()),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: _StatusChip(status: station.status),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              color: AppColors.accent,
                              tooltip: 'Edit',
                              onPressed: () => _showStationModal(context, ref, station: station),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outlined, size: 18),
                              color: AppColors.danger,
                              tooltip: 'Delete',
                              onPressed: () => _confirmDelete(context, ref, station),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TH extends StatelessWidget {
  const _TH(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
    );
  }
}

class _TD extends StatelessWidget {
  const _TD(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final StationStatus status;
  @override
  Widget build(BuildContext context) {
    final isActive = status == StationStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.shiftCovered : AppColors.shiftCritical,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.shiftCoveredText : AppColors.shiftCriticalText,
        ),
      ),
    );
  }
}

class _StationsCardList extends ConsumerWidget {
  const _StationsCardList();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(stationsNotifierProvider);
    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(ErrorHandler.getMessage(e))),
      data: (state) {
        if (state.stations.isEmpty) return const Center(child: Text('No stations found'));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.stations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final station = state.stations[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(station.name, style: Theme.of(context).textTheme.titleMedium)),
                        _StatusChip(status: station.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('${station.location} | Cap: ${station.capacity}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showStationModal(context, ref, station: station),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _confirmDelete(context, ref, station),
                          icon: const Icon(Icons.delete_outlined, size: 16),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

void _showStationModal(BuildContext context, WidgetRef ref, {Station? station}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => _StationModal(station: station, ref: ref),
  );
}

class _StationModal extends StatefulWidget {
  const _StationModal({this.station, required this.ref});
  final Station? station;
  final WidgetRef ref;
  @override
  State<_StationModal> createState() => _StationModalState();
}

class _StationModalState extends State<_StationModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _capacityCtrl;
  late final TextEditingController _notesCtrl;
  late StationStatus _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.station?.name ?? '');
    _locationCtrl = TextEditingController(text: widget.station?.location ?? '');
    _capacityCtrl = TextEditingController(text: widget.station?.capacity.toString() ?? '');
    _notesCtrl = TextEditingController(text: widget.station?.notes ?? '');
    _status = widget.station?.status ?? StationStatus.active;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _capacityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final notifier = widget.ref.read(stationsNotifierProvider.notifier);
      if (widget.station == null) {
        await notifier.createStation(CreateStationRequest(
          name: _nameCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          capacity: int.parse(_capacityCtrl.text.trim()),
          status: _status,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ));
      } else {
        await notifier.updateStation(widget.station!.id, UpdateStationRequest(
          name: _nameCtrl.text.trim(),
          location: _locationCtrl.text.trim(),
          capacity: int.parse(_capacityCtrl.text.trim()),
          status: _status,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        ));
      }
      if (mounted) {
        Navigator.of(context).pop();
        ErrorHandler.showSuccess(context, widget.station == null ? 'Station created' : 'Station updated');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ErrorHandler.showSnackbar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(widget.station == null ? 'Add New Station' : 'Edit Station', style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
                const SizedBox(height: 20),
                TextFormField(controller: _nameCtrl, validator: Validators.stationName, decoration: const InputDecoration(labelText: 'Station Name *')),
                const SizedBox(height: 16),
                TextFormField(controller: _locationCtrl, validator: Validators.location, decoration: const InputDecoration(labelText: 'Location / Sector *')),
                const SizedBox(height: 16),
                TextFormField(controller: _capacityCtrl, keyboardType: TextInputType.number, validator: Validators.capacity, decoration: const InputDecoration(labelText: 'Capacity *', hintText: '1-20')),
                const SizedBox(height: 16),
                Text('Status', style: Theme.of(context).textTheme.bodyLarge),
                Row(
                  children: StationStatus.values.map((s) => Expanded(
                    child: RadioListTile<StationStatus>(
                      title: Text(s.label),
                      value: s,
                      groupValue: _status,
                      onChanged: (v) => setState(() => _status = v!),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                TextFormField(controller: _notesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes', alignLabelWithHint: true)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: _saving ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Station'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _confirmDelete(BuildContext context, WidgetRef ref, Station station) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete Station'),
      content: Text('Are you sure you want to delete "${station.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () async {
            Navigator.of(ctx).pop();
            try {
              await ref.read(stationsNotifierProvider.notifier).deleteStation(station.id);
              if (context.mounted) ErrorHandler.showSuccess(context, 'Station deleted');
            } catch (e) {
              if (context.mounted) ErrorHandler.showSnackbar(context, e);
            }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
