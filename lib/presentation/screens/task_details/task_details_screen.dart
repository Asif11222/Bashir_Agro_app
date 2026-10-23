import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/task_model.dart';
import '../../../models/field_boundary_model.dart';
import '../../../models/task_assignment_model.dart';
import '../../../state/app_state.dart';
import '../../../state/farmer_app_state.dart';
import '../../widgets/farm_graphics.dart';
import '../../widgets/field_boundary_preview_card.dart';

class TaskDetailsScreen extends ConsumerWidget {
  const TaskDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(currentTaskProvider);
    final activeAssignment = ref.watch(activeAssignmentProvider);
    final liveCoordAsync = ref.watch(liveDeviceGpsStreamProvider);
    final cachedCoord = ref.watch(liveGpsCoordinateProvider);
    final trackingMode = ref.watch(gpsTrackingModeProvider);
    final currentDeviceCoord = liveCoordAsync.value ?? cachedCoord;
    final isGpsAcquiring = currentDeviceCoord == null && trackingMode == GpsTrackingMode.realDeviceGps;

    final targetLat = activeAssignment?.location?.latitude ?? task?.latitude;
    final targetLng = activeAssignment?.location?.longitude ?? task?.longitude;

    if (task == null) {
      return const Scaffold(
        body: Center(child: Text('কাজের বিবরণ খুঁজে পাওয়া যায়নি')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black26,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 26),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'কাজের বিবরণ',
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
              // Top Banner Image of Farm (Fish pond for fish, Cow shed for cow, Vegetable field for vegetable)
              FarmBannerSimulator(
                height: 180,
                type: task.thumbnailType,
              ),
              const SizedBox(height: 16),

              // Title and Description
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTaskIcon(task.thumbnailType),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          task.description,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Time and Location Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    // Time row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.access_time_rounded,
                            size: 18,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'কাজের সময়',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${DateFormatter.formatDateString(task.date)}, ${task.timeRange}',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: Color(0xFFEDF2F7), height: 1),
                    ),
                    // Location row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'পরিদর্শন স্থান',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                task.fullAddress,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Field Boundary Map Preview (Phase 12B V2 Requirement)
              FieldBoundaryPreviewCard(
                boundary: activeAssignment?.location?.fieldBoundary ??
                    task.fieldBoundary ??
                    (targetLat != null && targetLng != null
                        ? FieldBoundaryModel.fromCenterAndRadius(
                            targetLat,
                            targetLng,
                            task.geofenceRadiusMeters > 0 ? task.geofenceRadiusMeters.toDouble() : 40.0,
                          )
                        : const FieldBoundaryModel(coordinates: [])),
                farmName: activeAssignment?.location?.name ?? task.locationName,
                locationCode: activeAssignment?.location?.locationCode ?? 'LOC-001',
                farmType: activeAssignment?.location?.type ?? task.cropCategory,
                formattedArea: activeAssignment?.location?.formattedArea ?? '১.২৫ একর',
                farmerLat: currentDeviceCoord?.latitude,
                farmerLng: currentDeviceCoord?.longitude,
                targetLat: targetLat,
                targetLng: targetLng,
                gpsAccuracy: currentDeviceCoord?.accuracy ?? 5.0,
                isGpsAcquiring: isGpsAcquiring,
                onOpenFullMap: () => context.push('/field-boundary'),
              ),

              const SizedBox(height: 14),

              // Instruction Box (Golden Amber Tint)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.article_rounded,
                          color: Color(0xFFD97706),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'নির্দেশনা',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.instructions,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF78350F),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ============================================================
              // Task State Workflow Actions & Timer
              // ============================================================
              if (task.status == TaskStatus.scheduled) ...[
                // Helper Instruction Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'কাজের ছবি তোলার পূর্বে অবশ্যই কাজ শুরু করতে হবে। মাঠে পৌঁছে নিচে "কাজ শুরু করুন" চাপুন।',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Step 1 Primary Action: Start Work
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleStartWork(
                      context,
                      ref,
                      task,
                      activeAssignment,
                      currentDeviceCoord,
                      targetLat,
                      targetLng,
                    ),
                    icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                    label: const Text(
                      'কাজ শুরু করুন (Start Work)',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Step 2 Locked Action: Take Photo (Locked until work starts)
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: null, // Disabled until farmer starts work
                    icon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 20),
                    label: Text(
                      'ছবি তুলুন (${DateFormatter.toBanglaDigits(activeAssignment?.minPhotosRequired ?? task.minPhotos)}টি ছবি আবশ্যক)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                      backgroundColor: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      '🔒 কাজ শুরু না করা পর্যন্ত ছবি তোলা যাবে না',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ] else if (task.status == TaskStatus.inProgress) ...[
                // Active Work Stopwatch & Elapsed Duration Timer Card
                ActiveWorkTimerCard(
                  startTime: DateTime.tryParse(task.startedAt ?? '') ??
                      (activeAssignment?.startedAt != null ? DateTime.tryParse(activeAssignment!.startedAt!) : null) ??
                      DateTime.now(),
                ),
                const SizedBox(height: 16),

                // Step 2 Active Action: Capture Evidence
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context.push('/camera');
                    },
                    icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                    label: Text(
                      'ছবি তুলুন (${DateFormatter.toBanglaDigits(activeAssignment?.minPhotosRequired ?? task.minPhotos)}টি ছবি আবশ্যক)',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Completed or Submitted Task Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.status == TaskStatus.submitted ? 'রিভিউ অপেক্ষায়' : 'কাজ সম্পন্ন হয়েছে',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDarkGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'এই কাজের প্রতিবেদন ও ছবি সফলভাবে জমা দেওয়া হয়েছে।',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF166534)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (task.startedAt != null && task.completedAt != null) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: Color(0xFFDCFCE7)),
                        const SizedBox(height: 8),
                        Text(
                          'কাজের মোট সময়: ${_formatCompletedDuration(task.startedAt!, task.completedAt!)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

            ],
          ),
        ),
    );
  }

  Future<void> _handleStartWork(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    TaskAssignmentModel? activeAssignment,
    dynamic currentDeviceCoord,
    double? targetLat,
    double? targetLng,
  ) async {
    final lat = currentDeviceCoord?.latitude ?? targetLat ?? 23.7808;
    final lng = currentDeviceCoord?.longitude ?? targetLng ?? 90.4152;
    final boundary = activeAssignment?.location?.fieldBoundary ?? task.fieldBoundary;
    final isInside = boundary != null && boundary.isNotEmpty
        ? boundary.isPointInside(lat, lng, 20.0)
        : true;

    if (!isInside) {
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
          content: const Text(
            'আপনি নির্ধারিত মাঠের বহুভুজ সীমানা হতে বাইরে অবস্থান করছেন। আপনি কি নিশ্চিত যে কাজ শুরু করবেন?',
            style: TextStyle(fontSize: 14, height: 1.4),
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

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('কাজটি "চলছে" (In Progress) হিসেবে শুরু করা হয়েছে। মাঠের কাজ শেষ হলে ছবি তুলুন।'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    }
  }

  static String _formatCompletedDuration(String startIso, String endIso) {
    try {
      final start = DateTime.parse(startIso);
      final end = DateTime.parse(endIso);
      final diff = end.difference(start);
      final mins = diff.inMinutes;
      if (mins < 1) return '১ মিনিটের কম';
      final hours = mins ~/ 60;
      final remMins = mins % 60;
      if (hours > 0) {
        return '${DateFormatter.toBanglaDigits(hours)} ঘণ্টা ${DateFormatter.toBanglaDigits(remMins)} মিনিট';
      }
      return '${DateFormatter.toBanglaDigits(mins)} মিনিট';
    } catch (_) {
      return '—';
    }
  }

  Widget _buildTaskIcon(String type) {
    switch (type) {
      case 'fish':
        return const TaskThumbnailWidget(type: 'fish', size: 44, borderRadius: 12);
      case 'cow':
        return const TaskThumbnailWidget(type: 'cow', size: 44, borderRadius: 12);
      case 'vegetable':
      default:
        return const SproutIllustration(size: 42);
    }
  }
}

/// Active Work Elapsed Stopwatch Timer Card Widget
class ActiveWorkTimerCard extends StatefulWidget {
  final DateTime startTime;

  const ActiveWorkTimerCard({super.key, required this.startTime});

  @override
  State<ActiveWorkTimerCard> createState() => _ActiveWorkTimerCardState();
}

class _ActiveWorkTimerCardState extends State<ActiveWorkTimerCard> {
  Timer? _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startTime);
    if (_elapsed.isNegative) _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.startTime);
          if (_elapsed.isNegative) _elapsed = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final mins = d.inMinutes % 60;
    final secs = d.inSeconds % 60;

    final minsStr = DateFormatter.toBanglaDigits(mins);
    final secsStr = DateFormatter.toBanglaDigits(secs);

    if (hours > 0) {
      final hoursStr = DateFormatter.toBanglaDigits(hours);
      return '$hoursStr ঘণ্টা $minsStr মিনিট $secsStr সেকেন্ড';
    }
    return '$minsStr মিনিট $secsStr সেকেন্ড';
  }

  String _formatStartTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${DateFormatter.toBanglaDigits(hour)}:${DateFormatter.toBanglaDigits(dt.minute.toString().padLeft(2, '0'))} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'কাজ চলমান',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDarkGreen,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'শুরু: ${_formatStartTime(widget.startTime)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.primaryGreen, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'সময় অতিবাহিত হয়েছে',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                    Text(
                      _formatDuration(_elapsed),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 15, color: AppColors.primaryGreen),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'মাঠের কাজ সমাপ্ত হলে নিচের বাটনে চাপ দিয়ে প্রামাণ্য ছবি তুলুন।',
                  style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
