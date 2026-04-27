import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/station.dart';
import '../providers/stations_provider.dart';
import '../utils/app_colors.dart';
import '../utils/breakpoints.dart';
import '../widgets/add_edit_station_modal.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/station_card.dart';
import '../widgets/status_chip.dart';

/// Station Management Screen.
///
/// Displays a list of stations with full CRUD operations.
/// Desktop: data table with sortable columns and inline actions.
/// Mobile: card-based layout with swipe-to-delete.
class StationsScreen extends ConsumerStatefulWidget {
  const StationsScreen({super.key});

  @override
  ConsumerState<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends ConsumerState<StationsScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatusFilter;
  bool _showSearch = false;

  // Keyboard shortcut: 'N' to open add modal
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load stations on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stationsProvider.notifier).loadStations();
      ref.read(stationsProvider.notifier).loadStats();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  Future<void> _openAddModal() async {
    final result = await AddEditStationModal.show(context);
    if (result != null && mounted) {
      _showSuccessSnackbar('Station "${result.name}" created successfully');
    }
  }

  Future<void> _openEditModal(Station station) async {
    final result =
        await AddEditStationModal.show(context, station: station);
    if (result != null && mounted) {
      _showSuccessSnackbar('Station "${result.name}" updated successfully');
    }
  }

  Future<void> _confirmDelete(Station station) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Station'),
        content: Text(
          'Are you sure you want to delete "${station.name}"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref
          .read(stationsProvider.notifier)
          .deleteStation(station.id);
      if (success && mounted) {
        _showSuccessSnackbar('Station "${station.name}" deleted');
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onSearchChanged(String query) {
    ref.read(stationsProvider.notifier).search(query);
  }

  void _onStatusFilterChanged(String? status) {
    setState(() => _selectedStatusFilter = status);
    ref.read(stationsProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= Breakpoints.desktop;
    final isTablet = width >= Breakpoints.tablet;

    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        // 'N' key shortcut to add new station
        if (event.character == 'n' || event.character == 'N') {
          _openAddModal();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(isDesktop, isTablet),
            _buildErrorBanner(),
            Expanded(
              child: isDesktop || isTablet
                  ? _buildDesktopTable()
                  : _buildMobileList(),
            ),
          ],
        ),
        floatingActionButton:
            (!isDesktop && !isTablet) ? _buildFab() : null,
      ),
    );
  }

  Widget _buildTopBar(bool isDesktop, bool isTablet) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Station Management',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage operational stations and their configurations',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (isDesktop || isTablet)
                ElevatedButton.icon(
                  onPressed: _openAddModal,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Station'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Search and filter row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search stations...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.accent, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusFilterDropdown(),
              if (isDesktop) ...
                [
                  const SizedBox(width: 12),
                  _buildStatsRow(),
                ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedStatusFilter,
          hint: const Text(
            'All Status',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Status',
                  style: TextStyle(fontSize: 13)),
            ),
            const DropdownMenuItem<String?>(
              value: 'ACTIVE',
              child: Text('Active', style: TextStyle(fontSize: 13)),
            ),
            const DropdownMenuItem<String?>(
              value: 'CLOSED',
              child: Text('Closed', style: TextStyle(fontSize: 13)),
            ),
          ],
          onChanged: _onStatusFilterChanged,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final stats = ref.watch(stationsProvider).stats;
    if (stats == null) return const SizedBox.shrink();

    return Row(
      children: [
        _StatBadge(
          label: 'Total',
          value: stats.total.toString(),
          color: AppColors.accent,
        ),
        const SizedBox(width: 8),
        _StatBadge(
          label: 'Active',
          value: stats.active.toString(),
          color: AppColors.success,
        ),
        const SizedBox(width: 8),
        _StatBadge(
          label: 'Closed',
          value: stats.closed.toString(),
          color: AppColors.danger,
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    final error = ref.watch(stationsProvider).error;
    if (error == null) return const SizedBox.shrink();

    return ErrorBanner(
      message: error,
      onRetry: () {
        ref.read(stationsProvider.notifier).clearError();
        ref.read(stationsProvider.notifier).loadStations(refresh: true);
      },
      onDismiss: () => ref.read(stationsProvider.notifier).clearError(),
    );
  }

  Widget _buildDesktopTable() {
    final state = ref.watch(stationsProvider);

    if (state.isLoading) {
      return _buildTableShimmer();
    }

    if (state.stations.isEmpty) {
      return EmptyState(
        icon: Icons.layers_outlined,
        title: 'No stations found',
        description: state.searchQuery.isNotEmpty
            ? 'No stations match your search. Try a different query.'
            : 'Get started by adding your first operational station.',
        actionLabel: state.searchQuery.isEmpty ? 'Add Station' : null,
        onAction: state.searchQuery.isEmpty ? _openAddModal : null,
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTableHeader(),
                ...state.stations.asMap().entries.map(
                      (entry) => _buildTableRow(
                        entry.value,
                        isAlt: entry.key.isOdd,
                      ),
                    ),
                if (state.isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _buildTableFooter(state),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: AppColors.tableHeader,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      child: const Row(
        children: [
          SizedBox(width: 24),
          _TableHeaderCell(label: 'ID', flex: 2),
          _TableHeaderCell(label: 'Name', flex: 3),
          _TableHeaderCell(label: 'Location', flex: 3),
          _TableHeaderCell(label: 'Capacity', flex: 2),
          _TableHeaderCell(label: 'Status', flex: 2),
          _TableHeaderCell(label: 'Schedules', flex: 2),
          _TableHeaderCell(label: 'Actions', flex: 2),
          SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildTableRow(Station station, {bool isAlt = false}) {
    return _HoverableTableRow(
      station: station,
      isAlt: isAlt,
      onEdit: () => _openEditModal(station),
      onDelete: () => _confirmDelete(station),
    );
  }

  Widget _buildTableFooter(StationsState state) {
    final pagination = state.pagination;
    if (pagination == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Showing ${state.stations.length} of ${pagination.total} stations',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          if (state.hasMore)
            TextButton(
              onPressed: () =>
                  ref.read(stationsProvider.notifier).loadMore(),
              child: const Text('Load More'),
            ),
        ],
      ),
    );
  }

  Widget _buildTableShimmer() {
    return Column(
      children: [
        _buildTableHeader(),
        ...List.generate(8, (_) => const TableRowShimmer()),
      ],
    );
  }

  Widget _buildMobileList() {
    final state = ref.watch(stationsProvider);

    if (state.isLoading) {
      return ListView(
        children: List.generate(5, (_) => const StationCardShimmer()),
      );
    }

    if (state.stations.isEmpty) {
      return EmptyState(
        icon: Icons.layers_outlined,
        title: 'No stations found',
        description: state.searchQuery.isNotEmpty
            ? 'No stations match your search.'
            : 'Tap the + button to add your first station.',
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(stationsProvider.notifier).loadStations(refresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount:
            state.stations.length + (state.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.stations.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return StationCard(
            station: state.stations[index],
            onEdit: () => _openEditModal(state.stations[index]),
            onDelete: () => _confirmDelete(state.stations[index]),
          );
        },
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _openAddModal,
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Add Station'),
    );
  }
}

/// Hoverable table row with action buttons visible on hover.
class _HoverableTableRow extends StatefulWidget {
  final Station station;
  final bool isAlt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HoverableTableRow({
    required this.station,
    required this.isAlt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_HoverableTableRow> createState() => _HoverableTableRowState();
}

class _HoverableTableRowState extends State<_HoverableTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = _isHovered
        ? AppColors.tableRowHover
        : widget.isAlt
            ? AppColors.tableRowAlt
            : AppColors.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          border: const Border(
            bottom: BorderSide(color: AppColors.border),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Text(
                _formatId(widget.station.id),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.station.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.station.location,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${widget.station.capacity}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: StatusChip.fromStationStatus(widget.station.status),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${widget.station.scheduleCount}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: AnimatedOpacity(
                opacity: _isHovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Edit station',
                      child: IconButton(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: AppColors.accent,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Delete station',
                      child: IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        color: AppColors.danger,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  String _formatId(String id) {
    if (id.length >= 6) {
      return 'ST-${id.substring(0, 6).toUpperCase()}';
    }
    return 'ST-$id';
  }
}

/// Table header cell.
class _TableHeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _TableHeaderCell({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Small stat badge for the top bar.
class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
