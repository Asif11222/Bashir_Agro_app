import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/notification_model.dart';
import '../../../state/app_state.dart';
import '../../../state/farmer_app_state.dart';
import '../../widgets/farmer_bottom_nav_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationStateProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;

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
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: const Text(
          'বিজ্ঞপ্তি ও সতর্কতা',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: () {
                ref.read(notificationStateProvider.notifier).markAllAsRead();
              },
              icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
              label: const Text('সব পঠিত', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () =>
              ref.read(notificationStateProvider.notifier).loadNotifications(forceRefresh: true),
          child: notifications.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 56,
                              color: Color(0xFFCBD5E1),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'কোনো নতুন বিজ্ঞপ্তি নেই।',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'রিফ্রেশ করতে নিচে টানুন',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _buildNotificationCard(context, ref, notif);
                  },
                ),
        ),
      bottomNavigationBar: const FarmerBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotificationModel notif,
  ) {
    Color iconColor;
    Color bgColor;
    IconData iconData;

    switch (notif.eventType) {
      case NotificationEventType.newTask:
        iconColor = AppColors.primaryGreen;
        bgColor = const Color(0xFFE8F5E9);
        iconData = Icons.assignment_add;
        break;
      case NotificationEventType.reminder:
        iconColor = Colors.orange.shade800;
        bgColor = const Color(0xFFFFF3E0);
        iconData = Icons.alarm_rounded;
        break;
      case NotificationEventType.approval:
        iconColor = Colors.blue.shade700;
        bgColor = const Color(0xFFE3F2FD);
        iconData = Icons.verified_rounded;
        break;
      case NotificationEventType.rejection:
        iconColor = AppColors.errorRed;
        bgColor = AppColors.errorRedBg;
        iconData = Icons.warning_amber_rounded;
        break;
      case NotificationEventType.cancellation:
        iconColor = AppColors.errorRed;
        bgColor = AppColors.errorRedBg;
        iconData = Icons.cancel_outlined;
        break;
    }

    return InkWell(
      onTap: () {
        if (!notif.isRead) {
          ref.read(notificationStateProvider.notifier).markAsRead(notif.id);
        }
        if (notif.eventType == NotificationEventType.cancellation) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                notif.message.isNotEmpty
                    ? notif.message
                    : 'এই কাজের বরাদ্দটি অ্যাডমিন কর্তৃক প্রত্যাহার/মুছে ফেলা হয়েছে।',
              ),
              backgroundColor: AppColors.errorRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        if (notif.assignmentId != null) {
          final assignmentId = notif.assignmentId!;
          ref.read(selectedTaskIdProvider.notifier).setTaskId(assignmentId.toString());
          final assignments = ref.read(farmerTasksProvider).asData?.value;
          if (assignments != null && assignments.isNotEmpty) {
            try {
              final matching = assignments.firstWhere(
                (a) => a.id == assignmentId || a.id.toString() == assignmentId.toString(),
              );
              ref.read(selectedAssignmentProvider.notifier).setAssignment(matching);
            } catch (_) {}
          }
          context.push('/task-details');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead ? const Color(0xFFE2E8F0) : AppColors.primaryGreen.withValues(alpha: 0.35),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notif.eventNameBengali,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: iconColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(notif.timestamp),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ঘন্টা আগে';
    } else {
      return '${diff.inDays} দিন আগে';
    }
  }
}
