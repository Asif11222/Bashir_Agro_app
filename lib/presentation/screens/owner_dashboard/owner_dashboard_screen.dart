import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/owner_models.dart';
import '../../../state/app_state.dart';
import '../../../state/farmer_app_state.dart';
import '../../../state/owner_state.dart';
import '../../widgets/owner_farm_header.dart';
import '../../widgets/owner_bottom_nav_bar.dart';
import '../../widgets/farmer_avatar_badge.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen>
    with WidgetsBindingObserver {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(ownerDashboardProvider.notifier).loadDashboard(date: _selectedDate);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      ref.read(ownerDashboardProvider.notifier).loadDashboard(date: picked);
    }
  }

  void _pickLocation(List<OwnerLocationItem> locations, OwnerLocationItem? currentLocation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'লোকেশন নির্বাচন করুন',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('সব লোকেশন'),
                  trailing: currentLocation == null
                      ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    ref.read(ownerDashboardProvider.notifier).loadDashboard(clearLocation: true);
                    Navigator.pop(ctx);
                  },
                ),
                ...locations.map((loc) => ListTile(
                      title: Text(loc.name),
                      trailing: currentLocation?.id == loc.id
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen)
                          : null,
                      onTap: () {
                        ref.read(ownerDashboardProvider.notifier).loadDashboard(location: loc);
                        Navigator.pop(ctx);
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(ownerDashboardProvider);
    final kpis = dashState.kpis;
    final farmers = dashState.farmers;
    final locations = dashState.locations;
    final selectedLocation = dashState.selectedLocation;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(ownerDashboardProvider.notifier).loadDashboard();
              },
              color: AppColors.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Lush Green Header with Dynamic User Name
                    _buildHeader(context),

                    // 2. Date and Location Filter Pills
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 11,
                            child: _buildFilterPill(
                              icon: Icons.calendar_today_outlined,
                              iconColor: AppColors.primaryGreen,
                              text: DateFormatter.formatTodayDate(date: _selectedDate),
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 9,
                            child: _buildFilterPill(
                              icon: Icons.location_on_rounded,
                              iconColor: AppColors.primaryGreen,
                              text: selectedLocation?.name ?? 'সব লোকেশন',
                              onTap: () => _pickLocation(locations, selectedLocation),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Four Metric Cards (2x2 Grid)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  title: 'মোট কৃষক',
                                  count: '${DateFormatter.toBanglaDigits(kpis.totalFarmers.toString())} জন',
                                  subText: '+${DateFormatter.toBanglaDigits(kpis.newFarmersThisMonth.toString())} জন (এই মাসে)',
                                  subTextColor: const Color(0xFF1E8E3E),
                                  icon: Icons.people_alt_rounded,
                                  iconColor: const Color(0xFF1E8E3E),
                                  iconBgColor: const Color(0xFFE6F4EA),
                                  cardBgColor: const Color(0xFFF4FAF6),
                                  onTap: () => context.go('/farmers-list'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  title: 'আজকের কাজ',
                                  count: '${DateFormatter.toBanglaDigits(kpis.todayTasks.toString())} টি',
                                  subText: 'মোট নির্ধারিত কাজ',
                                  subTextColor: const Color(0xFF5F6368),
                                  icon: Icons.assignment_rounded,
                                  iconColor: const Color(0xFF1A73E8),
                                  iconBgColor: const Color(0xFFE8F0FE),
                                  cardBgColor: const Color(0xFFF3F9FD),
                                  onTap: () => context.go('/owner-tasks'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  title: 'সম্পন্ন কাজ',
                                  count: '${DateFormatter.toBanglaDigits(kpis.completedTasks.toString())} টি',
                                  subText: '${DateFormatter.toBanglaDigits(kpis.completionPercent.toString())}% সম্পন্ন',
                                  subTextColor: const Color(0xFF1E8E3E),
                                  icon: Icons.check_circle_rounded,
                                  iconColor: const Color(0xFF1E8E3E),
                                  iconBgColor: const Color(0xFFE6F4EA),
                                  cardBgColor: const Color(0xFFF4FAF6),
                                  onTap: () => context.go('/owner-tasks'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetricCard(
                                  title: 'বাকি কাজ',
                                  count: '${DateFormatter.toBanglaDigits(kpis.pendingTasks.toString())} টি',
                                  subText: kpis.todayTasks > 0
                                      ? '${DateFormatter.toBanglaDigits((100 - kpis.completionPercent).clamp(0, 100).toString())}% বাকি'
                                      : '০% বাকি',
                                  subTextColor: const Color(0xFFD93025),
                                  icon: Icons.access_time_filled_rounded,
                                  iconColor: const Color(0xFFE37400),
                                  iconBgColor: const Color(0xFFFEF7E0),
                                  cardBgColor: const Color(0xFFFDF6EE),
                                  onTap: () => context.go('/owner-tasks'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 4. "কৃষকদের অগ্রগতি" Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'কৃষকদের অগ্রগতি',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3026),
                            ),
                          ),
                          InkWell(
                            onTap: () => context.go('/farmers-list'),
                            child: const Row(
                              children: [
                                Text(
                                  'সব দেখুন',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                SizedBox(width: 3),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: AppColors.primaryGreen,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 5. Real Farmers Progress List
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE8ECE8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: dashState.isLoading && farmers.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: CircularProgressIndicator(color: AppColors.primaryGreen),
                                ),
                              )
                            : farmers.isEmpty
                                ? const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                                    child: Center(
                                      child: Text(
                                        'বর্তমানে এই ফিল্টারে কোনো কৃষক নির্ধারিত নেই।',
                                        style: TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: List.generate(
                                      farmers.length,
                                      (index) {
                                        final farmer = farmers[index];
                                        final isLast = index == farmers.length - 1;

                                        return Column(
                                          children: [
                                            _buildFarmerProgressTile(context, ref, farmer),
                                            if (!isLast)
                                              const Divider(height: 1, color: Color(0xFFF1F3F1)),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Navigation Bar
          const OwnerBottomNavBar(currentIndex: 0),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final authUser = ref.watch(farmerAuthProvider).user;
    final currentUser = ref.watch(currentUserProvider);
    final ownerName = (authUser?.name.isNotEmpty == true)
        ? authUser!.name
        : (currentUser?.name.isNotEmpty == true ? currentUser!.name : 'আব্দুল রহমান');

    return OwnerFarmHeaderBackground(
      height: 210,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'শুভ সকাল,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ownerName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'ফার্মের সব কার্যক্রম এক নজরে দেখুন',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFE8F5E9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bell Notification Icon
                  InkWell(
                    onTap: () => context.go('/notifications'),
                    borderRadius: BorderRadius.circular(21),
                    child: Container(
                      width: 42,
                      height: 42,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Owner Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: FarmerAvatarBadge.fromName(
                        ownerName,
                        size: 48,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5EBE5)),
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
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E35),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String count,
    required String subText,
    required Color subTextColor,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color cardBgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerProgressTile(
    BuildContext context,
    WidgetRef ref,
    FarmerItemModel farmer,
  ) {
    Color getProgressColor(int percent) {
      if (percent < 60) return const Color(0xFFF59E0B);
      return const Color(0xFF10B981);
    }

    IconData getFarmIcon(String farmType) {
      if (farmType.contains('মাছ')) return Icons.water_rounded;
      if (farmType.contains('গরু')) return Icons.pets_rounded;
      return Icons.eco_rounded;
    }

    Color getFarmIconColor(String farmType) {
      if (farmType.contains('মাছ')) return const Color(0xFF0288D1);
      if (farmType.contains('গরু')) return const Color(0xFF8D6E63);
      return const Color(0xFF2E7D32);
    }

    return InkWell(
      onTap: () {
        ref.read(selectedFarmerIdProvider.notifier).setFarmerId(farmer.id);
        context.go('/farmer-activity');
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Farmer Avatar
            FarmerAvatarBadge.fromName(farmer.name, size: 46),
            const SizedBox(width: 12),

            // Name & Region + Farm Type
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmer.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
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
                      const SizedBox(width: 8),
                      Icon(
                        getFarmIcon(farmer.farmType),
                        size: 13,
                        color: getFarmIconColor(farmer.farmType),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          farmer.farmType,
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

            // Progress Bar & Percentage
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${DateFormatter.toBanglaDigits(farmer.progressPercent.toString())}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: getProgressColor(farmer.progressPercent),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 72,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (farmer.progressPercent / 100.0).clamp(0.0, 1.0),
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        getProgressColor(farmer.progressPercent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
