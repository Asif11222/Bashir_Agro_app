import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/farmer_app_state.dart';
import '../../widgets/farm_graphics.dart';
import '../../widgets/farmer_bottom_nav_bar.dart';

class FarmerProfileScreen extends ConsumerWidget {
  const FarmerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(farmerAuthProvider);
    final user = authState.user;
    final profile = authState.profile;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text(
          'কৃষক প্রোফাইল',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'লগআউট',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('লগআউট নিশ্চিতকরণ'),
                  content: const Text('আপনি কি নিশ্চিতভাবে লগআউট করতে চান?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('না'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('হ্যাঁ, লগআউট করুন', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(farmerAuthProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
            children: [
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const FarmerAvatar(size: 80),
                    const SizedBox(height: 12),
                    Text(
                      profile?.fullName ?? user?.name ?? 'কৃষক',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.badgeTodayBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'আইডি: ${profile?.farmerCode ?? "-"}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      profile?.primaryActivity ?? 'ফার্মিং কার্যক্রম',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Personal Information Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline_rounded, color: AppColors.primaryGreen),
                        SizedBox(width: 8),
                        Text(
                          'ব্যক্তিগত তথ্য (Profile Info)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildInfoRow('মোবাইল নম্বর', profile?.phone ?? user?.phone ?? '-'),
                    _buildInfoRow('জাতীয় পরিচয়পত্র (NID)', profile?.nid ?? 'তথ্য পাওয়া যায়নি'),
                    _buildInfoRow('অভিজ্ঞতা', profile?.experienceYears != null ? '${profile!.experienceYears} বছর' : 'তথ্য নেই'),
                    _buildInfoRow('ঠিকানা', profile?.address ?? 'তথ্য পাওয়া যায়নি'),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Emergency Contact Box (Shown only if available)
              if (profile?.emergencyContact != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.contact_phone_outlined, color: AppColors.primaryGreen),
                          SizedBox(width: 8),
                          Text(
                            'জরুরি যোগাযোগ (Emergency Contact)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('নাম', profile?.emergencyContact?.name ?? '-'),
                      _buildInfoRow('সম্পর্ক', profile?.emergencyContact?.relationship ?? '-'),
                      _buildInfoRow('মোবাইল নম্বর', profile?.emergencyContact?.phone ?? '-'),
                    ],
                  ),
                ),

              const SizedBox(height: 18),

              // App Version & Organization Footer
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'বশির এগ্রো ফার্ম লিমিটেড',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ভার্সন ১.০.৯ (Bashir Agro Farmer App)',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 20),
            ],
          ),
        ),
      bottomNavigationBar: const FarmerBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
