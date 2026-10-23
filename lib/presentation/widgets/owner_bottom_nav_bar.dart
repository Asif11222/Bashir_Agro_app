import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../state/farmer_app_state.dart';
import '../../state/owner_state.dart';

class OwnerBottomNavBar extends ConsumerWidget {
  final int currentIndex;

  const OwnerBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, WidgetRef ref, int index) {
    ref.read(ownerNavIndexProvider.notifier).setIndex(index);

    switch (index) {
      case 0:
        context.go('/owner-dashboard');
        break;
      case 1:
        context.go('/owner-tasks');
        break;
      case 2:
        context.go('/farmers-list');
        break;
      case 3:
        context.go('/locations-list');
        break;
      case 4:
        _showSettingsBottomSheet(context, ref);
        break;
    }
  }

  void _showSettingsBottomSheet(BuildContext context, WidgetRef ref) {
    final user = ref.watch(farmerAuthProvider).user;
    final userName = user?.name.isNotEmpty == true ? user!.name : 'খামার মালিক';
    final userPhone = user?.phone ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppColors.primaryGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (userPhone.isNotEmpty)
                          Text(
                            userPhone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.map_rounded, color: AppColors.primaryGreen),
                  title: const Text('খামারের সীমানা ও মানচিত্র'),
                  subtitle: const Text('স্যাটেলাইট ভিউ ও জিপিএস বাউন্ডারি দেখুন'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/field-boundary');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
                  title: const Text('লগআউট করুন'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(farmerAuthProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = [
      _NavItemData(icon: Icons.home_rounded, label: 'ড্যাশবোর্ড'),
      _NavItemData(icon: Icons.assignment_outlined, label: 'কাজসমূহ'),
      _NavItemData(icon: Icons.people_alt_outlined, label: 'কৃষকরা'),
      _NavItemData(icon: Icons.location_on_outlined, label: 'লোকেশন'),
      _NavItemData(icon: Icons.settings_outlined, label: 'সেটিংস'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
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
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              final item = items[index];

              return InkWell(
                onTap: () => _onItemTapped(context, ref, index),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 24,
                        color: isSelected ? AppColors.primaryGreen : const Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primaryGreen : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  _NavItemData({required this.icon, required this.label});
}
