import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../providers/schedule_provider.dart';
import '../utils/app_colors.dart';
import '../utils/breakpoints.dart';
import '../widgets/schedule/weekly_grid_view.dart';
import '../widgets/schedule/day_view.dart';
import '../widgets/schedule/schedule_list_view.dart';
import '../widgets/schedule/assignment_panel.dart';
import '../widgets/schedule/new_shift_dialog.dart';
import '../widgets/common/loading_shimmer.dart';
import '../widgets/common/error_banner.dart';

/// Main scheduling screen with week/day/list views
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.keyN) {
        _openNewShiftDialog();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        ref.read(assignmentPanelProvider.notifier).close();
      }
    }
  }

  void _openNewShiftDialog() {
    showDialog(
      context: context,
      builder: (_) => const NewShiftDialog(),
    );
  }

  void _navigateWeek(int direction) {
    final current = ref.read(selectedWeekProvider);
    ref.read(selectedWeekProvider.notifier).state =
        current.add(Duration(days: 7 * direction));
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(scheduleViewModeProvider);
    final selectedWeek = ref.watch(selectedWeekProvider);
    final panelState = ref.watch(assignmentPanelProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= Breakpoints.desktop;
    final isTablet = width >= Breakpoints.tablet;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Row(
          children: [
            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _ScheduleHeader(
                    viewMode: viewMode,
                    selectedWeek: selectedWeek,
                    isDesktop: isDesktop,
                    isTablet: isTablet,
                    onPrevWeek: () => _navigateWeek(-1),
                    onNextWeek: () => _navigateWeek(1),
                    onNewShift: _openNewShiftDialog,
                    onViewModeChanged: (mode) {
                      ref.read(scheduleViewModeProvider.notifier).state = mode;
                    },
                  ),
                  // Content
                  Expanded(
                    child: _buildContent(viewMode, isDesktop, isTablet),
                  ),
                ],
              ),
            ),
            // Assignment panel (desktop slide-in)
            if (isDesktop && panelState.isOpen)
              AssignmentPanel(
                schedule: panelState.selectedSchedule!,
                onClose: () =>
                    ref.read(assignmentPanelProvider.notifier).close(),
              ),
          ],
        ),
        // Mobile FAB
        floatingActionButton: !isDesktop
            ? FloatingActionButton(
                onPressed: _openNewShiftDialog,
                backgroundColor: AppColors.accent,
                tooltip: 'New Shift (N)',
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        // Mobile assignment panel as bottom sheet
        bottomSheet: !isDesktop && panelState.isOpen
            ? _MobileAssignmentSheet(
                schedule: panelState.selectedSchedule!,
                onClose: () =>
                    ref.read(assignmentPanelProvider.notifier).close(),
              )
            : null,
      ),
    );
  }

  Widget _buildContent(
    ScheduleViewMode viewMode,
    bool isDesktop,
    bool isTablet,
  ) {
    switch (viewMode) {
      case ScheduleViewMode.week:
        return WeeklyGridView(isDesktop: isDesktop, isTablet: isTablet);
      case ScheduleViewMode.day:
        return DayView(isDesktop: isDesktop);
      case ScheduleViewMode.list:
        return ScheduleListView(isDesktop: isDesktop);
    }
  }
}

// ---------------------------------------------------------------------------
// Schedule Header
// ---------------------------------------------------------------------------
class _ScheduleHeader extends StatelessWidget {
  final ScheduleViewMode viewMode;
  final DateTime selectedWeek;
  final bool isDesktop;
  final bool isTablet;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onNewShift;
  final ValueChanged<ScheduleViewMode> onViewModeChanged;

  const _ScheduleHeader({
    required this.viewMode,
    required this.selectedWeek,
    required this.isDesktop,
    required this.isTablet,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onNewShift,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final weekEnd = selectedWeek.add(const Duration(days: 6));
    final weekLabel =
        'Week of ${DateFormat('MMM d').format(selectedWeek)} – ${DateFormat('MMM d, yyyy').format(weekEnd)}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24 : 16,
        vertical: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: isDesktop
          ? _DesktopHeader(
              weekLabel: weekLabel,
              viewMode: viewMode,
              onPrevWeek: onPrevWeek,
              onNextWeek: onNextWeek,
              onNewShift: onNewShift,
              onViewModeChanged: onViewModeChanged,
            )
          : _MobileHeader(
              weekLabel: weekLabel,
              viewMode: viewMode,
              onPrevWeek: onPrevWeek,
              onNextWeek: onNextWeek,
              onNewShift: onNewShift,
              onViewModeChanged: onViewModeChanged,
            ),
    );
  }
}

class _DesktopHeader extends StatelessWidget {
  final String weekLabel;
  final ScheduleViewMode viewMode;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onNewShift;
  final ValueChanged<ScheduleViewMode> onViewModeChanged;

  const _DesktopHeader({
    required this.weekLabel,
    required this.viewMode,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onNewShift,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Week navigation
        Row(
          children: [
            Text(
              weekLabel,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            _NavButton(
              icon: Icons.chevron_left,
              onTap: onPrevWeek,
              tooltip: 'Previous week',
            ),
            const SizedBox(width: 4),
            _NavButton(
              icon: Icons.chevron_right,
              onTap: onNextWeek,
              tooltip: 'Next week',
            ),
          ],
        ),
        const Spacer(),
        // View mode toggle
        _ViewModeToggle(
          viewMode: viewMode,
          onChanged: onViewModeChanged,
        ),
        const SizedBox(width: 16),
        // New shift button
        ElevatedButton.icon(
          onPressed: onNewShift,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New Shift'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  final String weekLabel;
  final ScheduleViewMode viewMode;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onNewShift;
  final ValueChanged<ScheduleViewMode> onViewModeChanged;

  const _MobileHeader({
    required this.weekLabel,
    required this.viewMode,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onNewShift,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                weekLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _NavButton(
              icon: Icons.chevron_left,
              onTap: onPrevWeek,
              tooltip: 'Previous week',
            ),
            _NavButton(
              icon: Icons.chevron_right,
              onTap: onNextWeek,
              tooltip: 'Next week',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _ViewModeToggle(
          viewMode: viewMode,
          onChanged: onViewModeChanged,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 18, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  final ScheduleViewMode viewMode;
  final ValueChanged<ScheduleViewMode> onChanged;

  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'Week',
            isSelected: viewMode == ScheduleViewMode.week,
            onTap: () => onChanged(ScheduleViewMode.week),
            isFirst: true,
          ),
          _ToggleButton(
            label: 'Day',
            isSelected: viewMode == ScheduleViewMode.day,
            onTap: () => onChanged(ScheduleViewMode.day),
          ),
          _ToggleButton(
            label: 'List',
            isSelected: viewMode == ScheduleViewMode.list,
            onTap: () => onChanged(ScheduleViewMode.list),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? const Radius.circular(7) : Radius.zero,
            right: isLast ? const Radius.circular(7) : Radius.zero,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile assignment bottom sheet wrapper
// ---------------------------------------------------------------------------
class _MobileAssignmentSheet extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onClose;

  const _MobileAssignmentSheet({
    required this.schedule,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: AssignmentPanel(
        schedule: schedule,
        onClose: onClose,
        isMobile: true,
      ),
    );
  }
}
