import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/owner_models.dart';
import '../../../state/owner_state.dart';
import '../../widgets/owner_farm_header.dart';
import '../../widgets/owner_bottom_nav_bar.dart';
import '../../widgets/farmer_avatar_badge.dart';

class FarmersListScreen extends ConsumerStatefulWidget {
  const FarmersListScreen({super.key});

  @override
  ConsumerState<FarmersListScreen> createState() => _FarmersListScreenState();
}

class _FarmersListScreenState extends ConsumerState<FarmersListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final currentFilter = ref.watch(farmerFilterStatusProvider);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ফিল্টার নির্বাচন করুন',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('সকল কৃষক'),
                  trailing: currentFilter == FarmerFilterStatus.all
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    ref.read(farmerFilterStatusProvider.notifier).setFilter(FarmerFilterStatus.all);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('নিয়োজিত কৃষক'),
                  trailing: currentFilter == FarmerFilterStatus.assigned
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    ref.read(farmerFilterStatusProvider.notifier).setFilter(FarmerFilterStatus.assigned);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('অনিয়োজিত কৃষক'),
                  trailing: currentFilter == FarmerFilterStatus.unassigned
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    ref.read(farmerFilterStatusProvider.notifier).setFilter(FarmerFilterStatus.unassigned);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSortModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final currentSort = ref.watch(farmerSortOrderProvider);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'সাজানোর ক্রম',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('নতুন থেকে পুরানো'),
                  trailing: currentSort == FarmerSortOrder.newest
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    ref.read(farmerSortOrderProvider.notifier).setSort(FarmerSortOrder.newest);
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('পুরানো থেকে নতুন'),
                  trailing: currentSort == FarmerSortOrder.oldest
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    ref.read(farmerSortOrderProvider.notifier).setSort(FarmerSortOrder.oldest);
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _addNewFarmerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('নতুন কৃষক যোগ করুন'),
        content: const Text('নতুন কৃষক নিবন্ধন ফর্ম শীঘ্রই সংযুক্ত করা হবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ঠিক আছে', style: TextStyle(color: AppColors.primaryGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmers = ref.watch(filteredFarmersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Column(
        children: [
          // 1. Lush Header with Farm Scenery, Title and '+' Action
          _buildHeader(context),

          // 2. Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                // Search Input Field
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8E2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(farmerSearchQueryProvider.notifier).setQuery(val);
                      },
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'কৃষকের নাম, ফোন নম্বর বা এলাকা দিয়ে খুঁজুন...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Filter Button
                InkWell(
                  onTap: () => _showFilterModal(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFC8E6C9)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 18,
                          color: AppColors.primaryGreen,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'ফিল্টার',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.primaryGreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Count & Sort Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'মোট কৃষক ${DateFormatter.toBanglaDigits(farmers.length.toString())} জন',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                InkWell(
                  onTap: () => _showSortModal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8E2)),
                    ),
                    child: const Row(
                      children: [
                        Text(
                          'নতুন থেকে পুরানো',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Farmers List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(ownerFarmersListProvider.notifier).loadFarmers();
              },
              color: AppColors.primaryGreen,
              child: farmers.isEmpty
                  ? ListView(
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                          child: Center(
                            child: Text(
                              'কোনো কৃষক খুঁজে পাওয়া যায়নি',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: farmers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final farmer = farmers[index];
                        return _buildFarmerCard(context, farmer);
                      },
                    ),
            ),
          ),

          // 5. Bottom Navigation Bar (Tab 2: কৃষকরা active)
          const OwnerBottomNavBar(currentIndex: 2),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return OwnerFarmHeaderBackground(
      height: 155,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  IconButton(
                    onPressed: () => context.go('/owner-dashboard'),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),

                  // Title
                  const Text(
                    'কৃষকদের তালিকা',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  // Add Farmer (+) Button
                  InkWell(
                    onTap: () => _addNewFarmerDialog(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.primaryGreen,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'সকল কৃষকের বিবরণ ও বর্তমান অবস্থা',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFFE8F5E9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerCard(BuildContext context, FarmerItemModel farmer) {
    return InkWell(
      onTap: () {
        ref.read(selectedFarmerIdProvider.notifier).setFarmerId(farmer.id);
        context.go('/farmer-activity');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          children: [
            // Farmer Avatar Badge
            FarmerAvatarBadge.fromName(farmer.name, size: 52),
            const SizedBox(width: 14),

            // Name, Phone & Location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmer.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        farmer.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        farmer.region,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Badge: নিয়োজিত (Green) or অনিয়োজিত (Red)
            _buildStatusBadge(farmer.isAssigned),
            const SizedBox(width: 6),

            // Trailing Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isAssigned) {
    if (isAssigned) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F7ED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFB7EAD0)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 13,
              color: Color(0xFF1E8E3E),
            ),
            SizedBox(width: 4),
            Text(
              'নিয়োজিত',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E8E3E),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFDE8E8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF8B4B4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cancel_rounded,
              size: 13,
              color: Color(0xFFD93025),
            ),
            SizedBox(width: 4),
            Text(
              'অনিয়োজিত',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD93025),
              ),
            ),
          ],
        ),
      );
    }
  }
}
