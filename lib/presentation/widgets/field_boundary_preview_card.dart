import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/field_boundary_model.dart';
import 'field_boundary_map_widget.dart';

class FieldBoundaryPreviewCard extends StatelessWidget {
  final FieldBoundaryModel boundary;
  final String farmName;
  final String locationCode;
  final String farmType;
  final String formattedArea;
  final double? farmerLat;
  final double? farmerLng;
  final double? targetLat;
  final double? targetLng;
  final double gpsAccuracy;
  final bool isGpsAcquiring;
  final VoidCallback? onOpenFullMap;

  const FieldBoundaryPreviewCard({
    super.key,
    required this.boundary,
    this.farmName = 'দক্ষিণ মাঠ, ২ নং ব্লক',
    this.locationCode = 'LOC-001',
    this.farmType = 'সবজি ক্ষেত',
    this.formattedArea = '',
    this.farmerLat,
    this.farmerLng,
    this.targetLat,
    this.targetLng,
    this.gpsAccuracy = 5.0,
    this.isGpsAcquiring = false,
    this.onOpenFullMap,
  });

  @override
  Widget build(BuildContext context) {
    // Authoritative field boundary polygon
    final effectiveBoundary = boundary.isNotEmpty
        ? boundary
        : (targetLat != null && targetLng != null
            ? FieldBoundaryModel.fromCenterAndRadius(targetLat!, targetLng!, 40.0)
            : const FieldBoundaryModel(coordinates: []));

    final bool hasFarmerLocation = farmerLat != null && farmerLng != null;
    final bool isInside = hasFarmerLocation && effectiveBoundary.isNotEmpty
        ? effectiveBoundary.isPointInside(farmerLat!, farmerLng!, 20.0)
        : false;
    final double dist = hasFarmerLocation && effectiveBoundary.isNotEmpty
        ? effectiveBoundary.distanceToBoundaryMeters(farmerLat!, farmerLng!)
        : 0.0;

    final String noticeText;
    final Color noticeBg;
    final Color noticeBorder;
    final Color noticeTextColor;
    final IconData noticeIcon;

    if (!hasFarmerLocation) {
      noticeText = isGpsAcquiring
          ? 'মোবাইলের জিপিএস অবস্থান নির্ণয় করা হচ্ছে... অপেক্ষা করুন।'
          : 'জিপিএস তথ্য পাওয়া যায়নি। মোবাইলের লোকেশন সার্ভিস (GPS) চালু করুন।';
      noticeBg = const Color(0xFFFFFBEB);
      noticeBorder = const Color(0xFFFDE68A);
      noticeTextColor = const Color(0xFFB45309);
      noticeIcon = Icons.gps_not_fixed_rounded;
    } else if (isInside) {
      noticeText = 'আপনার জিপিএস অবস্থান নির্ধারিত মাঠের ভেতরে রয়েছে।';
      noticeBg = const Color(0xFFF1F8F4);
      noticeBorder = const Color(0xFFDCEDE0);
      noticeTextColor = AppColors.primaryDarkGreen;
      noticeIcon = Icons.check_circle_rounded;
    } else {
      final distStr = dist >= 1000
          ? '${(dist / 1000).toStringAsFixed(1)} কিমি'
          : '${dist.toStringAsFixed(0)} মিটার';
      noticeText = 'আপনি সীমানা থেকে $distStr দূরে আছেন। নির্ধারিত মাঠে যান।';
      noticeBg = const Color(0xFFFEF2F2);
      noticeBorder = const Color(0xFFFCA5A5);
      noticeTextColor = Colors.red.shade800;
      noticeIcon = Icons.warning_amber_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Satellite Icon & Verified Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.satellite_alt_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'মাঠের বহুভুজ সীমানা (Field Boundary)',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$farmName ($locationCode)',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 13),
                    SizedBox(width: 4),
                    Text(
                      'PostGIS যাচাইকৃত',
                      style: TextStyle(
                        color: AppColors.primaryDarkGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Embedded Mini Satellite Map
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                FieldBoundaryMapWidget(
                  boundary: effectiveBoundary,
                  farmName: farmName,
                  locationCode: locationCode,
                  farmType: farmType,
                  formattedArea: formattedArea,
                  farmerLat: farmerLat,
                  farmerLng: farmerLng,
                  targetLat: targetLat,
                  targetLng: targetLng,
                  gpsAccuracy: gpsAccuracy,
                  height: 195,
                  isInteractive: false,
                ),
                // Tap to Expand Overlay
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onOpenFullMap ?? () => context.push('/field-boundary'),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24, width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.open_in_full_rounded, color: Colors.white, size: 12),
                        SizedBox(width: 5),
                        Text(
                          'বড় মানচিত্র দেখুন',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Proximity & Geofence Notice Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: noticeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: noticeBorder),
            ),
            child: Row(
              children: [
                Icon(
                  noticeIcon,
                  color: noticeTextColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    noticeText,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: noticeTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Action Buttons: Open Full Boundary Map & Navigate
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenFullMap ?? () => context.push('/field-boundary'),
                  icon: const Icon(Icons.map_rounded, size: 18, color: AppColors.primaryGreen),
                  label: const Text(
                    'সীমানা মানচিত্র (Map)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primaryGreen, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to field or focus
                    onOpenFullMap != null ? onOpenFullMap!() : context.push('/field-boundary');
                  },
                  icon: const Icon(Icons.navigation_rounded, size: 18, color: Colors.white),
                  label: const Text(
                    'ফিল্ডে যান (Go)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
