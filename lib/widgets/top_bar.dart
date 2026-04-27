import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Top application bar for the dashboard.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userName;
  final String userInitials;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const TopBar({
    super.key,
    required this.title,
    required this.userName,
    required this.userInitials,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Title / breadcrumb
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // Search bar
          _SearchBar(),
          const SizedBox(width: 16),
          // Notification bell
          _NotificationButton(onTap: onNotificationTap),
          const SizedBox(width: 12),
          // User avatar
          _UserAvatar(
            initials: userInitials,
            name: userName,
            onTap: onAvatarTap,
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          SizedBox(width: 10),
          Icon(Icons.search, size: 16, color: AppColors.textMuted),
          SizedBox(width: 8),
          Text(
            'Search...',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _NotificationButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: const Icon(
            Icons.notifications_outlined,
            size: 22,
            color: AppColors.textSecondary,
          ),
          tooltip: 'Notifications',
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String initials;
  final String name;
  final VoidCallback? onTap;

  const _UserAvatar({
    required this.initials,
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.accent,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
