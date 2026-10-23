import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/owner_models.dart';
import '../../../state/owner_state.dart';
import '../../widgets/owner_bottom_nav_bar.dart';
import '../../widgets/farmer_avatar_badge.dart';
import '../../widgets/owner_farm_header.dart';

class FarmerActivityScreen extends ConsumerWidget {
  const FarmerActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmer = ref.watch(currentSelectedFarmerProvider);
    final selectedFilter = ref.watch(activityFilterTimeProvider);

    if (farmer == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7FAF7),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('কোনো কৃষক নির্বাচন করা হয়নি'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/farmers-list'),
                child: const Text('কৃষকদের তালিকায় ফিরে যান'),
              ),
            ],
          ),
        ),
      );
    }

    final activitiesAsync = ref.watch(farmerActivitiesProvider(farmer.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Column(
        children: [
          // 1. Curved Green Header with Profile Card Overlay
          _buildHeaderWithProfile(context, farmer),

          // 2. Timeline and Content
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () async {
                ref.invalidate(farmerActivitiesProvider(farmer.id));
                try {
                  await ref.read(farmerActivitiesProvider(farmer.id).future);
                } catch (_) {}
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    // Filter Tabs: আজকের, ৭ দিন, ৩০ দিন
                    _buildFilterTabs(ref, selectedFilter),
                    const SizedBox(height: 16),

                    // Connected Vertical Timeline with Real API Data
                    activitiesAsync.when(
                      data: (activities) {
                        final now = DateTime.now();
                        final begin = DateTime(now.year, now.month, now.day)
                            .subtract(
                              Duration(
                                days: selectedFilter == '৩০ দিন'
                                    ? 29
                                    : selectedFilter == '৭ দিন'
                                    ? 6
                                    : 0,
                              ),
                            );
                        final end = DateTime(now.year, now.month, now.day + 1);
                        final shown = activities.where((activity) {
                          final date = DateTime.tryParse(
                            activity.scheduledDate,
                          );
                          return date != null &&
                              !date.isBefore(begin) &&
                              date.isBefore(end);
                        }).toList();
                        if (shown.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 40,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE8ECE8),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$selectedFilter কোনো কার্যক্রম পাওয়া যায়নি।',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }
                        return _buildTimelineList(context, shown);
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'তথ্য লোড করতে সমস্যা হয়েছে: $err',
                          style: const TextStyle(color: AppColors.errorRed),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Navigation Bar (Tab 2: কৃষকরা active)
          const OwnerBottomNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildHeaderWithProfile(BuildContext context, FarmerItemModel farmer) {
    return Stack(
      children: [
        // Green Curved Header Top Banner with Scenery
        OwnerFarmHeaderBackground(
          height: OwnerFarmHeaderBackground.standardHeight,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.go('/farmers-list'),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Expanded(
                    child: Text(
                      'কৃষকের কার্যক্রম',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating Profile Card with proper bottom clearance
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 144, 16, 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FarmerAvatarBadge.fromName(farmer.name, size: 54),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farmer.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            farmer.phone.isNotEmpty
                                ? farmer.phone
                                : 'ফোন নম্বর সংযুক্ত নেই',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 2),
                              Flexible(
                                child: Text(
                                  farmer.region,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: farmer.isAssigned
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: farmer.isAssigned
                              ? const Color(0xFFC8E6C9)
                              : const Color(0xFFFFE0B2),
                        ),
                      ),
                      child: Text(
                        farmer.isAssigned ? 'নিয়োজিত' : 'অনিয়োজিত',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: farmer.isAssigned
                              ? AppColors.primaryGreen
                              : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F1)),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _buildStatItem(
                      'জমি এলাকা',
                      farmer.landArea > 0
                          ? '${farmer.landArea} একর'
                          : 'তথ্য নেই',
                    ),
                    _buildStatItem('মূল কার্যক্রম', farmer.farmType),
                    _buildStatItem('অগ্রগতি', '${farmer.progressPercent}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(WidgetRef ref, String selectedFilter) {
    final tabs = ['আজকের', '৭ দিন', '৩০ দিন'];

    return Row(
      children: tabs.map((tab) {
        final isSelected = tab == selectedFilter;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                ref.read(activityFilterTimeProvider.notifier).setFilter(tab);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryGreen : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : const Color(0xFFE2E8E2),
                  ),
                ),
                child: Center(
                  child: Text(
                    tab,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineList(
    BuildContext context,
    List<FarmerActivityItemModel> activities,
  ) {
    return Column(
      children: List.generate(activities.length, (index) {
        final activity = activities[index];
        final isLast = index == activities.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getTimelineDotColor(activity),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          _getTimelineDotIcon(activity),
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2.5,
                          color: const Color(0xFF006837),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildActivityCard(context, activity),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Color _getTimelineDotColor(FarmerActivityItemModel activity) {
    return activity.isCompleted
        ? AppColors.primaryGreen
        : const Color(0xFF94A3B8);
  }

  IconData _getTimelineDotIcon(FarmerActivityItemModel activity) {
    return activity.isCompleted
        ? Icons.check_rounded
        : Icons.schedule_rounded;
  }

  Color _getBadgeBgColor(FarmerActivityItemModel activity) {
    return activity.isCompleted
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFFF3E0);
  }

  Color _getBadgeTextColor(FarmerActivityItemModel activity) {
    return activity.isCompleted
        ? AppColors.primaryGreen
        : const Color(0xFFE65100);
  }

  Widget _buildActivityCard(
    BuildContext context,
    FarmerActivityItemModel activity,
  ) {
    return InkWell(
      onTap: () => context.push('/owner-photo-details/${activity.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8ECE8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 72,
                height: 72,
                child: activity.photoUrls.isNotEmpty
                    ? Image.network(
                        activity.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      )
                    : Container(
                        color: const Color(0xFFE9F5ED),
                        child: const Icon(
                          Icons.grass_rounded,
                          color: AppColors.primaryGreen,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getBadgeBgColor(activity),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          activity.statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getBadgeTextColor(activity),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          activity.time,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          activity.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (activity.isCompleted) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (OwnerWorkStatus.verificationLabel(
                              activity.geofencePassed,
                              activity.isLate,
                            ) !=
                            null)
                          _activityBadge(
                            OwnerWorkStatus.verificationLabel(
                              activity.geofencePassed,
                              activity.isLate,
                            )!,
                          ),
                        if (activity.geofencePassed != null)
                          _activityBadge(
                            activity.geofencePassed!
                                ? 'সঠিক লোকেশনে'
                                : 'লোকেশনের বাইরে',
                          ),
                        if (activity.isLate != null)
                          _activityBadge(
                            activity.isLate! ? 'সময় পেরিয়েছে' : 'সময়ের মধ্যে',
                          ),
                        _activityBadge('${activity.photoUrls.length}টি ছবি'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityBadge(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color:
          text.contains('সমস্যা') ||
              text.contains('বাইরে') ||
              text.contains('পেরিয়েছে')
          ? const Color(0xFFFEE2E2)
          : const Color(0xFFDCFCE7),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
    ),
  );
}
