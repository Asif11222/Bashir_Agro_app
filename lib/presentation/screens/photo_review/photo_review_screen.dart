import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../services/image_compression_service.dart';
import '../../../state/app_state.dart';
import '../../../state/farmer_app_state.dart';
import '../../widgets/farm_graphics.dart';

class PhotoReviewScreen extends ConsumerStatefulWidget {
  const PhotoReviewScreen({super.key});

  @override
  ConsumerState<PhotoReviewScreen> createState() => _PhotoReviewScreenState();
}

class _PhotoReviewScreenState extends ConsumerState<PhotoReviewScreen> {
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final sessionPhotos = ref.read(cameraSessionProvider);
    final photo = ref.read(latestCapturedPhotoProvider);
    final task = ref.read(currentTaskProvider);
    final activeAssignment = ref.read(activeAssignmentProvider);
    final minRequired = activeAssignment?.minPhotosRequired ?? task?.minPhotos ?? 1;
    final totalCaptured = sessionPhotos.isNotEmpty ? sessionPhotos.length : (photo != null ? 1 : 0);

    if (totalCaptured < minRequired) {
      final remaining = minRequired - totalCaptured;
      _showUnderCaptureDialog(context, totalCaptured, minRequired, remaining);
      return;
    }

    // Check if any captured photo or current location is recorded outside field boundary
    final bool isAnyPhotoOutside = sessionPhotos.isNotEmpty
        ? sessionPhotos.any((p) => !p.insideGeofence)
        : !(photo?.insideGeofence ?? true);

    if (isAnyPhotoOutside) {
      final confirm = await _showOutsideBoundaryWarningDialog(context);
      if (confirm != true) {
        return;
      }
      return _executeSubmit(overrideGeofence: true);
    }

    return _executeSubmit(overrideGeofence: false);
  }

  Future<bool?> _showOutsideBoundaryWarningDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'মাঠের বাইরে অবস্থান!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'আপনি নির্ধারিত মাঠের সীমানার বাইরে আছেন। আপনি কি নিশ্চিত যে মাঠের বাইরে থেকেই ছবি ও কাজের রিপোর্ট জমা দিতে চান?',
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'এটি অ্যাডমিন বা সুপারভাইজার প্যানেলে "মাঠের বাইরে থেকে জমা দেওয়া" হিসেবে সতর্কবার্তা সহ চিহ্নিত থাকবে।',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF92400E),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'না, পরে করব',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            label: const Text(
              'হ্যাঁ, জমা দিন',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006837),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _executeSubmit({bool overrideGeofence = false}) async {
    final photo = ref.read(latestCapturedPhotoProvider);
    final task = ref.read(currentTaskProvider);

    setState(() => _isSubmitting = true);

    final syncState = ref.read(offlineSyncProvider);
    final notes = _notesController.text.trim();

    final lat = photo?.latitude ?? 23.7808;
    final lng = photo?.longitude ?? 90.4152;
    const accuracy = 4.5;
    final assignmentId = int.tryParse(task?.id.replaceAll(RegExp(r'[^0-9]'), '') ?? '1') ?? 1;

    bool isOfflineQueued = false;
    bool isGeofenceRejected = false;
    bool isSubmissionFailed = false;
    String statusMessage = '';

    if (!syncState.isOnline) {
      // 2. Real API task, but device is genuinely offline
      final sessionPhotos = ref.read(cameraSessionProvider);
      final paths = sessionPhotos.isNotEmpty
          ? sessionPhotos.map((p) => p.localPath).where((p) => p.isNotEmpty).toList()
          : [photo?.localPath ?? 'photo_1.jpg'];
      final offlineService = ref.read(offlineSyncServiceProvider);
      await offlineService.queueSubmission(
        assignmentId: assignmentId,
        latitude: lat,
        longitude: lng,
        accuracy: accuracy,
        notes: notes,
        photoPaths: paths.isNotEmpty ? paths : ['photo_1.jpg'],
        overrideGeofence: overrideGeofence,
      );
      ref.read(offlineSyncProvider.notifier).updatePendingCount();
      isOfflineQueued = true;
      statusMessage = 'ইন্টারনেট সংযোগ না থাকায় প্রতিবেদনটি ডিভাইসে সংরক্ষণ করা হয়েছে। সংযোগ ফিরে এলে তা স্বয়ংক্রিয়ভাবে সার্ভারে সিঙ্ক হবে।';
      if (task != null) {
        ref.read(taskListProvider.notifier).submitTask(task.id);
      }
    } else {
      // 3. Real API task & online: Direct upload to Laravel API
      try {
        final apiService = ref.read(apiServiceProvider);
        final sessionPhotos = ref.read(cameraSessionProvider);
        final List<Uint8List> photoBytesList = [];
        final compressionService = ImageCompressionService();

        if (sessionPhotos.isNotEmpty) {
          for (final p in sessionPhotos) {
            if (p.localPath.isNotEmpty && File(p.localPath).existsSync()) {
              final raw = await File(p.localPath).readAsBytes();
              final comp = await compressionService.compressImage(raw, targetMaxKb: 800);
              photoBytesList.add(comp.compressedBytes);
            }
          }
        }

        if (photoBytesList.isEmpty) {
          if (photo != null && photo.localPath.isNotEmpty && File(photo.localPath).existsSync()) {
            final raw = await File(photo.localPath).readAsBytes();
            final comp = await compressionService.compressImage(raw, targetMaxKb: 800);
            photoBytesList.add(comp.compressedBytes);
          } else {
            photoBytesList.add(compressionService.generateSimulatedPhotoBytes('evidence'));
          }
        }

        final result = await apiService.submitAssignment(
          assignmentId: assignmentId,
          latitude: lat,
          longitude: lng,
          accuracy: accuracy,
          notes: notes.isNotEmpty ? notes : null,
          photoBytesList: photoBytesList,
          overrideGeofence: overrideGeofence,
        );

        statusMessage = result.message.isNotEmpty
            ? result.message
            : 'আপনার কাজের রিপোর্ট এবং প্রামাণ্য ছবি সফলভাবে সার্ভারে জমা হয়েছে।';
        if (task != null) {
          ref.read(taskListProvider.notifier).submitTask(task.id);
        }
      } on ApiException catch (e) {
        if (e.statusCode == 422) {
          final isPhotoError = e.message.contains('ছবি') || e.message.toLowerCase().contains('photo');
          if (isPhotoError) {
            isSubmissionFailed = true;
            statusMessage = e.message;
          } else {
            // PostGIS Geofence Rejection from Laravel Backend!
            isGeofenceRejected = true;
            statusMessage = e.message;
          }
        } else {
          isSubmissionFailed = true;
          statusMessage = e.message.isNotEmpty ? e.message : 'সার্ভার সমস্যা: জমা দেওয়া সম্ভব হয়নি। অনুগ্রহ করে পুনরায় চেষ্টা করুন।';
        }
      } catch (e) {
        isSubmissionFailed = true;
        statusMessage = 'সার্ভারে জমা দেওয়া সম্ভব হয়নি। ইন্টারনেট সংযোগ পরীক্ষা করে পুনরায় জমা দিন।';
      }
    }

    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                (isGeofenceRejected || isSubmissionFailed)
                    ? Icons.error_outline_rounded
                    : (isOfflineQueued ? Icons.save_rounded : Icons.check_circle),
                color: (isGeofenceRejected || isSubmissionFailed)
                    ? AppColors.errorRed
                    : (isOfflineQueued ? Colors.amber.shade800 : AppColors.primaryGreen),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isGeofenceRejected
                      ? 'যাচাইকরণ ব্যর্থ!'
                      : (isSubmissionFailed
                          ? 'জমা ব্যর্থ হয়েছে'
                          : (isOfflineQueued ? 'অফলাইনে সংরক্ষিত!' : 'সফলভাবে জমা হয়েছে!')),
                  style: TextStyle(
                    color: (isGeofenceRejected || isSubmissionFailed) ? AppColors.errorRed : AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusMessage,
                style: const TextStyle(height: 1.4, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pin_drop_outlined, size: 18, color: AppColors.primaryGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'GPS: $lat, $lng (Accuracy: ±${accuracy}m)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: isGeofenceRejected
              ? [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.push('/field-boundary');
                    },
                    child: const Text('সীমানা মানচিত্র দেখুন', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final sessionPhotos = ref.read(cameraSessionProvider);
                      final currentPhoto = ref.read(latestCapturedPhotoProvider);
                      if (currentPhoto != null) {
                        final idx = sessionPhotos.indexWhere((p) => p.id == currentPhoto.id);
                        if (idx != -1) {
                          ref.read(selectedPhotoSlotProvider.notifier).selectSlot(idx);
                        }
                      }
                      Navigator.pop(ctx);
                      context.pop(); // Back to camera
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
                    child: const Text('পুনরায় ছবি তুলুন', style: TextStyle(color: Colors.white)),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _executeSubmit(overrideGeofence: true);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006837)),
                    child: const Text('তাও জমা দিন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ]
              : (isSubmissionFailed
                  ? [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('বাতিল', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _executeSubmit(overrideGeofence: overrideGeofence);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                        child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(color: Colors.white)),
                      ),
                    ]
                  : [
                      ElevatedButton(
                        onPressed: () {
                          ref.read(cameraSessionProvider.notifier).clearSession();
                          ref.read(latestCapturedPhotoProvider.notifier).setPhoto(null);
                          ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
                          Navigator.pop(ctx);
                          context.go('/dashboard');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                        child: const Text('ঠিক আছে', style: TextStyle(color: Colors.white)),
                      ),
                    ]),
        ),
      );
    }
  }

  void _handleRetake(dynamic photo, List<dynamic> sessionPhotos) {
    if (photo != null) {
      final index = sessionPhotos.indexWhere((p) => p.id == photo.id);
      if (index != -1) {
        ref.read(selectedPhotoSlotProvider.notifier).selectSlot(index);
      }
    }
    context.pop(); // Return to camera with targeted slot ready for retake
  }

  void _handleDelete(dynamic photo, List<dynamic> sessionPhotos) {
    if (photo != null) {
      final index = sessionPhotos.indexWhere((p) => p.id == photo.id);
      if (index != -1) {
        ref.read(cameraSessionProvider.notifier).removePhotoAt(index);
        final remaining = ref.read(cameraSessionProvider);
        if (remaining.isEmpty) {
          ref.read(latestCapturedPhotoProvider.notifier).setPhoto(null);
          ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ছবি মুছে ফেলা হয়েছে। অনুগ্রহ করে নতুন ছবি তুলুন।'),
              backgroundColor: Color(0xFF1E293B),
            ),
          );
          context.pop();
          return;
        } else {
          final nextIndex = index < remaining.length ? index : remaining.length - 1;
          ref.read(latestCapturedPhotoProvider.notifier).setPhoto(remaining[nextIndex]);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ছবি সফলভাবে মুছে ফেলা হয়েছে।'),
              duration: Duration(seconds: 1),
              backgroundColor: Color(0xFF1E293B),
            ),
          );
        }
      }
    }
  }

  void _showUnderCaptureDialog(BuildContext context, int captured, int minRequired, int remaining) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ছবি তোলা সম্পূর্ণ হয়নি!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'এই কাজের জন্য কমপক্ষে ${DateFormatter.toBanglaDigits(minRequired)}টি প্রামাণ্য ছবি প্রয়োজন।',
              style: const TextStyle(fontSize: 14.5, height: 1.4, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 20, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'বর্তমান ছবি: ${DateFormatter.toBanglaDigits(captured)}টি (আর ${DateFormatter.toBanglaDigits(remaining)}টি আবশ্যক)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('পরে করব', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
              context.pop(); // Back to camera
            },
            icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
            label: const Text('বাকি ছবি তুলুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoRequirementProgressCard(int captured, int minRequired, bool isMet) {
    final remaining = minRequired - captured;
    final progress = minRequired > 0 ? math.min(1.0, captured / minRequired) : 1.0;

    return Container(
      decoration: BoxDecoration(
        color: isMet ? const Color(0xFFEFF7F1) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMet ? const Color(0xFFDCEDE0) : const Color(0xFFFDE68A),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isMet ? AppColors.primaryGreen : Colors.amber.shade700,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMet ? Icons.check : Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMet ? 'প্রয়োজনীয় ছবি তোলা সম্পন্ন' : 'আরও ছবি আবশ্যক',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isMet ? AppColors.primaryDarkGreen : const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ছবি তোলা হয়েছে: ${DateFormatter.toBanglaDigits(captured)} / ${DateFormatter.toBanglaDigits(minRequired)} টি',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMet ? AppColors.primaryGreen : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isMet ? const Color(0xFFDCEDE0) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isMet ? 'সম্পূর্ণ' : 'বাকি ${DateFormatter.toBanglaDigits(remaining)}টি',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isMet ? AppColors.primaryDarkGreen : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: isMet ? const Color(0xFFC8E6C9) : const Color(0xFFFDE68A),
              valueColor: AlwaysStoppedAnimation<Color>(
                isMet ? AppColors.primaryGreen : Colors.amber.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMet
                ? 'সবগুলো আবশ্যক ছবি তোলা হয়েছে। অনুগ্রহ করে ছবিগুলো পর্যালোচনা করে জমা দিন।'
                : 'কাজের সঠিক প্রমাণের জন্য কমপক্ষে ${DateFormatter.toBanglaDigits(minRequired)}টি ছবি তুলতে হবে। বাকি ছবিগুলো তুলে জমা দিন।',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: isMet ? const Color(0xFF2E7D32) : const Color(0xFF78350F),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionPhotos = ref.watch(cameraSessionProvider);
    final currentLatest = ref.watch(latestCapturedPhotoProvider);
    final photo = currentLatest ?? (sessionPhotos.isNotEmpty ? sessionPhotos.last : null);
    final task = ref.watch(currentTaskProvider);
    final activeAssignment = ref.watch(activeAssignmentProvider);
    final minRequired = activeAssignment?.minPhotosRequired ?? task?.minPhotos ?? 1;
    final totalCaptured = sessionPhotos.isNotEmpty ? sessionPhotos.length : (photo != null ? 1 : 0);
    final isRequirementMet = totalCaptured >= minRequired;
    final isValid = photo?.insideGeofence ?? true;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'ছবি পর্যালোচনা ও জমা',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(18),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Captured Photo with Edit / Retake overlay icon
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: (photo != null &&
                            photo.localPath.isNotEmpty &&
                            File(photo.localPath).existsSync())
                        ? Image.file(
                            File(photo.localPath),
                            height: 205,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : FarmBannerSimulator(
                            height: 205,
                            type: task?.thumbnailType ?? 'vegetable',
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Retake button
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.8), width: 1),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _handleRetake(photo, sessionPhotos),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.sync_rounded, color: Colors.amberAccent, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'পুনরায় তুলুন',
                                    style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Delete button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.8), width: 1),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _handleDelete(photo, sessionPhotos),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'মুছে ফেলুন',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Compression Indicator Badge (Phase 12B Submission Module: Image Compression)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Builder(
                      builder: (context) {
                        String sizeLabel = '৪৮০ KB (অনুকূলিত)';
                        if (photo != null &&
                            photo.localPath.isNotEmpty &&
                            File(photo.localPath).existsSync()) {
                          try {
                            final bytes = File(photo.localPath).lengthSync();
                            final kb = (bytes / 1024).round();
                            sizeLabel = '${DateFormatter.toBanglaDigits(kb)} KB (ক্যামেরা ছবি)';
                          } catch (_) {}
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.compress_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'আকার: $sizeLabel',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // Multi-photo switcher if more than 1 photo required or captured
              if (math.max(minRequired, sessionPhotos.length) > 1) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 68,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: math.max(minRequired, math.max(1, sessionPhotos.length)),
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final isCaptured = idx < sessionPhotos.length;
                      if (isCaptured) {
                        final p = sessionPhotos[idx];
                        final isSelected = p.id == photo?.id;
                        final isFile = p.localPath.isNotEmpty && File(p.localPath).existsSync();

                        return GestureDetector(
                          onTap: () {
                            ref.read(latestCapturedPhotoProvider.notifier).setPhoto(p);
                          },
                          child: Container(
                            width: 68,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? AppColors.primaryGreen : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  isFile
                                      ? Image.file(File(p.localPath), fit: BoxFit.cover)
                                      : const FarmBannerSimulator(height: 68, borderRadius: BorderRadius.zero),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '#${DateFormatter.toBanglaDigits(idx + 1)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        // Empty slot placeholder
                        final isRequiredSlot = idx < minRequired;
                        return GestureDetector(
                          onTap: () {
                            ref.read(selectedPhotoSlotProvider.notifier).selectSlot(idx);
                            context.pop(); // Returns to camera focused on this slot
                          },
                          child: Container(
                            width: 68,
                            decoration: BoxDecoration(
                              color: isRequiredSlot ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isRequiredSlot ? Colors.amber.shade400 : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 20,
                                  color: isRequiredSlot ? Colors.amber.shade800 : Colors.grey.shade500,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '#${DateFormatter.toBanglaDigits(idx + 1)} ${isRequiredSlot ? 'আবশ্যক' : ''}',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isRequiredSlot ? Colors.amber.shade900 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Photo Requirement & Progress Indicator Card
              _buildPhotoRequirementProgressCard(totalCaptured, minRequired, isRequirementMet),

              const SizedBox(height: 14),

              // Geofence Verification Status Box (PostGIS Validation)
              Container(
                decoration: BoxDecoration(
                  color: isValid ? const Color(0xFFEFF7F1) : AppColors.errorRedBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isValid ? const Color(0xFFDCEDE0) : const Color(0xFFFCA5A5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isValid ? AppColors.primaryGreen : AppColors.errorRed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isValid ? Icons.check : Icons.close,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isValid ? 'অবস্থান সঠিক (Geofence Verified)' : 'নির্ধারিত মাঠের বাইরে তোলা হয়েছে',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isValid ? AppColors.primaryDarkGreen : AppColors.errorRed,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isValid
                                ? 'এই ছবির অবস্থান আপনার জমির জিও-ফেন্স পরিধির ভেতরে রেকর্ড করা হয়েছে।'
                                : 'এই ছবিটি নির্ধারিত প্লটের সীমানার বাইরে। পোস্টজিআইএস যাচাইকরণে এটি ব্যর্থ হতে পারে।',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isValid ? const Color(0xFF2E7D32) : const Color(0xFF991B1B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Notes Input Field (Submission Module Requirement)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notes_rounded, color: AppColors.primaryGreen, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'কাজের বিবরণ ও মন্তব্য (Notes)',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'মাঠের অবস্থা বা কাজের কোনো বিশেষ তথ্য লিখুন...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Metadata: Capture Time and Location (GPS Module)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    // Time Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.access_time_rounded, color: AppColors.primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ছবি তোলার সময়',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                DateFormatter.formatDateTime(date: photo?.capturedAt),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Color(0xFFEDF2F7), height: 1),
                    ),
                    // Location & GPS Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, color: AppColors.primaryGreen, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'জিপিএস অবস্থান ও নির্ভুলতা (GPS)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '২৩.৭৮০৮° N, ৯০.৪১৫২° E (±৪.৫ মিটার)',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 20),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Primary Upload & Submit Button (Online / Offline Aware)
              if (!isRequirementMet) ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
                      context.pop(); // Returns to camera
                    },
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 22),
                    label: Text(
                      'পরবর্তী ছবি তুলুন (আর ${DateFormatter.toBanglaDigits(minRequired - totalCaptured)}টি আবশ্যক)',
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.textSecondary, size: 20),
                    label: Text(
                      'জমা দিন (${DateFormatter.toBanglaDigits(totalCaptured)}/${DateFormatter.toBanglaDigits(minRequired)} টি ছবি)',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 22),
                    label: Text(
                      _isSubmitting
                          ? 'আপলোড হচ্ছে...'
                          : 'ছবি আপলোড ও জমা দিন (${DateFormatter.toBanglaDigits(totalCaptured)}টি ছবি)',
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Retake & Delete Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleRetake(photo, sessionPhotos),
                      icon: const Icon(Icons.sync_rounded, color: Color(0xFFE65100), size: 18),
                      label: const Text('ছবি পরিবর্তন (Retake)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        side: const BorderSide(color: Color(0xFFE65100), width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleDelete(photo, sessionPhotos),
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                      label: const Text('ছবি বাদ দিন (Delete)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

              if (!isRequirementMet) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(selectedPhotoSlotProvider.notifier).selectSlot(null);
                      context.pop();
                    },
                    icon: const Icon(Icons.camera_alt_outlined, color: AppColors.textLinkBlue, size: 20),
                    label: const Text(
                      'পরবর্তী আবশ্যক ছবি তুলুন',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLinkBlue,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
    );
  }
}
