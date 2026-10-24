import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/task_model.dart';
import 'farm_graphics.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
  });

  Color _getBadgeBgColor() {
    if (task.badgeText == 'সম্পন্ন') {
      return const Color(0xFFDCFCE7);
    } else if (task.badgeText == 'চলছে') {
      return AppColors.badgeRunningBg;
    } else if (task.badgeText == 'বাকি আছে') {
      return AppColors.badgePendingBg;
    } else if (task.badgeText == 'সময় পার (বিলম্বিত)' || task.badgeText == 'দেরি হয়েছে') {
      return const Color(0xFFFEF3C7);
    } else if (task.badgeText.contains('আসন্ন')) {
      return const Color(0xFFEFF6FF);
    } else if (task.badgeText == 'রিভিউ অপেক্ষায়') {
      return const Color(0xFFF3E8FF);
    }
    return AppColors.badgeTodayBg;
  }

  Color _getBadgeTextColor() {
    if (task.badgeText == 'সম্পন্ন') {
      return const Color(0xFF15803D);
    } else if (task.badgeText == 'চলছে') {
      return AppColors.badgeRunningText;
    } else if (task.badgeText == 'বাকি আছে') {
      return AppColors.badgePendingText;
    } else if (task.badgeText == 'সময় পার (বিলম্বিত)' || task.badgeText == 'দেরি হয়েছে') {
      return const Color(0xFFB45309);
    } else if (task.badgeText.contains('আসন্ন')) {
      return const Color(0xFF1D4ED8);
    } else if (task.badgeText == 'রিভিউ অপেক্ষায়') {
      return const Color(0xFF7E22CE);
    }
    return AppColors.badgeTodayText;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Thumbnail
                TaskThumbnailWidget(
                  type: task.thumbnailType,
                  size: 72,
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Badge row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: _getBadgeBgColor(),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              task.badgeText,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getBadgeTextColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        task.subTitle,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Time
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14.5,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              task.timeRange,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 15,
                            color: AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              task.locationName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
