import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../utils/app_colors.dart';
import '../common/loading_shimmer.dart';
import '../common/error_banner.dart';

/// List view of all schedules with search and filter
class ScheduleListView extends ConsumerStatefulWidget {
  final bool isDesktop;

  const ScheduleListView({super.key, required this.isDesktop});

  @override
  ConsumerState<ScheduleListView> createState() => _ScheduleListViewState();
}

class _ScheduleListViewState extends ConsumerState<ScheduleListView> {
  final _searchController = TextEditingController();
  String _filterStatus = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Schedule> _filterSchedules(List<Schedule> schedules) {
    var filtered = schedules;
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((s) {
        final stationName = s.station?.name.toLowerCase() ?? '';
        final userName = s.user?.name.toLowerCase() ?? '';
        return stationName.contains(query) || userName.contains(query);
      }).toList();
    }
    if (_filterStatus != 'all') {
      filtered = filtered.where((s) {
        switch (_filterStatus) {
          case 'covered':
            return s.isCovered;
          case 'open':
            return s.isOpen;
          case 'critical':
            return s.isCritical;
          default:
            return true;
        }
      }).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final schedulesState = ref.watch(schedulesListProvider);
    final filtered = _filterSchedules(schedulesState.schedules);

    return Column(
      children: [
        // Toolbar
        _ListToolbar(
          searchController: _searchController,
          filterStatus: _filterStatus,
          onFilterChanged: (v) => setState(() => _filterStatus = v),
          onSearchChanged: (_) => setState(() {}),
        ),
        // Content
        Expanded(
          child: schedulesState.isLoading
              ? const _ListShimmer()
              : schedulesState.error != null
                  ? ErrorBanner(
                      message: schedulesState.error!,
                      onRetry: () => ref
                          .read(schedulesListProvider.notifier)
                          .loadSchedules(),
                    )
                  : filtered.isEmpty
                      ? _EmptyListState(
                          hasFilter: _filterStatus != 'all' ||
                              _searchController.text.isNotEmpty,
                        )
                      : widget.isDesktop
                          ? _DesktopListTable(schedules: filtered)
                          : _MobileListCards(schedules: filtered),
        ),
      ],
    );
  }
}

class _ListToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final String filterStatus;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onSearchChanged;

  const _ListToolbar({
    required this.searchController,
    required this.filterStatus,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppColors.surface,
      child: Row(
        children: [
          // Search
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search schedules...',
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.accent, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter dropdown
          _FilterDropdown(
            value: filterStatus,
            onChanged: onFilterChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: (v) => onChanged(v ?? 'all'),
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'covered', child: Text('Covered')),
            DropdownMenuItem(value: 'open', child: Text('Open')),
            DropdownMenuItem(value: 'critical', child: Text('Critical')),
          ],
        ),
      ),
    );
  }
}

class _DesktopListTable extends ConsumerWidget {
  final List<Schedule> schedules;

  const _DesktopListTable({required this.schedules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Row(
                children: [
                  _HeaderCell(label: 'Station', flex: 2),
                  _HeaderCell(label: 'Date', flex: 2),
                  _HeaderCell(label: 'Shift Time', flex: 2),
                  _HeaderCell(label: 'Assigned To', flex: 2),
                  _HeaderCell(label: 'Status', flex: 1),
                  _HeaderCell(label: 'Actions', flex: 1),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            // Rows
            ...schedules.map(
              (s) => _ListTableRow(
                schedule: s,
                onAssign: () =>
                    ref.read(assignmentPanelProvider.notifier).open(s),
                onDelete: () async {
                  await ref
                      .read(schedulesListProvider.notifier)
                      .deleteSchedule(s.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _HeaderCell({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ListTableRow extends StatefulWidget {
  final Schedule schedule;
  final VoidCallback onAssign;
  final VoidCallback onDelete;

  const _ListTableRow({
    required this.schedule,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  State<_ListTableRow> createState() => _ListTableRowState();
}

class _ListTableRowState extends State<_ListTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.accent.withOpacity(0.04)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            // Station
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  s.station?.name ?? s.stationId,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            // Date
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  DateFormat('EEE, MMM d').format(s.startTime),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Shift time
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  s.shiftTimeLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            // Assigned to
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: s.user != null
                    ? Row(
                        children: [
                          _UserAvatar(user: s.user!),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.user!.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'Unassigned',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
            ),
            // Status
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _StatusChip(schedule: s),
              ),
            ),
            // Actions
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          s.isCovered ? Icons.edit : Icons.person_add,
                          size: 18,
                          color: AppColors.accent,
                        ),
                        onPressed: widget.onAssign,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: s.isCovered ? 'Edit' : 'Assign',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        onPressed: widget.onDelete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Delete',
                      ),
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
}

class _MobileListCards extends ConsumerWidget {
  final List<Schedule> schedules;

  const _MobileListCards({required this.schedules});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, i) {
        final s = schedules[i];
        return _MobileScheduleCard(
          schedule: s,
          onAssign: () =>
              ref.read(assignmentPanelProvider.notifier).open(s),
          onDelete: () async {
            await ref
                .read(schedulesListProvider.notifier)
                .deleteSchedule(s.id);
          },
        );
      },
    );
  }
}

class _MobileScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onAssign;
  final VoidCallback onDelete;

  const _MobileScheduleCard({
    required this.schedule,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final s = schedule;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: s.isCritical
                  ? AppColors.danger
                  : s.isCovered
                      ? AppColors.success
                      : AppColors.warning,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.station?.name ?? s.stationId,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _StatusChip(schedule: s),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${DateFormat('EEE, MMM d').format(s.startTime)} • ${s.shiftTimeLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (s.user != null) ...
                      [
                        _UserAvatar(user: s.user!),
                        const SizedBox(width: 8),
                        Text(
                          s.user!.name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ]
                    else
                      const Text(
                        'Unassigned',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: onAssign,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      child: Text(s.isCovered ? 'Edit' : 'Assign'),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppColors.danger,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyListState extends StatelessWidget {
  final bool hasFilter;

  const _EmptyListState({required this.hasFilter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.filter_list_off : Icons.calendar_month_outlined,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No schedules match your filter' : 'No schedules yet',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Try adjusting your search or filter'
                : 'Create a new shift to get started',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListShimmer extends StatelessWidget {
  const _ListShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          8,
          (i) => Container(
            height: 52,
            margin: const EdgeInsets.only(bottom: 1),
            child: const LoadingShimmer(),
          ),
        ),
      ),
    );
  }
}

// Shared widgets
class _UserAvatar extends StatelessWidget {
  final UserInfo user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Schedule schedule;

  const _StatusChip({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final (bg, textColor, label) = _style();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  (Color, Color, String) _style() {
    if (schedule.isCritical) {
      return (AppColors.shiftCritical, AppColors.danger, 'Critical');
    }
    if (schedule.isCovered) {
      return (AppColors.shiftCovered, AppColors.success, 'Covered');
    }
    return (AppColors.shiftOpen, const Color(0xFF92400E), 'Open');
  }
}
