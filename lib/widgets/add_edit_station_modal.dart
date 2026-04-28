import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/station.dart';
import '../providers/stations_provider.dart';
import '../services/station_service.dart';
import '../utils/app_colors.dart';
import '../utils/validators.dart';

/// Modal dialog for adding or editing a station.
///
/// Supports both create (station == null) and edit (station != null) modes.
/// Validates all fields before submission and shows inline errors.
class AddEditStationModal extends ConsumerStatefulWidget {
  /// The station to edit, or null to create a new one.
  final Station? station;

  const AddEditStationModal({super.key, this.station});

  /// Show the modal and return the saved station, or null if cancelled.
  static Future<Station?> show(
    BuildContext context, {
    Station? station,
  }) {
    return showDialog<Station?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditStationModal(station: station),
    );
  }

  @override
  ConsumerState<AddEditStationModal> createState() =>
      _AddEditStationModalState();
}

class _AddEditStationModalState extends ConsumerState<AddEditStationModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _locationController;
  late final TextEditingController _capacityController;
  late final TextEditingController _notesController;

  late StationStatus _status;
  bool _isSaving = false;
  String? _saveError;

  bool get _isEditing => widget.station != null;

  @override
  void initState() {
    super.initState();
    final s = widget.station;
    _nameController = TextEditingController(text: s?.name ?? '');
    _locationController = TextEditingController(text: s?.location ?? '');
    _capacityController =
        TextEditingController(text: s?.capacity.toString() ?? '');
    _notesController = TextEditingController(text: s?.notes ?? '');
    _status = s?.status ?? StationStatus.active;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final notifier = ref.read(stationsNotifierProvider.notifier);

    try {
      final Station result = _isEditing
          ? await notifier.updateStation(
              widget.station!.id,
              UpdateStationRequest(
                name: _nameController.text.trim(),
                location: _locationController.text.trim(),
                capacity: int.parse(_capacityController.text.trim()),
                status: _status,
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
              ),
            )
          : await notifier.createStation(
              CreateStationRequest(
                name: _nameController.text.trim(),
                location: _locationController.text.trim(),
                capacity: int.parse(_capacityController.text.trim()),
                status: _status,
                notes: _notesController.text.trim().isEmpty
                    ? null
                    : _notesController.text.trim(),
              ),
            );

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_saveError != null) ...[
                        const SizedBox(height: 16),
                        _buildErrorBox(_saveError!),
                      ],
                      const SizedBox(height: 20),
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildLocationField(),
                      const SizedBox(height: 16),
                      _buildCapacityField(),
                      const SizedBox(height: 16),
                      _buildStatusField(),
                      const SizedBox(height: 16),
                      _buildNotesField(),
                      const SizedBox(height: 24),
                      _buildActions(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.layers_outlined,
              size: 20,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit Station' : 'Add New Station',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _isEditing
                      ? 'Update station information'
                      : 'Create a new operational station',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(null),
            icon: const Icon(Icons.close, size: 20),
            color: AppColors.textSecondary,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Station Name', required: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nameController,
          enabled: !_isSaving,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. Alpha Station',
            prefixIcon: Icon(Icons.layers_outlined, size: 18),
          ),
          validator: Validators.stationName,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Location / Sector', required: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: _locationController,
          enabled: !_isSaving,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'e.g. North Sector',
            prefixIcon: Icon(Icons.location_on_outlined, size: 18),
          ),
          validator: Validators.location,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildCapacityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Capacity (staff slots)', required: true),
        const SizedBox(height: 6),
        TextFormField(
          controller: _capacityController,
          enabled: !_isSaving,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            hintText: '1 – 20',
            prefixIcon: Icon(Icons.people_outline, size: 18),
            suffixText: 'slots',
          ),
          validator: Validators.capacity,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildStatusField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Status'),
        const SizedBox(height: 8),
        Row(
          children: [
            _StatusRadio(
              value: StationStatus.active,
              groupValue: _status,
              label: 'Active',
              color: AppColors.success,
              onChanged: _isSaving ? null : (v) => setState(() => _status = v!),
            ),
            const SizedBox(width: 24),
            _StatusRadio(
              value: StationStatus.closed,
              groupValue: _status,
              label: 'Closed',
              color: AppColors.danger,
              onChanged: _isSaving ? null : (v) => setState(() => _status = v!),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel(label: 'Notes'),
        const SizedBox(height: 6),
        TextFormField(
          controller: _notesController,
          enabled: !_isSaving,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Optional notes about this station...',
            alignLabelWithHint: true,
          ),
          validator: Validators.notes,
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_isEditing ? 'Save Changes' : 'Save Station'),
        ),
      ],
    );
  }
}

/// Field label with optional required asterisk.
class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.danger),
            ),
        ],
      ),
    );
  }
}

/// Radio button for status selection.
class _StatusRadio extends StatelessWidget {
  final StationStatus value;
  final StationStatus groupValue;
  final String label;
  final Color color;
  final ValueChanged<StationStatus?>? onChanged;

  const _StatusRadio({
    required this.value,
    required this.groupValue,
    required this.label,
    required this.color,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(value) : null,
      child: RadioGroup(
        groupValue: groupValue,
        onChanged: (value) => onChanged?.call(value),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<StationStatus>(
              value: value,
              activeColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
