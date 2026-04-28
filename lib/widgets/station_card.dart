import 'package:flutter/material.dart';
import '../models/station.dart';
import '../utils/app_colors.dart';
import 'status_chip.dart';

/// Mobile card view for a single station.
///
/// Displays station info in a card layout optimized for small screens.
/// Shows edit and delete action buttons.
class StationCard extends StatelessWidget {
  final Station station;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const StationCard({
    super.key,
    required this.station,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with station ID and status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.tableHeader,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                // Station ID badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _formatId(station.id),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    station.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip.fromStationStatus(station.status),
              ],
            ),
          ),

          // Station details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _InfoItem(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: station.location,
                    ),
                    const SizedBox(width: 24),
                    _InfoItem(
                      icon: Icons.people_outline,
                      label: 'Capacity',
                      value: '${station.capacity} slots',
                    ),
                    if (station.scheduleCount > 0) ...
                      [
                        const SizedBox(width: 24),
                        _InfoItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Schedules',
                          value: '${station.scheduleCount}',
                        ),
                      ],
                  ],
                ),
                if (station.notes != null && station.notes!.isNotEmpty) ...
                  [
                    const SizedBox(height: 10),
                    Text(
                      station.notes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
              ],
            ),
          ),

          // Action buttons
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (onDelete != null) ...
                  [
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatId(String id) {
    // Show first 6 chars of UUID as station ID
    if (id.length >= 6) {
      return 'ST-${id.substring(0, 6).toUpperCase()}';
    }
    return 'ST-$id';
  }
}

/// Small info item with icon, label, and value.
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
