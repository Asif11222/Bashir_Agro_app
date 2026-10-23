import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../state/farmer_app_state.dart';

class FarmerBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const FarmerBottomNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTap,
  });

  void _handleItemTapped(BuildContext context, WidgetRef ref, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    switch (index) {
      case 0:
        if (currentIndex != 0) {
          context.go('/dashboard');
        }
        break;
      case 1:
        if (currentIndex != 1) {
          context.go('/new-task');
        }
        break;
      case 2:
        if (currentIndex != 2) {
          context.go('/notifications');
        }
        break;
      case 3:
        if (currentIndex != 3) {
          context.go('/profile');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationStateProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. আমার কাজ (Active Pill by default)
              _buildNavItem(
                context: context,
                ref: ref,
                index: 0,
                label: 'আমার কাজ',
                icon: Icons.assignment_turned_in_outlined,
                isSelected: currentIndex == 0,
              ),

              // 2. নতুন কাজ (Circular green + button)
              _buildAddNavItem(
                context: context,
                ref: ref,
                index: 1,
                label: 'নতুন কাজ',
                isSelected: currentIndex == 1,
              ),

              // 3. নোটিশ (Bell with unread dot badge)
              _buildNoticeNavItem(
                context: context,
                ref: ref,
                index: 2,
                label: 'নোটিশ',
                hasUnread: unreadCount > 0,
                isSelected: currentIndex == 2,
              ),

              // 4. প্রোফাইল
              _buildNavItem(
                context: context,
                ref: ref,
                index: 3,
                label: 'প্রোফাইল',
                icon: Icons.person_outline_rounded,
                isSelected: currentIndex == 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _handleItemTapped(context, ref, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 21,
                  color: const Color(0xFF006837),
                ),
              )
            else
              Icon(
                icon,
                size: 23,
                color: const Color(0xFF64748B),
              ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF006837) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required String label,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _handleItemTapped(context, ref, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006837),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      size: 19,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF006837),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF006837) : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticeNavItem({
    required BuildContext context,
    required WidgetRef ref,
    required int index,
    required String label,
    required bool hasUnread,
    required bool isSelected,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => _handleItemTapped(context, ref, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 23,
                  color: isSelected ? const Color(0xFF006837) : const Color(0xFF64748B),
                ),
                if (hasUnread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 7.5,
                      height: 7.5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF006837) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
