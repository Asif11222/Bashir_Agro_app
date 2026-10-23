import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/task_model.dart';
import 'farm_graphics.dart';

class CompletedTaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const CompletedTaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = task.completedSubmissionType;

    // 1. Theme configuration according to the 4 states
    final (
      Color cardBg,
      Color borderColor,
      String headerLabel,
      IconData headerIcon,
      Color headerBg,
      Color headerTextColor,
      bool geoPassed,
      bool isLate,
    ) = switch (type) {
      CompletedSubmissionType.allGood => (
          Colors.white,
          const Color(0xFFE2E8F0),
          'সব ঠিক',
          Icons.check_circle_rounded,
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          true,
          false,
        ),
      CompletedSubmissionType.lateOnly => (
          const Color(0xFFFFFDF8),
          const Color(0xFFFDE68A),
          'সময়ে সমস্যা',
          Icons.error_rounded,
          const Color(0xFFFEF3C7),
          const Color(0xFFB45309),
          true,
          true,
        ),
      CompletedSubmissionType.outsideZoneOnly => (
          const Color(0xFFFFFDF9),
          const Color(0xFFFED7AA),
          'লোকেশনে সমস্যা',
          Icons.error_rounded,
          const Color(0xFFFFEDD5),
          const Color(0xFFC2410C),
          false,
          false,
        ),
      CompletedSubmissionType.bothIssues => (
          const Color(0xFFFFFBFB),
          const Color(0xFFFECACA),
          'সময় ও লোকেশনে সমস্যা',
          Icons.cancel_rounded,
          const Color(0xFFFEE2E2),
          const Color(0xFFB91C1C),
          false,
          true,
        ),
    };

    // Formatted submission time
    final submittedTime = task.submittedAt != null && task.submittedAt!.isNotEmpty
        ? task.submittedAt!
        : 'সকাল ৯:১৫';

    // Photos list
    final photos = task.evidencePhotoUrls;
    final int photoCount = photos.isNotEmpty ? photos.length : (type == CompletedSubmissionType.bothIssues ? 5 : (type == CompletedSubmissionType.lateOnly ? 1 : 3));

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Status Indicator pill + 'সম্পন্ন' pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Status Badge (e.g., সব ঠিক / সময়ে সমস্যা / লোকেশনে সমস্যা / সময় ও লোকেশনে সমস্যা)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: headerBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(headerIcon, size: 13, color: headerTextColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                headerLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: headerTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // 'সম্পন্ন' Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F4EA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'সম্পন্ন',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006837),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),

                // Main Content Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task Thumbnail Graphic (Fish, Cow, Plant, Fertilizer)
                    TaskThumbnailWidget(
                      type: task.thumbnailType,
                      size: 56,
                      borderRadius: 12,
                    ),
                    const SizedBox(width: 8),

                    // Left Column: Task details
                    Expanded(
                      flex: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            task.subTitle,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 7),

                          // Scheduled Time
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'নির্ধারিত: ${task.timeRange}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Location
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 13,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  task.locationName,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),

                          // Submitted Time
                          Row(
                            children: [
                              const Icon(
                                Icons.event_available_rounded,
                                size: 13,
                                color: Color(0xFF006837),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'জমা: $submittedTime',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Right Column: 2 Verification Pills & Evidence Thumbnails Gallery
                    Expanded(
                      flex: 11,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // 1. Geofence Status Pill
                          _buildVerificationPill(
                            isPositive: geoPassed,
                            positiveLabel: 'সঠিক লোকেশনে',
                            negativeLabel: 'লোকেশনের বাইরে',
                          ),
                          const SizedBox(height: 5),

                          // 2. Time Status Pill
                          _buildVerificationPill(
                            isPositive: !isLate,
                            positiveLabel: 'সময়ের মধ্যে',
                            negativeLabel: 'সময় পেরিয়েছে',
                          ),
                          const SizedBox(height: 8),

                          // 3. Evidence Photos row + Count pill + Chevron
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Photo previews
                                _buildPhotoPreviews(photos, task.thumbnailType, photoCount),
                                const SizedBox(width: 4),

                                // Count Badge (e.g. ৩টি ছবি)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${DateFormatter.toBanglaDigits(photoCount)}টি ছবি',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 1),

                                // Chevron arrow
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 15,
                                  color: Color(0xFF94A3B8),
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildVerificationPill({
    required bool isPositive,
    required String positiveLabel,
    required String negativeLabel,
  }) {
    final bgColor = isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final textColor = isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C);
    final icon = isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final label = isPositive ? positiveLabel : negativeLabel;

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11.5, color: textColor),
            const SizedBox(width: 3.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreviews(List<String> photos, String thumbType, int totalCount) {
    // If real uploaded photo URLs exist, render network thumbnail
    // Else render fallback stylized preview tiles
    final firstUrl = photos.isNotEmpty ? photos[0] : null;
    final secondUrl = photos.length > 1 ? photos[1] : null;

    final hasOverlay = totalCount > 2;
    final overlayCount = totalCount - 2;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSingleThumb(firstUrl, thumbType, 0),
        if (totalCount > 1) ...[
          const SizedBox(width: 3),
          Stack(
            children: [
              _buildSingleThumb(secondUrl, thumbType, 1),
              if (hasOverlay)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+${DateFormatter.toBanglaDigits(overlayCount)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSingleThumb(String? url, String thumbType, int index) {
    const double thumbSize = 24;
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Image.network(
          url,
          width: thumbSize,
          height: thumbSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackTile(thumbType, index),
        ),
      );
    }
    return _buildFallbackTile(thumbType, index);
  }

  Widget _buildFallbackTile(String thumbType, int index) {
    const double thumbSize = 24;
    // Stylized subtle farm scene preview tile
    final (Color bg, IconData icon, Color iconColor) = switch (thumbType) {
      'fish' => (
          const Color(0xFFBAE6FD),
          Icons.waves_rounded,
          const Color(0xFF0369A1),
        ),
      'cow' => (
          const Color(0xFFFED7AA),
          Icons.pets_rounded,
          const Color(0xFFC2410C),
        ),
      'fertilizer' => (
          const Color(0xFFFEF08A),
          Icons.grain_rounded,
          const Color(0xFF854D0E),
        ),
      _ => (
          const Color(0xFFBBF7D0),
          Icons.eco_rounded,
          const Color(0xFF15803D),
        ),
    };

    return Container(
      width: thumbSize,
      height: thumbSize,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.white, width: 0.8),
      ),
      child: Center(
        child: Icon(icon, size: 12, color: iconColor),
      ),
    );
  }
}
