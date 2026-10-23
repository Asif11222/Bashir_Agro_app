import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/owner_bottom_nav_bar.dart';
import '../../widgets/owner_farm_header.dart';

class OwnerPhotoDetailsScreen extends ConsumerWidget {
  const OwnerPhotoDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: Column(
        children: [
          // 1. Curved Green Header
          _buildHeader(context),

          // 2. Scrollable Photo & Geofence Details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Photo (Farmer Spraying Field)
                  _buildHeroPhoto(),
                  const SizedBox(height: 12),

                  // "সঠিক অবস্থান" Verification Status Card
                  _buildStatusVerificationCard(),
                  const SizedBox(height: 12),

                  // Date and Time (2-Column Cards)
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.calendar_today_rounded,
                          iconColor: const Color(0xFF1E8E3E),
                          iconBgColor: const Color(0xFFE6F4EA),
                          label: 'তোলার তারিখ',
                          value: DateFormatter.formatFullDateWithDay().split(',').first.trim(),
                          subValue: DateFormatter.formatFullDateWithDay().contains(',')
                              ? DateFormatter.formatFullDateWithDay().split(',').last.trim()
                              : 'আজকের দিন',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.access_time_rounded,
                          iconColor: const Color(0xFFE37400),
                          iconBgColor: const Color(0xFFFEF7E0),
                          label: 'তোলার সময়',
                          value: 'সকাল ৮:২৪',
                          subValue: '(GMT+6)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // GPS Coordinates Card
                  _buildGpsCard(),
                  const SizedBox(height: 12),

                  // Satellite Map Geofence Preview Card
                  _buildGeofenceMapCard(),
                  const SizedBox(height: 12),

                  // Verification Timestamp Footer Card
                  _buildVerificationFooterCard(),
                  const SizedBox(height: 16),
                ],
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
      height: 150,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/farmer-activity'),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'ছবির বিস্তারিত',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.only(left: 40),
                child: Text(
                  'কাজের ছবি ও সঠিক অবস্থান যাচাই',
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


  Widget _buildHeroPhoto() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.asset(
            'assets/images/farmer_spraying.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFC8E6C9),
              child: const Center(
                child: Icon(Icons.photo_camera_rounded, size: 48, color: AppColors.primaryGreen),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusVerificationCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF1E8E3E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'সঠিক অবস্থান',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E8E3E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ছবিটি নির্ধারিত খামার এলাকার ভেতরেই তোলা হয়েছে।',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String label,
    required String value,
    required String subValue,
  }) {
    return Container(
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
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subValue,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
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
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'জিপিএস লোকেশন',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '23.8103° N, 90.4125° E',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'মুন্সীগঞ্জ খামার, সদর, ঢাকা',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeofenceMapCard() {
    return Container(
      height: 175,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD1EED8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Satellite Aerial Image
            Image.asset(
              'assets/images/farm_satellite_map.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF2E7D32),
              ),
            ),

            // Polygonal Geofence Boundary Overlay
            CustomPaint(
              painter: _GeofencePolygonPainter(),
            ),

            // Top Floating Tag: "🏠 নির্ধারিত খামার এলাকা"
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.home_work_rounded,
                        size: 14,
                        color: Color(0xFF006837),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'নির্ধারিত খামার এলাকা',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006837),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Center Pin Marker
            Center(
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF006837),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationFooterCard() {
    return Container(
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
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.gps_fixed_rounded,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'যাচাই সম্পন্ন',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E8E3E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ছবিটির লোকেশন আমাদের খামার এলাকার সাথে মিলেছে।',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text(
                'যাচাইয়ের সময়',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
              ),
              SizedBox(height: 2),
              Text(
                '১২ মার্চ ২০২৪, সকাল ৮:২৫',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeofencePolygonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Polygon boundary points
    final path = Path()
      ..moveTo(w * 0.20, h * 0.30)
      ..lineTo(w * 0.72, h * 0.35)
      ..lineTo(w * 0.65, h * 0.85)
      ..lineTo(w * 0.22, h * 0.75)
      ..close();

    // Translucent Green Fill
    final fillPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Glowing Green Solid Border
    final glowPaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, glowPaint);

    // White dashed inner border
    final whiteBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, whiteBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
