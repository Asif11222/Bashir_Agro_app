import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/task_model.dart';
import '../../../data/models/task_photo_model.dart';
import '../../../services/camera_service.dart';
import '../../../services/gps_service.dart';
import '../../../state/app_state.dart';
import '../../../state/farmer_app_state.dart';
import '../../widgets/camera_reticle.dart';
import '../../widgets/farm_graphics.dart';

class LiveCameraScreen extends ConsumerStatefulWidget {
  const LiveCameraScreen({super.key});

  @override
  ConsumerState<LiveCameraScreen> createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends ConsumerState<LiveCameraScreen> {
  final CameraService _cameraService = CameraService.instance;
  bool _isInitializing = true;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() => _isInitializing = true);
    await _cameraService.initialize();
    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  Future<void> _handleShutter() async {
    final currentTask = ref.read(currentTaskProvider);
    if (currentTask != null && currentTask.status == TaskStatus.scheduled) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: Color(0xFFD97706), size: 24),
                SizedBox(width: 8),
                Text('কাজ শুরু করা হয়নি', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'কাজের প্রামাণ্য ছবি তোলার পূর্বে অবশ্যই কাজ শুরু করতে হবে। আপনি কি এখনই কাজটি "চলছে" (In Progress) হিসেবে শুরু করতে চান?',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('বাতিল করুন', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(taskListProvider.notifier).startTask(currentTask.id);
                  final assignmentId = int.tryParse(currentTask.id.replaceAll(RegExp(r'[^0-9]'), ''));
                  if (assignmentId != null) {
                    try {
                      await ref.read(farmerTasksProvider.notifier).startTask(assignmentId);
                    } catch (_) {}
                  }
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('কাজটি শুরু হয়েছে। এখন আপনি প্রামাণ্য ছবি তুলতে পারেন।'),
                        backgroundColor: Color(0xFF006837),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006837),
                  foregroundColor: Colors.white,
                ),
                child: const Text('হ্যাঁ, কাজ শুরু করুন'),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final trackingMode = ref.read(gpsTrackingModeProvider);
      final isInsideSimulation = ref.read(gpsSimulationInsideProvider);
      final liveCoord = ref.read(liveGpsCoordinateProvider);
      final task = ref.read(currentTaskProvider);
      final activeAssignment = ref.read(activeAssignmentProvider);
      final boundary = activeAssignment?.location?.fieldBoundary ?? task?.fieldBoundary;

      final targetLat = activeAssignment?.location?.latitude ?? task?.latitude ?? 23.7808;
      final targetLng = activeAssignment?.location?.longitude ?? task?.longitude ?? 90.4152;

      final double photoLat;
      final double photoLng;
      final double photoAcc;
      final bool photoInside;

      if (trackingMode == GpsTrackingMode.realDeviceGps && liveCoord != null) {
        photoLat = liveCoord.latitude;
        photoLng = liveCoord.longitude;
        photoAcc = liveCoord.accuracy;
        photoInside = boundary != null && boundary.isNotEmpty
            ? boundary.isPointInside(photoLat, photoLng, 20.0)
            : true;
      } else if (trackingMode == GpsTrackingMode.outsideSimulation || !isInsideSimulation) {
        photoLat = targetLat + 0.05;
        photoLng = targetLng + 0.05;
        photoAcc = 15.0;
        photoInside = false;
      } else {
        photoLat = targetLat;
        photoLng = targetLng;
        photoAcc = 4.5;
        photoInside = true;
      }

      String photoPath = '';
      if (_cameraService.isInitialized) {
        final xFile = await _cameraService.takePicture();
        if (xFile != null) {
          photoPath = xFile.path;
        }
      }

      // Fallback for virtual/test environments if sensor cannot capture
      if (photoPath.isEmpty) {
        photoPath = 'simulated_farm_crop_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }

      final newPhoto = TaskPhotoModel(
        id: 'PHOTO_${DateTime.now().millisecondsSinceEpoch}',
        localPath: photoPath,
        capturedAt: DateTime.now(),
        latitude: photoLat,
        longitude: photoLng,
        gpsAccuracy: photoAcc,
        insideGeofence: photoInside,
        locationName: photoInside
            ? (activeAssignment?.location?.name ?? task?.locationName ?? 'নির্ধারিত খামার জমি')
            : 'নির্ধারিত এলাকার বাইরে',
      );

      final selectedSlot = ref.read(selectedPhotoSlotProvider);
      final currentPhotos = ref.read(cameraSessionProvider);
      final minRequired = activeAssignment?.minPhotosRequired ?? task?.minPhotos ?? 1;

      // Prevent capturing extra photos beyond the required count unless retaking
      if (selectedSlot == null && currentPhotos.length >= minRequired) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'প্রয়োজনীয় ${DateFormatter.toBanglaDigits(minRequired)}টি ছবি ইতিমধ্যে তোলা সম্পন্ন হয়েছে।',
              ),
              backgroundColor: const Color(0xFF006837),
            ),
          );
          context.push('/photo-review');
        }
        return;
      }

      if (selectedSlot != null && selectedSlot < currentPhotos.length) {
        // Retaking/replacing a specific slot
        ref.read(cameraSessionProvider.notifier).replacePhotoAt(selectedSlot, newPhoto);
        ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
      } else {
        // Appending to the next required slot
        if (currentPhotos.length < minRequired) {
          ref.read(cameraSessionProvider.notifier).addPhoto(newPhoto);
        } else {
          ref.read(cameraSessionProvider.notifier).replacePhotoAt(minRequired - 1, newPhoto);
        }
      }

      ref.read(latestCapturedPhotoProvider.notifier).setPhoto(newPhoto);

      if (mounted) {
        context.push('/photo-review');
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.always:
        return Icons.flash_on_rounded;
      case FlashMode.off:
        return Icons.flash_off_rounded;
      case FlashMode.auto:
      default:
        return Icons.flash_auto_rounded;
    }
  }

  String _getFlashLabel(FlashMode mode) {
    switch (mode) {
      case FlashMode.always:
        return 'অন (Always On)';
      case FlashMode.off:
        return 'বন্ধ (Off)';
      case FlashMode.auto:
      default:
        return 'স্বয়ংক্রিয় (Auto)';
    }
  }

  Widget _buildViewfinder(TaskModel? task) {
    // 1. Live Hardware Camera Viewfinder Preview
    if (_cameraService.isInitialized && _cameraService.controller != null) {
      final controller = _cameraService.controller!;
      return ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewSize = controller.value.previewSize;
            if (previewSize == null) {
              return CameraPreview(controller);
            }

            final screenAspectRatio = constraints.maxWidth / constraints.maxHeight;
            final cameraAspectRatio = previewSize.height / previewSize.width;

            var scale = screenAspectRatio / cameraAspectRatio;
            if (scale < 1.0) {
              scale = 1.0 / scale;
            }

            return Transform.scale(
              scale: scale,
              child: Center(
                child: CameraPreview(controller),
              ),
            );
          },
        ),
      );
    }

    // 2. Camera Initializing State
    if (_isInitializing) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF006837),
                strokeWidth: 3,
              ),
              SizedBox(height: 16),
              Text(
                'ক্যামেরা চালু হচ্ছে...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Fallback Viewfinder (Test runner / emulator without camera hardware)
    return Stack(
      fit: StackFit.expand,
      children: [
        FarmBannerSimulator(
          height: double.infinity,
          borderRadius: BorderRadius.zero,
          type: task?.thumbnailType ?? 'vegetable',
        ),
        Positioned(
          top: 48,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24, width: 0.8),
              ),
              child: Text(
                _cameraService.errorMessage ?? 'ভার্চুয়াল ক্যামেরা মোড সক্রিয়',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackingMode = ref.watch(gpsTrackingModeProvider);
    final isInsideSimulation = ref.watch(gpsSimulationInsideProvider);
    final liveCoordAsync = ref.watch(liveDeviceGpsStreamProvider);
    final cachedCoord = ref.watch(liveGpsCoordinateProvider);
    final deviceCoord = liveCoordAsync.value ?? cachedCoord;
    final capturedPhotos = ref.watch(cameraSessionProvider);
    final selectedSlot = ref.watch(selectedPhotoSlotProvider);
    final task = ref.watch(currentTaskProvider);
    final activeAssignment = ref.watch(activeAssignmentProvider);
    final boundary = activeAssignment?.location?.fieldBoundary ?? task?.fieldBoundary;
    final minRequired = activeAssignment?.minPhotosRequired ?? task?.minPhotos ?? 1;

    final bool isRealGps = trackingMode == GpsTrackingMode.realDeviceGps;
    final bool isAcquiring = isRealGps && deviceCoord == null;
    final bool isInsideGeofence;

    if (isRealGps) {
      if (deviceCoord != null && boundary != null && boundary.isNotEmpty) {
        isInsideGeofence = boundary.isPointInside(deviceCoord.latitude, deviceCoord.longitude, 20.0);
      } else if (deviceCoord != null && task?.latitude != null && task?.longitude != null) {
        final dist = GpsService().calculateDistanceMeters(
          deviceCoord.latitude,
          deviceCoord.longitude,
          task!.latitude!,
          task.longitude!,
        );
        isInsideGeofence = dist <= (task.geofenceRadiusMeters > 0 ? task.geofenceRadiusMeters : 40.0);
      } else {
        isInsideGeofence = false;
      }
    } else {
      isInsideGeofence = (trackingMode == GpsTrackingMode.insideSimulation || isInsideSimulation);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'ছবি তুলুন',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          if (capturedPhotos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: () => context.push('/photo-review'),
                icon: Icon(
                  capturedPhotos.length >= minRequired
                      ? Icons.check_circle_rounded
                      : Icons.rate_review_outlined,
                  color: capturedPhotos.length >= minRequired
                      ? Colors.greenAccent
                      : Colors.amberAccent,
                  size: 18,
                ),
                label: Text(
                  'পর্যালোচনা (${DateFormatter.toBanglaDigits(capturedPhotos.length)}/${DateFormatter.toBanglaDigits(minRequired)})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          // Real GPS Lock Action & Status Indicator
          IconButton(
            icon: Icon(
              Icons.gps_fixed_rounded,
              color: isAcquiring
                  ? Colors.amberAccent
                  : isInsideGeofence
                      ? Colors.greenAccent
                      : Colors.redAccent,
            ),
            tooltip: 'আসল জিপিএস রিফ্রেশ ও অবস্থান চিহ্নিত করুন',
            onPressed: () async {
              ref.read(gpsTrackingModeProvider.notifier).setMode(GpsTrackingMode.realDeviceGps);
              final coord = await GpsService().getCurrentLocation(forceHardware: true);
              if (!mounted) return;
              if (coord != null) {
                ref.read(liveGpsCoordinateProvider.notifier).updateCoordinate(coord);
                final messenger = ScaffoldMessenger.of(context);
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'আসল জিপিএস পজিশন লক হয়েছে (নির্ভুলতা: ${coord.accuracy.toStringAsFixed(1)} মি.)',
                    ),
                    backgroundColor: Colors.black87,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Viewport with Framing Reticles
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Live Viewfinder
                _buildViewfinder(task),

                // Corner framing reticles [ ]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: CustomPaint(
                    painter: CameraReticlePainter(
                      color: Colors.white.withValues(alpha: 0.9),
                      cornerLength: 40,
                      strokeWidth: 3.5,
                      borderRadius: 12,
                    ),
                  ),
                ),

                // Bottom pill message: "ছবিটি অবশ্যই এখনই (রিয়েল টাইমে) তুলতে হবে"
                Positioned(
                  bottom: 24,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco_rounded, color: Color(0xFF81C784), size: 16),
                          SizedBox(width: 7),
                          Text(
                            'ছবিটি অবশ্যই এখনই (রিয়েল টাইমে) তুলতে হবে',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Geofence status tag on top of viewfinder
                Positioned(
                  top: 12,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAcquiring
                          ? const Color(0xCCE65100)
                          : isInsideGeofence
                              ? const Color(0xCC007936)
                              : const Color(0xCCD32F2F),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAcquiring
                              ? Icons.gps_not_fixed_rounded
                              : isInsideGeofence
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isAcquiring
                              ? 'জিপিএস খোঁজা হচ্ছে...'
                              : isInsideGeofence
                                  ? 'জিপিএস: মাঠের ভেতরে'
                                  : 'জিপিএস: মাঠের বাইরে',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Photo Counter & Requirement Pill on top right of viewfinder
                Positioned(
                  top: 12,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: capturedPhotos.length >= minRequired
                          ? const Color(0xCC007936)
                          : const Color(0xCCE65100),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: capturedPhotos.length >= minRequired
                            ? Colors.greenAccent.withValues(alpha: 0.6)
                            : Colors.amberAccent.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          capturedPhotos.length >= minRequired
                              ? Icons.check_circle_rounded
                              : Icons.photo_camera_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'ছবি: ${DateFormatter.toBanglaDigits(capturedPhotos.length)} / ${DateFormatter.toBanglaDigits(minRequired)}টি',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Retake Mode indicator badge
                if (selectedSlot != null && selectedSlot < capturedPhotos.length)
                  Positioned(
                    top: 48,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xE6E65100),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.amberAccent, width: 1.2),
                            boxShadow: const [
                              BoxShadow(color: Colors.black45, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'ছবি #${selectedSlot + 1} পরিবর্তন করা হচ্ছে (বাতিল করতে ট্যাপ করুন)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Controls Container (Black)
          Container(
            color: Colors.black,
            padding: const EdgeInsets.only(top: 14, bottom: 28, left: 24, right: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thumbnails strip
                SizedBox(
                  height: 56,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        math.max(minRequired, capturedPhotos.length),
                        (index) {
                          final hasPhoto = index < capturedPhotos.length;
                          final photo = hasPhoto ? capturedPhotos[index] : null;
                          final isRealFile = photo != null && File(photo.localPath).existsSync();
                          final isSelectedForRetake = selectedSlot == index;
                          final isRequiredSlot = index < minRequired;

                          return GestureDetector(
                            onTap: () {
                              if (hasPhoto) {
                                if (isSelectedForRetake) {
                                  ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
                                } else {
                                  ref.read(selectedPhotoSlotProvider.notifier).selectSlot(index);
                                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('ছবি #${index + 1} পুনরায় তোলার জন্য নির্বাচিত। শাটার চাপুন।'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: const Color(0xFFE65100),
                                    ),
                                  );
                                }
                              } else {
                                if (selectedSlot != null) {
                                  ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
                                }
                              }
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  margin: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelectedForRetake
                                          ? Colors.amberAccent
                                          : (hasPhoto
                                              ? Colors.white
                                              : (isRequiredSlot
                                                  ? Colors.amberAccent.withValues(alpha: 0.8)
                                                  : Colors.white24)),
                                      width: isSelectedForRetake ? 2.5 : 1.5,
                                    ),
                                    boxShadow: isSelectedForRetake
                                        ? [
                                            BoxShadow(
                                              color: Colors.amberAccent.withValues(alpha: 0.5),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: hasPhoto
                                        ? Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              (isRealFile
                                                  ? Image.file(
                                                      File(photo.localPath),
                                                      fit: BoxFit.cover,
                                                      width: 52,
                                                      height: 52,
                                                    )
                                                  : const FarmBannerSimulator(
                                                      height: 52,
                                                      borderRadius: BorderRadius.zero,
                                                    )),
                                              Positioned(
                                                bottom: 2,
                                                left: 2,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black.withValues(alpha: 0.75),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '#${DateFormatter.toBanglaDigits(index + 1)}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Container(
                                            color: isRequiredSlot
                                                ? Colors.amber.withValues(alpha: 0.12)
                                                : Colors.white10,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '#${DateFormatter.toBanglaDigits(index + 1)}',
                                                    style: TextStyle(
                                                      color: isRequiredSlot ? Colors.amberAccent : Colors.white38,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  if (isRequiredSlot)
                                                    const Text(
                                                      'আবশ্যক',
                                                      style: TextStyle(
                                                        color: Colors.amberAccent,
                                                        fontSize: 8.5,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                            // Delete button (✕)
                            if (hasPhoto)
                              Positioned(
                                top: -4,
                                right: 1,
                                child: GestureDetector(
                                  onTap: () {
                                    ref.read(cameraSessionProvider.notifier).removePhotoAt(index);
                                    if (selectedSlot == index) {
                                      ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
                                    } else if (selectedSlot != null && selectedSlot > index) {
                                      ref.read(selectedPhotoSlotProvider.notifier).selectSlot(selectedSlot - 1);
                                    }
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('ছবিটি মুছে ফেলা হয়েছে'),
                                        duration: Duration(seconds: 1),
                                        backgroundColor: Color(0xFF1E293B),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      color: Colors.redAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 13,
                                    ),
                                  ),
                                ),
                              ),
                            // Retake icon indicator
                            if (isSelectedForRetake)
                              Positioned(
                                bottom: 2,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE65100),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.sync_rounded,
                                    color: Colors.white,
                                    size: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 22),

                // Controls: Flash, Shutter, Flip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Flash Button
                    IconButton(
                      icon: Icon(
                        _getFlashIcon(_cameraService.flashMode),
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final newMode = await _cameraService.cycleFlashMode();
                        if (!mounted) return;
                        setState(() {});
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('ফ্ল্যাশ মোড: ${_getFlashLabel(newMode)}'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: const Color(0xFF1E293B),
                          ),
                        );
                      },
                    ),

                    // Shutter Button (Outer ring + Inner circle)
                    GestureDetector(
                      onTap: _isCapturing ? null : _handleShutter,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: _isCapturing
                              ? const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF006837),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),

                    // Camera Switch / Flip Button
                    IconButton(
                      icon: const Icon(
                        Icons.cameraswitch_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () async {
                        if (!_cameraService.hasMultipleCameras) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ডিভাইসে শুধুমাত্র একটি ক্যামেরা পাওয়া গেছে'),
                              duration: Duration(seconds: 1),
                              backgroundColor: Color(0xFF1E293B),
                            ),
                          );
                          return;
                        }
                        final switched = await _cameraService.switchCamera();
                        if (mounted && switched) {
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
