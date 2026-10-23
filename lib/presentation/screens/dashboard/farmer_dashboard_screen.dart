import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/task_model.dart';
import '../../../services/task_service.dart';
import '../../../state/app_state.dart';
import '../../../state/farmer_app_state.dart';
import '../../widgets/farm_graphics.dart';
import '../../widgets/task_card.dart';
import '../../widgets/completed_task_card.dart';
import '../../widgets/farmer_bottom_nav_bar.dart';


class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _isSyncing = false;
  Set<String> _knownTaskIds = {};
  bool _isInitialSyncDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncTasks(isInitial: true);
      _startPolling();

      final syncState = ref.read(offlineSyncProvider);
      if (syncState.isOnline && syncState.pendingCount > 0 && !syncState.isSyncing) {
        ref.read(offlineSyncProvider.notifier).syncNow();
      }
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        _syncTasks();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resumed from background/lockscreen -> refresh immediately and resume polling
      _syncTasks();
      _startPolling();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Screen locked or app minimized -> pause polling to prevent server overload
      _pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _syncTasks({bool isInitial = false}) async {
    if (_isSyncing || !mounted) return;
    _isSyncing = true;

    try {
      final prevTasks = ref.read(taskListProvider).asData?.value ?? [];
      if (_knownTaskIds.isEmpty && prevTasks.isNotEmpty) {
        _knownTaskIds = prevTasks.map((t) => t.id).toSet();
      }

      await Future.wait([
        ref.read(taskListProvider.notifier).refresh(),
        ref.read(farmerTasksProvider.notifier).refresh(),
        ref.read(notificationStateProvider.notifier).loadNotifications(forceRefresh: true),
      ]);

      final syncState = ref.read(offlineSyncProvider);
      if (syncState.isOnline && syncState.pendingCount > 0 && !syncState.isSyncing) {
        ref.read(offlineSyncProvider.notifier).syncNow();
      }

      if (!mounted) return;

      final updatedTasks = ref.read(taskListProvider).asData?.value ?? [];

      if (!_isInitialSyncDone && isInitial) {
        _knownTaskIds = updatedTasks.map((t) => t.id).toSet();
        _isInitialSyncDone = true;
      } else if (_knownTaskIds.isNotEmpty) {
        final currentTaskIds = updatedTasks.map((t) => t.id).toSet();
        final newTasks = updatedTasks
            .where((t) => !_knownTaskIds.contains(t.id) && t.status != TaskStatus.completed)
            .toList();
        final removedTaskIds = _knownTaskIds.difference(currentTaskIds);

        _knownTaskIds = currentTaskIds;

        if (newTasks.isNotEmpty) {
          _showNewTaskNotification(newTasks.first);
        } else if (removedTaskIds.isNotEmpty) {
          _showTaskRemovedNotification();
        }
      } else {
        _knownTaskIds = updatedTasks.map((t) => t.id).toSet();
      }
    } catch (_) {
      // Silent error during background poll
    } finally {
      if (mounted) {
        _isSyncing = false;
      }
    }
  }

  void _showNewTaskNotification(TaskModel newTask) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'নতুন কাজ বরাদ্দ হয়েছে!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    newTask.title,
                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        action: SnackBarAction(
          label: 'দেখুন',
          textColor: Colors.white,
          onPressed: () {
            final now = DateTime.now();
            final todayStr =
                "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
            if (newTask.date.isNotEmpty && newTask.date != 'আজ' && newTask.date.compareTo(todayStr) > 0) {
              ref.read(taskTabFilterProvider.notifier).setFilter(TaskTabFilter.upcoming);
            } else {
              ref.read(taskTabFilterProvider.notifier).setFilter(TaskTabFilter.today);
            }

            ref.read(selectedTaskIdProvider.notifier).setTaskId(newTask.id);
            final assignments = ref.read(farmerTasksProvider).asData?.value;
            if (assignments != null && assignments.isNotEmpty) {
              try {
                final matching = assignments.firstWhere((a) => a.id.toString() == newTask.id);
                ref.read(selectedAssignmentProvider.notifier).setAssignment(matching);
              } catch (_) {}
            }
            context.push('/task-details');
          },
        ),
      ),
    );
  }

  void _showTaskRemovedNotification() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'কাজের তালিকা আপডেট হয়েছে',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'একটি কাজ বরাদ্দ প্রত্যাহার/মুছে ফেলা হয়েছে।',
                    style: TextStyle(fontSize: 12.5, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);
    final user = ref.watch(currentUserProvider);
    final authState = ref.watch(farmerAuthProvider);
    final currentFilter = ref.watch(taskTabFilterProvider);
    final syncState = ref.watch(offlineSyncProvider);
    final notifications = ref.watch(notificationStateProvider);
    final unreadNotifs = notifications.where((n) => !n.isRead).length;
    ref.watch(farmerTasksProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: Column(
        children: [
          // Custom Curved Green Header with Village Natural Scenario
          VillageHeaderBackground(
            height: MediaQuery.of(context).padding.top + 210,
            child: Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                left: 20,
                right: 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'আজকের কাজ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 1.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          DateFormatter.formatFullDateWithDay(),
                          style: TextStyle(
                            fontSize: 14.5,
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w500,
                            shadows: const [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notifications & Profile Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Notification Bell with Unread Count Badge -> Opens Notifications Screen
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.notifications_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              tooltip: 'বিজ্ঞপ্তি',
                              onPressed: () {
                                context.push('/notifications');
                              },
                            ),
                          ),
                          if (unreadNotifs > 0)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$unreadNotifs',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // More / Profile Button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => _showOptionsDialog(context, ref),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Body
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () async => _syncTasks(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                  // Offline Status & Sync Banner (Phase 12B Offline Support)
                  if (!syncState.isOnline || syncState.pendingCount > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: syncState.isOnline ? const Color(0xFFFEF3C7) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            syncState.isOnline ? Icons.sync_rounded : Icons.wifi_off_rounded,
                            color: Colors.amber.shade800,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  syncState.isOnline
                                      ? (syncState.isSyncing ? 'সার্ভারে সিঙ্ক হচ্ছে...' : '${syncState.pendingCount}টি রিপোর্ট ব্যাকগ্রাউন্ডে সিঙ্ক হচ্ছে')
                                      : 'অফলাইন মোড (ইন্টারনেট সংযোগ নেই)',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  syncState.isOnline
                                      ? 'সার্ভারে সফলভাবে জমা হওয়ার পর এটি স্বয়ংক্রিয়ভাবে মুছে যাবে।'
                                      : 'ইন্টারনেট সংযোগ পেলে স্বয়ংক্রিয়ভাবে সার্ভারে জমা হবে।',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (syncState.isOnline && syncState.pendingCount > 0)
                            ElevatedButton(
                              onPressed: syncState.isSyncing
                                  ? null
                                  : () => ref.read(offlineSyncProvider.notifier).syncNow(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: syncState.isSyncing
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text(
                                      'সিঙ্ক করুন',
                                      style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                            ),
                        ],
                      ),
                    ),

                  // Greeting Card (Clickable to view Profile)
                  InkWell(
                    onTap: () => context.push('/profile'),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF7F1),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFDCEDE0), width: 1.2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const FarmerAvatar(size: 64),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'শুভ সকাল,',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${authState.profile?.fullName ?? user?.name ?? "কৃষক"}!',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    if (authState.profile?.farmerCode != null && authState.profile!.farmerCode.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGreen.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'আইডি: ${authState.profile!.farmerCode}',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGreen,
                                          ),
                                        ),
                                      ),
                                    tasksAsync.when(
                                      data: (tasks) {
                                        final activeCount = tasks.where((t) => t.status != TaskStatus.completed).length;
                                        return Text(
                                          activeCount > 0 ? 'আজ $activeCountটি কাজ আছে' : 'আজ কোনো কাজ বাকি নেই',
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        );
                                      },
                                      loading: () => const Text(
                                        'লোড হচ্ছে...',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      error: (_, _) => const Text(
                                        'আজকের কাজ',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Dashboard Tabs: Smooth Sliding Segmented Control
                  _buildSegmentedFilterTabs(
                    currentFilter: currentFilter,
                    ref: ref,
                  ),

                  const SizedBox(height: 16),

                  // Tasks List
                  tasksAsync.when(
                    data: (tasks) {
                      final now = DateTime.now();
                      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                      final filteredTasks = tasks.where((task) {
                        final isCompleted = task.status == TaskStatus.completed || task.status == TaskStatus.submitted;
                        final isUpcoming = task.date.isNotEmpty && task.date != 'আজ' && task.date.compareTo(todayStr) > 0;
                        final isToday = (task.date == todayStr || task.date == 'আজ') && !isCompleted;
                        final isOverdue = task.date.isNotEmpty && task.date != 'আজ' && task.date.compareTo(todayStr) < 0 && !isCompleted;

                        if (currentFilter == TaskTabFilter.today) {
                          return isToday;
                        } else if (currentFilter == TaskTabFilter.upcoming) {
                          return isUpcoming && !isCompleted;
                        } else if (currentFilter == TaskTabFilter.pending) {
                          return (isOverdue || task.badgeText == 'বাকি আছে' || task.badgeText == 'সময় পার (বিলম্বিত)' || task.status == TaskStatus.inProgress || task.status == TaskStatus.scheduled) && !isCompleted && !isUpcoming;
                        } else {
                          return isCompleted;
                        }
                      }).toList();

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey(currentFilter),
                          child: filteredTasks.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(32),
                                  alignment: Alignment.center,
                                  child: Column(
                                    children: [
                                      Icon(Icons.task_alt_rounded, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        currentFilter == TaskTabFilter.completed
                                            ? 'এখনও কোনো কাজ সম্পন্ন হয়নি।'
                                            : (currentFilter == TaskTabFilter.upcoming
                                                ? 'কোনো আসন্ন কাজ নির্ধারিত নেই।'
                                                : (currentFilter == TaskTabFilter.today
                                                    ? 'আজকের জন্য কোনো কাজ নির্ধারিত নেই।'
                                                    : 'এই ক্যাটাগরিতে কোনো কাজ নেই।')),
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (currentFilter == TaskTabFilter.completed)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                                        child: Row(
                                          children: [
                                            const Text(
                                              'সম্পন্ন কাজ',
                                              style: TextStyle(
                                                fontSize: 16.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${DateFormatter.toBanglaDigits(filteredTasks.length)}টি কাজ',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ...filteredTasks.map((task) {
                                      if (currentFilter == TaskTabFilter.completed) {
                                        return CompletedTaskCard(
                                          task: task,
                                          onTap: () {
                                            ref.read(selectedTaskIdProvider.notifier).setTaskId(task.id);
                                            final assignments = ref.read(farmerTasksProvider).asData?.value;
                                            if (assignments != null && assignments.isNotEmpty) {
                                              try {
                                                final matching = assignments.firstWhere((a) => a.id.toString() == task.id);
                                                ref.read(selectedAssignmentProvider.notifier).setAssignment(matching);
                                              } catch (_) {}
                                            }
                                            context.push('/task-details');
                                          },
                                        );
                                      }
                                      return TaskCard(
                                        task: task,
                                        onTap: () {
                                          ref.read(selectedTaskIdProvider.notifier).setTaskId(task.id);
                                          final assignments = ref.read(farmerTasksProvider).asData?.value;
                                          if (assignments != null && assignments.isNotEmpty) {
                                            try {
                                              final matching = assignments.firstWhere((a) => a.id.toString() == task.id);
                                              ref.read(selectedAssignmentProvider.notifier).setAssignment(matching);
                                            } catch (_) {}
                                          }
                                          context.push('/task-details');
                                        },
                                      );
                                    }),
                                  ],
                                ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(color: AppColors.primaryGreen),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text('তথ্য লোড করতে সমস্যা হয়েছে: $err'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  ),
),
],
),
bottomNavigationBar: const FarmerBottomNavBar(currentIndex: 0),
);
  }

  Widget _buildSegmentedFilterTabs({
    required TaskTabFilter currentFilter,
    required WidgetRef ref,
  }) {
    final activeIndex = switch (currentFilter) {
      TaskTabFilter.today => 0,
      TaskTabFilter.upcoming => 1,
      TaskTabFilter.pending => 2,
      TaskTabFilter.completed => 3,
    };

    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / 4;
          return Stack(
            children: [
              // Single Smooth Sliding Indicator Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeInOutCubic,
                left: activeIndex * tabWidth,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 5,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              // Tab Item Labels
              Row(
                children: [
                  _buildTabItem(
                    title: 'আজকের',
                    isSelected: currentFilter == TaskTabFilter.today,
                    onTap: () => ref.read(taskTabFilterProvider.notifier).setFilter(TaskTabFilter.today),
                  ),
                  _buildTabItem(
                    title: 'আসন্ন কাজ',
                    isSelected: currentFilter == TaskTabFilter.upcoming,
                    onTap: () => ref.read(taskTabFilterProvider.notifier).setFilter(TaskTabFilter.upcoming),
                  ),
                  _buildTabItem(
                    title: 'বাকি কাজ',
                    isSelected: currentFilter == TaskTabFilter.pending,
                    onTap: () => ref.read(taskTabFilterProvider.notifier).setFilter(TaskTabFilter.pending),
                  ),
                  _buildTabItem(
                    title: 'সম্পন্ন',
                    isSelected: currentFilter == TaskTabFilter.completed,
                    onTap: () => ref.read(taskTabFilterProvider.notifier).setFilter(TaskTabFilter.completed),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: AppColors.primaryGreen.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  void _showOptionsDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'কৃষক মেনু ও সেটিংস (Farmer Menu)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: AppColors.primaryGreen),
                  title: const Text('প্রোফাইল দেখুন (Profile)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_none_rounded, color: AppColors.primaryGreen),
                  title: const Text('বিজ্ঞপ্তি সমূহ (Notifications)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/notifications');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.errorRed),
                  title: const Text('লগআউট (Logout)'),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(farmerAuthProvider.notifier).logout();
                    context.go('/login');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
