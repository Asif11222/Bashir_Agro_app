import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/task_model.dart';
import '../../../models/field_boundary_model.dart';
import '../../../models/task_assignment_model.dart';
import '../../../services/gps_service.dart';
import '../../../state/app_state.dart';
import '../../../state/farmer_app_state.dart';
import '../../widgets/field_boundary_map_widget.dart';

class FieldBoundaryMapScreen extends ConsumerStatefulWidget {
  const FieldBoundaryMapScreen({super.key});

  @override
  ConsumerState<FieldBoundaryMapScreen> createState() => _FieldBoundaryMapScreenState();
}

class _FieldBoundaryMapScreenState extends ConsumerState<FieldBoundaryMapScreen> {
  StreamSubscription<GpsCoordinate>? _gpsStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchGpsLocation();
      }
    });
  }

  @override
  void dispose() {
    _gpsStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchGpsLocation() async {
    final gpsService = GpsService();
    // Always enforce real device hardware GPS
    ref.read(gpsTrackingModeProvider.notifier).setMode(GpsTrackingMode.realDeviceGps);

    final isServiceEnabled = await gpsService.isLocationServiceEnabled();
    if (!isServiceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('মোবাইলের জিপিএস / লোকেশন সার্ভিস বন্ধ রয়েছে। দয়া করে চালু করুন।'),
          backgroundColor: Colors.amber.shade900,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'সেটিংস',
            textColor: Colors.white,
            onPressed: () => gpsService.openLocationSettings(),
          ),
        ),
      );
    }

    final coord = await gpsService.getCurrentLocation(forceHardware: true);
    if (mounted && coord != null) {
      ref.read(liveGpsCoordinateProvider.notifier).updateCoordinate(coord);
    }
    _startLiveGpsStream();
  }

  void _startLiveGpsStream() {
    _gpsStreamSubscription?.cancel();
    _gpsStreamSubscription = GpsService().getRealTimePositionStream().listen(
      (coord) {
        if (mounted) {
          ref.read(liveGpsCoordinateProvider.notifier).updateCoordinate(coord);
        }
      },
      onError: (e) {
        debugPrint('GPS stream error: $e');
      },
    );
  }

  Future<void> _handleStartWorkFromMap({
    required TaskModel task,
    required TaskAssignmentModel? activeAssignment,
    required bool isInside,
    required double distMeters,
  }) async {
    if (!isInside) {
      final distStr = distMeters >= 1000
          ? '${(distMeters / 1000).toStringAsFixed(1)} কিমি'
          : '${distMeters.toStringAsFixed(0)} মিটার';

      final shouldStart = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 26),
              SizedBox(width: 10),
              Text('সীমানার বাইরে অবস্থান', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'আপনি নির্ধারিত মাঠের বহুভুজ সীমানা হতে $distStr বাইরে অবস্থান করছেন। আপনি কি নিশ্চিত যে কাজ শুরু করবেন?',
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('বাতিল করুন', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('হ্যাঁ, কাজ শুরু করুন', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      if (shouldStart != true) {
        return;
      }
    }

    await ref.read(taskListProvider.notifier).startTask(task.id);
    final assignmentId = int.tryParse(task.id.replaceAll(RegExp(r'[^0-9]'), ''));
    if (assignmentId != null) {
      try {
        await ref.read(farmerTasksProvider.notifier).startTask(assignmentId);
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('কাজটি "চলছে" (In Progress) হিসেবে শুরু করা হয়েছে। মাঠের কাজ শেষ হলে ছবি তুলুন।'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(currentTaskProvider);
    final activeAssignment = ref.watch(activeAssignmentProvider);
    final liveCoord = ref.watch(liveGpsCoordinateProvider);

    final taskLat = activeAssignment?.location?.latitude ?? task?.latitude ?? 24.7471;
    final taskLng = activeAssignment?.location?.longitude ?? task?.longitude ?? 90.4203;

    // Resolve boundary polygon from active assignment location or task
    final boundary = activeAssignment?.location?.fieldBoundary ??
        task?.fieldBoundary ??
        FieldBoundaryModel.fromCenterAndRadius(
          taskLat,
          taskLng,
          (activeAssignment?.location?.geofenceRadiusMeters ?? task?.geofenceRadiusMeters ?? 40).toDouble(),
        );

    final farmName = activeAssignment?.location?.name ?? task?.locationName ?? 'ফার্ম প্লট';
    final locationCode = activeAssignment?.location?.locationCode ?? 'LOC-001';
    final farmType = activeAssignment?.location?.type ?? task?.cropCategory ?? 'মাঠ কাজ';
    final formattedArea = activeAssignment?.location?.formattedArea ?? '১.০০ একর';

    // Calculate effective coordinates strictly from real hardware GPS
    final double? fLat;
    final double? fLng;
    final double gpsAccuracy;
    final bool hasLocation;

    if (liveCoord != null) {
      fLat = liveCoord.latitude;
      fLng = liveCoord.longitude;
      gpsAccuracy = liveCoord.accuracy;
      hasLocation = true;
    } else {
      fLat = null;
      fLng = null;
      gpsAccuracy = 0.0;
      hasLocation = false;
    }

    final bool isInside = hasLocation && boundary.isNotEmpty
        ? boundary.isPointInside(fLat!, fLng!, 20.0)
        : false;
    final double distMeters = hasLocation && boundary.isNotEmpty
        ? boundary.distanceToBoundaryMeters(fLat!, fLng!)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/owner-dashboard');
            }
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'মাঠের বহুভুজ সীমানা',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              'PostGIS স্যাটেলাইট মানচিত্র ভিউ',
              style: TextStyle(fontSize: 11.5, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          // Direct Real GPS Refresh and Lock Action
          IconButton(
            icon: Icon(
              hasLocation ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
              color: hasLocation
                  ? (isInside ? const Color(0xFF00E676) : const Color(0xFF00E5FF))
                  : Colors.amberAccent,
            ),
            tooltip: 'আসল ডিভাইস জিপিএস রিফ্রেশ ও অবস্থান চিহ্নিত করুন',
            onPressed: () async {
              await _fetchGpsLocation();
              if (!mounted) return;
              final live = ref.read(liveGpsCoordinateProvider);
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              if (live != null) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.satellite_alt_rounded, color: Color(0xFF00E5FF), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'আসল জিপিএস সক্রিয়: নির্ভুলতা ${live.accuracy.toStringAsFixed(1)} মিটার',
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.black87,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              } else {
                messenger.showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.location_searching_rounded, color: Colors.amberAccent, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'জিপিএস সিগন্যাল অনুসন্ধান করা হচ্ছে...',
                            style: TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.black87,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Full-screen Interactive Mapbox / Satellite Tile Canvas
          Positioned.fill(
            child: FieldBoundaryMapWidget(
              boundary: boundary,
              farmName: farmName,
              locationCode: locationCode,
              farmType: farmType,
              formattedArea: formattedArea,
              farmerLat: fLat,
              farmerLng: fLng,
              targetLat: taskLat,
              targetLng: taskLng,
              gpsAccuracy: gpsAccuracy,
              height: double.infinity,
              isInteractive: true,
            ),
          ),

          // 2. Bottom Floating Details Card
          Positioned(
            left: 14,
            right: 14,
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title & Badge Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5E9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.eco_rounded, color: AppColors.primaryGreen, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              farmName,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$farmType • $formattedArea',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: !hasLocation
                              ? const Color(0xFFFFFBEB)
                              : isInside
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !hasLocation
                                ? const Color(0xFFFDE68A)
                                : isInside
                                    ? const Color(0xFFC8E6C9)
                                    : const Color(0xFFFFCDD2),
                          ),
                        ),
                        child: Text(
                          !hasLocation
                              ? 'জিপিএস খোঁজা হচ্ছে'
                              : isInside
                                  ? 'সীমানার ভেতরে'
                                  : 'সীমানার বাইরে',
                          style: TextStyle(
                            color: !hasLocation
                                ? Colors.amber.shade900
                                : isInside
                                    ? AppColors.primaryDarkGreen
                                    : Colors.red.shade800,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFEDF2F7)),
                  const SizedBox(height: 12),

                  // GPS Coordinates & Distance Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'আপনার জিপিএস অবস্থান',
                                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: hasLocation ? const Color(0xFFE0F7FA) : Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  hasLocation ? 'আসল জিপিএস (লাইভ)' : 'অনুসন্ধান চলছে',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    color: hasLocation ? const Color(0xFF00838F) : Colors.amber.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            hasLocation
                                ? '${fLat!.toStringAsFixed(5)}° N, ${fLng!.toStringAsFixed(5)}° E'
                                : 'জিপিএস অনুসন্ধান চলছে...',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'সীমানা হতে দূরত্ব',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Text(
                            !hasLocation
                                ? 'অপেক্ষমান...'
                                : isInside
                                    ? '০.০ মিটার (ভেতরে)'
                                    : distMeters >= 1000
                                        ? '${(distMeters / 1000).toStringAsFixed(2)} কিমি'
                                        : '${distMeters.toStringAsFixed(1)} মিটার',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: !hasLocation
                                  ? Colors.amber.shade900
                                  : isInside
                                      ? AppColors.primaryGreen
                                      : Colors.red.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Primary Workflow Action (Navigate / Start / Camera)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isInside
                                      ? 'আপনি বর্তমানে $farmName-এর অনুমোদিত সীমানার ভেতরে আছেন।'
                                      : 'দিকনির্দেশনা: মাঠটি আপনার থেকে ${distMeters.toStringAsFixed(1)} মিটার দূরে অবস্থিত।',
                                ),
                                backgroundColor: isInside ? AppColors.primaryGreen : Colors.orange.shade800,
                              ),
                            );
                          },
                          icon: const Icon(Icons.navigation_rounded, color: AppColors.primaryGreen, size: 18),
                          label: const Text(
                            'দিকনির্দেশনা',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryGreen, width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (task != null && task.status == TaskStatus.scheduled)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _handleStartWorkFromMap(
                              task: task,
                              activeAssignment: activeAssignment,
                              isInside: isInside,
                              distMeters: distMeters,
                            ),
                            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
                            label: const Text(
                              'কাজ শুরু করুন',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      else if (task != null && (task.status == TaskStatus.completed || task.status == TaskStatus.submitted))
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18),
                            label: const Text(
                              'কাজ সম্পন্ন',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              context.push('/camera');
                            },
                            icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                            label: const Text(
                              'ছবি তুলুন',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (task != null && task.status == TaskStatus.scheduled)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          '🔒 কাজ শুরু না করা পর্যন্ত ছবি তোলা যাবে না',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
