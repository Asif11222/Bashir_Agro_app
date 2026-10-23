import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/owner_models.dart';
import '../../../state/owner_state.dart';
import '../../widgets/owner_bottom_nav_bar.dart';
import '../../widgets/owner_farm_header.dart';

class OwnerLocationsListScreen extends ConsumerStatefulWidget {
  const OwnerLocationsListScreen({super.key});

  @override
  ConsumerState<OwnerLocationsListScreen> createState() => _OwnerLocationsListScreenState();
}

class _OwnerLocationsListScreenState extends ConsumerState<OwnerLocationsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(ownerLocationsListProvider.notifier).reload();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onOpenLocationMap(OwnerLocationItem location) {
    ref.read(selectedLocationForMapProvider.notifier).setLocation(location);
    context.push('/location-map');
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(ownerLocationsListProvider);
    final filteredLocations = ref.watch(filteredOwnerLocationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Column(
        children: [
          // 1. Lush Green Header
          _buildHeader(context),

          // 2. Main Scrollable Content
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () async {
                await ref.read(ownerLocationsListProvider.notifier).reload();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search & Filter Box
                    _buildSearchBar(),
                    const SizedBox(height: 14),

                    // Locations Count / Summary Banner
                    _buildSummaryBanner(filteredLocations.length),
                    const SizedBox(height: 14),

                    // Locations List or Loading / Empty States
                    locationsAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryGreen),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.errorRed),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'লোকেশন তথ্য লোড করা যায়নি: $err',
                                style: const TextStyle(fontSize: 13, color: AppColors.errorRed),
                              ),
                            ),
                          ],
                        ),
                      ),
                      data: (_) {
                        if (filteredLocations.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8ECE8)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.location_off_rounded,
                                  size: 44,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchController.text.isNotEmpty
                                      ? 'এই নামে কোনো লোকেশন খুঁজে পাওয়া যায়নি।'
                                      : 'অ্যাডমিন প্যানেলে এখনও কোনো লোকেশন যুক্ত করা হয়নি।',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filteredLocations.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final location = filteredLocations[index];
                            return _buildLocationCard(context, location);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Bottom Navigation Bar (Tab 3: লোকেশন active)
          const OwnerBottomNavBar(currentIndex: 3),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return OwnerFarmHeaderBackground(
      height: 140,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(width: 8),

              // Location Pin Icon Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'খামারের লোকেশনসমূহ',
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'অ্যাডমিন প্যানেলে যুক্ত সকল প্লট ও জমি',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFE8F5E9),
                      ),
                    ),
                  ],
                ),
              ),

              // Map Preview Quick Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8E2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          ref.read(locationSearchQueryProvider.notifier).setQuery(val);
        },
        decoration: InputDecoration(
          hintText: 'লোকেশন, কোড বা ফসল অনুসন্ধান করুন...',
          hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGreen, size: 22),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(locationSearchQueryProvider.notifier).clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSummaryBanner(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1EED8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18),
          const SizedBox(width: 8),
          Text(
            'মোট ${DateFormatter.toBanglaDigits(count.toString())}টি লোকেশন সক্রিয় রয়েছে',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, OwnerLocationItem location) {
    Color typeBg;
    Color typeFg;
    IconData typeIcon;

    if (location.type.contains('সবজি')) {
      typeBg = const Color(0xFFE8F5E9);
      typeFg = const Color(0xFF2E7D32);
      typeIcon = Icons.eco_rounded;
    } else if (location.type.contains('ধান')) {
      typeBg = const Color(0xFFFFF8E1);
      typeFg = const Color(0xFFF57F17);
      typeIcon = Icons.grass_rounded;
    } else if (location.type.contains('পুকুর') || location.type.contains('মাছ')) {
      typeBg = const Color(0xFFE1F5FE);
      typeFg = const Color(0xFF0288D1);
      typeIcon = Icons.water_drop_rounded;
    } else {
      typeBg = const Color(0xFFF1F5F9);
      typeFg = const Color(0xFF475569);
      typeIcon = Icons.place_rounded;
    }

    final lat = location.latitude;
    final lng = location.longitude;
    final coordsText = (lat != null && lng != null)
        ? '${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E'
        : 'স্থানাঙ্ক নির্ধারিত নেই';

    return InkWell(
      onTap: () => _onOpenLocationMap(location),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EBE5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Name, Location Code, and Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Type Icon Circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: typeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: typeFg, size: 20),
                ),
                const SizedBox(width: 12),

                // Name & Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              location.locationCode,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            location.type,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: typeFg,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Map navigation indicator chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.map_rounded, size: 14, color: AppColors.primaryGreen),
                      SizedBox(width: 4),
                      Text(
                        'মানচিত্র',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),

            // Metadata Grid / Badges: Address, Area, Coordinates
            Row(
              children: [
                const Icon(Icons.pin_drop_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    location.address,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (location.area != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'আয়তন: ${location.formattedArea}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 6),

            // Coordinates & Boundary status
            Row(
              children: [
                const Icon(Icons.gps_fixed_rounded, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 5),
                Text(
                  coordsText,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontFamily: 'monospace',
                    color: Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.polyline_rounded, size: 14, color: Color(0xFF006837)),
                const SizedBox(width: 4),
                const Text(
                  'সীমানা প্রস্তুত',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF006837),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
