import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/task_model.dart';
import '../../../models/field_boundary_model.dart';
import '../../../models/task_assignment_model.dart';
import '../../widgets/completed_task_map_widget.dart';
import '../../widgets/farm_graphics.dart';
import '../../widgets/submitted_photos_grid.dart';
import 'completed_task_full_map_screen.dart';

/// Screen view for Completed / Submitted Tasks matching the user's sample interface:
/// 1. App Bar: <- কাজের বিবরণ
/// 2. Top Success Banner: [✓] কাজের তথ্য জমা হয়েছে
/// 3. Hero Farm Banner Image
/// 4. Task Title, Category & [✓ সম্পন্ন] Status Badge
/// 5. Key Info Card: কাজের সময়, নির্ধারিত স্থান, জমা দেওয়ার সময়
/// 6. Authoritative 4-State Verification Pills:
///    - (✓) সব ঠিক / (!) সময়ে সমস্যা / (!) লোকেশনে সমস্যা / (X) সময় ও লোকেশনে সমস্যা
///    - (✓) সঠিক লোকেশনে vs (X) লোকেশনের বাইরে
///    - (✓) সময়ের মধ্যে vs (X) সময় পেরিয়েছে
/// 7. Field Boundary Satellite Map with green/red photo pins + legend + outside warning
/// 8. Submitted Photos Grid with photo thumbnails & lightbox
/// 9. Instruction Card (নির্দেশনা)
/// 10. Bottom Return Button: [← কাজের তালিকায় ফিরুন]
class CompletedTaskDetailsView extends StatelessWidget {
  final TaskModel task;
  final TaskAssignmentModel? activeAssignment;
  final VoidCallback onBack;
  final VoidCallback? onOpenFullMap;

  const CompletedTaskDetailsView({
    super.key,
    required this.task,
    this.activeAssignment,
    required this.onBack,
    this.onOpenFullMap,
  });

  List<SubmittedPhotoDetail> _getEffectivePhotos() {
    if (task.submittedPhotos.isNotEmpty) {
      return task.submittedPhotos;
    }
    if (activeAssignment?.submission?.photosDetailed.isNotEmpty == true) {
      return activeAssignment!.submission!.photosDetailed;
    }
    if (task.evidencePhotoUrls.isNotEmpty) {
      return task.evidencePhotoUrls.asMap().entries.map((e) {
        return SubmittedPhotoDetail(
          id: e.key + 1,
          url: e.value,
          latitude: task.latitude,
          longitude: task.longitude,
          capturedAt: task.submittedAt ?? task.completedAt,
          insideGeofence: task.geofencePassed ?? true,
          isLate: task.isLate,
        );
      }).toList();
    }
    if (task.photos.isNotEmpty) {
      return task.photos.asMap().entries.map((e) {
        return SubmittedPhotoDetail(
          id: int.tryParse(e.value.id) ?? (e.key + 1),
          url: e.value.localPath,
          latitude: e.value.latitude,
          longitude: e.value.longitude,
          capturedAt: e.value.capturedAt.toIso8601String(),
          insideGeofence: e.value.insideGeofence,
          isLate: task.isLate,
        );
      }).toList();
    }
    return const [];
  }

  void _openFullMap(
    BuildContext context,
    FieldBoundaryModel boundary,
    List<SubmittedPhotoDetail> photos, {
    int? initialPhotoIndex,
  }) {
    if (onOpenFullMap != null && initialPhotoIndex == null) {
      onOpenFullMap!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompletedTaskFullMapScreen(
          boundary: boundary,
          farmName: activeAssignment?.location?.name ?? task.locationName,
          locationCode: activeAssignment?.location?.locationCode ?? 'LOC-001',
          targetLat: activeAssignment?.location?.latitude ?? task.latitude,
          targetLng: activeAssignment?.location?.longitude ?? task.longitude,
          photos: photos,
          taskIsLate: task.isLate,
          initialPhotoIndex: initialPhotoIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectivePhotos = _getEffectivePhotos();
    final effectiveBoundary = activeAssignment?.location?.fieldBoundary ??
        task.fieldBoundary ??
        (task.latitude != null && task.longitude != null
            ? FieldBoundaryModel.fromCenterAndRadius(
                task.latitude!,
                task.longitude!,
                task.geofenceRadiusMeters > 0 ? task.geofenceRadiusMeters.toDouble() : 40.0,
              )
            : const FieldBoundaryModel(coordinates: []));

    // Determine location validity across photos
    bool isLocationValid = true;
    if (effectivePhotos.isNotEmpty) {
      final hasOutside = effectivePhotos.any((p) {
        if (p.insideGeofence != null) return !p.insideGeofence!;
        if (p.latitude != null &&
            p.longitude != null &&
            effectiveBoundary.isNotEmpty) {
          return !effectiveBoundary.isPointInside(
            p.latitude!,
            p.longitude!,
            20.0,
          );
        }
        return false;
      });
      isLocationValid = !hasOutside;
    } else {
      isLocationValid = task.geofencePassed ??
          (activeAssignment?.submission?.geofencePassed ?? true);
    }

    // Determine time validity
    final bool isTimeValid = !task.isLate &&
        (activeAssignment?.submission?.isLate != true);

    // Format submission time
    final submissionTimeFormatted = _getSubmissionTimeFormatted();

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
          onPressed: onBack,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Success Banner
            _buildTopSuccessBanner(),
            const SizedBox(height: 14),

            // 2. Hero Farm Banner Image
            FarmBannerSimulator(
              height: 180,
              type: task.thumbnailType,
            ),
            const SizedBox(height: 16),

            // 3. Task Title, Category & Completed Status Badge
            _buildTaskHeader(),
            const SizedBox(height: 16),

            // 4. Key Info Box (Time, Location, Submission Time)
            _buildKeyInfoBox(submissionTimeFormatted),
            const SizedBox(height: 16),

            // 5. Authoritative 4-State Verification Matrix Pills
            _buildVerificationPills(isLocationValid, isTimeValid),
            const SizedBox(height: 16),

            // 6. Field Polygon Satellite Map Widget with green/red photo pins
            CompletedTaskMapWidget(
              boundary: effectiveBoundary,
              farmName: activeAssignment?.location?.name ?? task.locationName,
              locationCode: activeAssignment?.location?.locationCode ?? 'LOC-001',
              targetLat: activeAssignment?.location?.latitude ?? task.latitude,
              targetLng: activeAssignment?.location?.longitude ?? task.longitude,
              photos: effectivePhotos,
              onOpenFullMap: () => _openFullMap(context, effectiveBoundary, effectivePhotos),
              onPhotoTap: (photo, index) => _openFullMap(
                context,
                effectiveBoundary,
                effectivePhotos,
                initialPhotoIndex: index,
              ),
            ),
            const SizedBox(height: 16),

            // 7. Submitted Photos Grid with Lightbox
            if (effectivePhotos.isNotEmpty) ...[
              SubmittedPhotosGrid(
                photos: effectivePhotos,
                boundary: effectiveBoundary,
                targetLat: task.latitude,
                targetLng: task.longitude,
                taskIsLate: task.isLate,
              ),
              const SizedBox(height: 16),
            ],

            // 8. Instructions Card (Golden Amber Tint)
            _buildInstructionsCard(),
            const SizedBox(height: 20),

            // 9. Bottom Return Button: [← কাজের তালিকায় ফিরুন]
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                label: const Text(
                  'কাজের তালিকায় ফিরুন',
                  style: TextStyle(
                    fontSize: 16.5,
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Top Success Banner: [✓] কাজের তথ্য জমা হয়েছে • কাজ সম্পন্ন হয়েছে
  Widget _buildTopSuccessBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7), // Mint green
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF15803D),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'কাজের তথ্য জমা হয়েছে',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  task.status == TaskStatus.submitted ? 'রিভিউ অপেক্ষায়' : 'কাজ সম্পন্ন হয়েছে',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Task Title, Category & [✓ সম্পন্ন] Status Badge
  Widget _buildTaskHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildCategoryIcon(task.thumbnailType),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                task.cropCategory.isNotEmpty ? task.cropCategory : task.subTitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // [✓ সম্পন্ন] Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 15),
              SizedBox(width: 4),
              Text(
                'সম্পন্ন',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15803D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Key Info Card: কাজের সময়, নির্ধারিত স্থান, জমা দেওয়ার সময়
  Widget _buildKeyInfoBox(String submissionTime) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        children: [
          // 1. কাজের সময়
          _buildInfoRow(
            icon: Icons.access_time_rounded,
            iconBg: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF475569),
            label: 'কাজের সময়',
            value: '${DateFormatter.formatDateString(task.date)}, ${task.timeRange}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFEDF2F7), height: 1),
          ),
          // 2. নির্ধারিত স্থান
          _buildInfoRow(
            icon: Icons.location_on_rounded,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: AppColors.primaryGreen,
            label: 'নির্ধারিত স্থান',
            value: '${task.locationName}, ${task.fullAddress}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFFEDF2F7), height: 1),
          ),
          // 3. জমা দেওয়ার সময়
          _buildInfoRow(
            icon: Icons.receipt_long_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            label: 'জমা দেওয়ার সময়',
            value: submissionTime,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Authoritative 4-State Verification Matrix:
  /// 1. সময়ের মধ্যে ও জোনের ভেতরে -> (✓) সব ঠিক, (✓) সঠিক লোকেশনে, (✓) সময়ের মধ্যে
  /// 2. সময় পেরিয়েছে ও জোনের ভেতরে -> (!) সময়ে সমস্যা, (✓) সঠিক লোকেশনে, (X) সময় পেরিয়েছে
  /// 3. সময়ের মধ্যে কিন্তু জোনের বাইরে -> (!) লোকেশনে সমস্যা, (X) লোকেশনের বাইরে, (✓) সময়ের মধ্যে
  /// 4. সময় পেরিয়েছে ও জোনের বাইরে -> (X) সময় ও লোকেশনে সমস্যা, (X) লোকেশনের বাইরে, (X) সময় পেরিয়েছে
  Widget _buildVerificationPills(bool isLocationValid, bool isTimeValid) {
    final String headerText;
    final IconData headerIcon;
    final Color headerBg;
    final Color headerBorder;
    final Color headerTextColor;

    if (isLocationValid && isTimeValid) {
      headerText = '(✓) সব ঠিক';
      headerIcon = Icons.check_circle_rounded;
      headerBg = const Color(0xFFDCFCE7);
      headerBorder = const Color(0xFF86EFAC);
      headerTextColor = const Color(0xFF15803D);
    } else if (isLocationValid && !isTimeValid) {
      headerText = '(!) সময়ে সমস্যা';
      headerIcon = Icons.error_rounded;
      headerBg = const Color(0xFFFEF3C7);
      headerBorder = const Color(0xFFFDE68A);
      headerTextColor = const Color(0xFFB45309);
    } else if (!isLocationValid && isTimeValid) {
      headerText = '(!) লোকেশনে সমস্যা';
      headerIcon = Icons.error_rounded;
      headerBg = const Color(0xFFFFEDD5);
      headerBorder = const Color(0xFFFED7AA);
      headerTextColor = const Color(0xFFC2410C);
    } else {
      headerText = '(X) সময় ও লোকেশনে সমস্যা';
      headerIcon = Icons.cancel_rounded;
      headerBg = const Color(0xFFFEE2E2);
      headerBorder = const Color(0xFFFCA5A5);
      headerTextColor = const Color(0xFFB91C1C);
    }

    return Column(
      children: [
        // Main Header Verification Pill
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: headerBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: headerBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(headerIcon, color: headerTextColor, size: 20),
              const SizedBox(width: 8),
              Text(
                headerText,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: headerTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Sub-pills: Location Tag & Time Tag
        Row(
          children: [
            // Location Tag
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isLocationValid
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLocationValid
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFCA5A5),
                  ),
                ),
                child: Text(
                  isLocationValid ? '(✓) সঠিক লোকেশনে' : '(X) লোকেশনের বাইরে',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isLocationValid
                        ? const Color(0xFF15803D)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Time Tag
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isTimeValid
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isTimeValid
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Text(
                  isTimeValid ? '(✓) সময়ের মধ্যে' : '(X) সময় পেরিয়েছে',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isTimeValid
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB45309),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Instructions Card
  Widget _buildInstructionsCard() {
    return Container(
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
            task.instructions.isNotEmpty
                ? task.instructions
                : 'নির্ধারিত সময়ে মাঠ পরিদর্শন করে সঠিক অবস্থান থেকে কাজের ছবি সংগ্রহ করুন।',
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF78350F),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(String type) {
    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (type.toLowerCase()) {
      case 'fish':
        iconData = Icons.water_rounded;
        iconColor = const Color(0xFF0284C7);
        bgColor = const Color(0xFFE0F2FE);
        break;
      case 'cow':
        iconData = Icons.pets_rounded;
        iconColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'fertilizer':
        iconData = Icons.science_rounded;
        iconColor = const Color(0xFF7C3AED);
        bgColor = const Color(0xFFEDE9FE);
        break;
      case 'vegetable':
      default:
        iconData = Icons.eco_rounded;
        iconColor = AppColors.primaryGreen;
        bgColor = const Color(0xFFE8F5E9);
        break;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  String _getSubmissionTimeFormatted() {
    if (task.submittedAt != null && task.submittedAt!.isNotEmpty) {
      return DateFormatter.formatDateTimeToBanglaTime(task.submittedAt);
    }
    if (activeAssignment?.submission?.submittedAt != null) {
      return DateFormatter.formatDateTimeToBanglaTime(
        activeAssignment!.submission!.submittedAt,
      );
    }
    if (task.completedAt != null && task.completedAt!.isNotEmpty) {
      return DateFormatter.formatDateTimeToBanglaTime(task.completedAt);
    }
    return '${DateFormatter.formatDateString(task.date)}, বিকাল ৫:২০';
  }
}
