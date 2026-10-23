import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/owner_models.dart';
import '../../../models/field_boundary_model.dart';
import '../../../state/owner_state.dart';
import '../../widgets/field_boundary_map_widget.dart';

class OwnerLocationMapScreen extends ConsumerWidget {
  final OwnerLocationItem? locationOverride;

  const OwnerLocationMapScreen({
    super.key,
    this.locationOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = locationOverride ?? ref.watch(selectedLocationForMapProvider);

    if (location == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          title: const Text('মানচিত্র ভিউ', style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('কোনো লোকেশন নির্বাচন করা হয়নি।'),
              const SizedBox(height: 14),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.go('/locations-list'),
                child: const Text('লোকেশন তালিকায় যান'),
              ),
            ],
          ),
        ),
      );
    }

    final lat = location.latitude ?? 24.7471;
    final lng = location.longitude ?? 90.4203;

    final boundary = location.fieldBoundary.isNotEmpty
        ? location.fieldBoundary
        : FieldBoundaryModel.fromCenterAndRadius(lat, lng, 35.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/locations-list');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              location.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${location.locationCode} • PostGIS বহুভুজ সীমানা',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded, color: Colors.white),
            tooltip: 'সব লোকেশন',
            onPressed: () => context.go('/locations-list'),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. High-Fidelity Satellite Map Widget
          Positioned.fill(
            child: FieldBoundaryMapWidget(
              boundary: boundary,
              farmName: location.name,
              locationCode: location.locationCode,
              farmType: location.type,
              formattedArea: location.formattedArea,
              targetLat: lat,
              targetLng: lng,
              height: double.infinity,
              isInteractive: true,
            ),
          ),

          // 2. Floating Location Info Card at Bottom
          Positioned(
            left: 14,
            right: 14,
            bottom: 24,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Code
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            location.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            location.locationCode,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Type, Area and Address
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            location.type,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'আয়তন: ${location.formattedArea}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Coordinates & Address Row
                    Row(
                      children: [
                        const Icon(Icons.pin_drop_outlined, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location.address,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.gps_fixed_rounded, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          '${lat.toStringAsFixed(6)}° N, ${lng.toStringAsFixed(6)}° E',
                          style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace', color: Color(0xFF475569)),
                        ),
                        const Spacer(),
                        if (location.farmersCount > 0)
                          Text(
                            'কৃষক: ${DateFormatter.toBanglaDigits(location.farmersCount.toString())} জন',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Return Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/locations-list');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('সব লোকেশন তালিকায় ফিরুন'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
