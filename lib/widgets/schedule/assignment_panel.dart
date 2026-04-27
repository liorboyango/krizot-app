import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/schedule.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../services/schedule_service.dart';

/// Slide-in assignment panel for assigning staff to a shift
class AssignmentPanel extends ConsumerStatefulWidget {
  final Schedule schedule;
  final VoidCallback onClose;
  final bool isMobile;

  const AssignmentPanel({
    super.key,
    required this.schedule,
    required this.onClose,
    this.isMobile = false,
  });

  @override
  ConsumerState<AssignmentPanel> createState() => _AssignmentPanelState();
}

class _AssignmentPanelState extends ConsumerState<AssignmentPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  final _searchController = TextEditingController();
  List<UserInfo> _staffList = [];
  List<UserInfo> _filteredStaff = [];
  bool _isLoadingStaff = false;
  String? _staffError;
  String? _assigningUserId;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
    _loadStaff();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoadingStaff = true;
      _staffError = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/users');
      final data = response.data as Map<String, dynamic>;
      if (data['success'] == true) {
        final users = (data['data'] as List<dynamic>)
            .map((u) => UserInfo.fromJson(u as Map<String, dynamic>))
            .toList();
        setState(() {
          _staffList = users;
          _filteredStaff = users;
          _isLoadingStaff = false;
        });
      } else {
        setState(() {
          _staffError = data['error']?['message'] ?? 'Failed to load staff';
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      setState(() {
        _staffError = 'Could not load staff list';
        _isLoadingStaff = false;
        // Use mock data as fallback for demo
        _staffList = _mockStaff();
        _filteredStaff = _mockStaff();
      });
    }
  }

  List<UserInfo> _mockStaff() {
    return [
      const UserInfo(id: '1', name: 'J. Cohen', email: 'j.cohen@krizot.com'),
      const UserInfo(id: '2', name: 'R. Levi', email: 'r.levi@krizot.com'),
      const UserInfo(id: '3', name: 'A. Mizrahi', email: 'a.mizrahi@krizot.com'),
      const UserInfo(id: '4', name: 'M. Shapiro', email: 'm.shapiro@krizot.com'),
    ];
  }

  void _filterStaff(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStaff = _staffList;
      } else {
        _filteredStaff = _staffList
            .where((u) =>
                u.name.toLowerCase().contains(query.toLowerCase()) ||
                u.email.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _assignUser(UserInfo user) async {
    setState(() => _assigningUserId = user.id);
    try {
      await ref
          .read(schedulesListProvider.notifier)
          .assignUser(widget.schedule.id, user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} assigned successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Assignment failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _assigningUserId = null);
    }
  }

  Future<void> _unassignUser() async {
    setState(() => _assigningUserId = 'unassign');
    try {
      await ref
          .read(schedulesListProvider.notifier)
          .unassignUser(widget.schedule.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff unassigned'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Unassign failed: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _assigningUserId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.schedule;

    final panel = Container(
      width: widget.isMobile ? double.infinity : 380,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: widget.isMobile
            ? null
            : const Border(
                left: BorderSide(color: AppColors.border),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          _PanelHeader(
            schedule: s,
            onClose: widget.onClose,
            isMobile: widget.isMobile,
          ),
          const Divider(height: 1, color: AppColors.border),
          // Current assignment
          if (s.user != null) _CurrentAssignment(user: s.user!, onUnassign: _unassignUser),
          // Search staff
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterStaff,
              decoration: InputDecoration(
                hintText: 'Search staff...',
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
          // Staff list
          Expanded(
            child: _isLoadingStaff
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
                  )
                : _staffError != null && _filteredStaff.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.danger,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _staffError!,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadStaff,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredStaff.isEmpty
                        ? const Center(
                            child: Text(
                              'No staff found',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredStaff.length,
                            itemBuilder: (context, i) {
                              final user = _filteredStaff[i];
                              final isCurrentlyAssigned =
                                  s.userId == user.id;
                              final isAssigning =
                                  _assigningUserId == user.id;
                              return _StaffListItem(
                                user: user,
                                isCurrentlyAssigned: isCurrentlyAssigned,
                                isAssigning: isAssigning,
                                onAssign: isCurrentlyAssigned
                                    ? null
                                    : () => _assignUser(user),
                              );
                            },
                          ),
          ),
        ],
      ),
    );

    if (widget.isMobile) return panel;

    return SlideTransition(
      position: _slideAnimation,
      child: panel,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onClose;
  final bool isMobile;

  const _PanelHeader({
    required this.schedule,
    required this.onClose,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign Staff',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${schedule.station?.name ?? 'Station'} • ${schedule.shiftTimeLabel}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: onClose,
                color: AppColors.textSecondary,
                tooltip: 'Close (Esc)',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentAssignment extends StatelessWidget {
  final UserInfo user;
  final VoidCallback onUnassign;

  const _CurrentAssignment({
    required this.user,
    required this.onUnassign,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.shiftCovered,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Text(
                  'Currently assigned',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onUnassign,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            child: const Text(
              'Unassign',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffListItem extends StatefulWidget {
  final UserInfo user;
  final bool isCurrentlyAssigned;
  final bool isAssigning;
  final VoidCallback? onAssign;

  const _StaffListItem({
    required this.user,
    required this.isCurrentlyAssigned,
    required this.isAssigning,
    this.onAssign,
  });

  @override
  State<_StaffListItem> createState() => _StaffListItemState();
}

class _StaffListItemState extends State<_StaffListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: widget.isCurrentlyAssigned
              ? AppColors.shiftCovered
              : _hovered
                  ? AppColors.background
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isCurrentlyAssigned
                ? AppColors.success.withOpacity(0.3)
                : _hovered
                    ? AppColors.border
                    : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.user.initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Name & email
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    widget.user.email,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Assign button
            if (widget.isCurrentlyAssigned)
              const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.success,
              )
            else if (widget.isAssigning)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            else
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 150),
                child: ElevatedButton(
                  onPressed: widget.onAssign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: const Size(60, 30),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Assign'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
