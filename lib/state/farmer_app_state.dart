import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../models/auth_model.dart';
import '../models/task_assignment_model.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';
import '../services/gps_service.dart';
import '../services/offline_sync_service.dart';
import '../services/notification_service.dart';
import '../services/location_resolution_service.dart';
export '../services/location_resolution_service.dart';
import 'app_state.dart';

// Services Singletons
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final apiServiceProvider = Provider<ApiService>((ref) => ApiService(client: ref.watch(apiClientProvider)));
final authServiceProvider = Provider<AuthService>((ref) => AuthService(apiService: ref.watch(apiServiceProvider)));
final taskServiceProvider = Provider<TaskService>((ref) => TaskService(apiService: ref.watch(apiServiceProvider)));
final gpsServiceProvider = Provider<GpsService>((ref) => GpsService());
final locationResolutionServiceProvider = Provider<LocationResolutionService>(
  (ref) => LocationResolutionService(apiService: ref.watch(apiServiceProvider)),
);
final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) => OfflineSyncService());
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(apiService: ref.watch(apiServiceProvider)),
);

// Auth State
class FarmerAuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final AuthUser? user;
  final FarmerProfile? profile;
  final String? errorMessage;

  const FarmerAuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.profile,
    this.errorMessage,
  });

  FarmerAuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    AuthUser? user,
    FarmerProfile? profile,
    String? errorMessage,
  }) {
    return FarmerAuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
    );
  }
}

class FarmerAuthNotifier extends Notifier<FarmerAuthState> {
  @override
  FarmerAuthState build() {
    final authService = ref.read(authServiceProvider);
    if (authService.isAuthenticated && authService.currentUser != null) {
      return FarmerAuthState(
        isAuthenticated: true,
        user: authService.currentUser,
        profile: authService.farmerProfile,
      );
    }
    return const FarmerAuthState(isAuthenticated: false);
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final authService = ref.read(authServiceProvider);
      final response = await authService.login(phone, password);

      if (response.success) {
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          user: response.user,
          profile: response.farmerProfile,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const FarmerAuthState(isAuthenticated: false);
  }
}

final farmerAuthProvider =
    NotifierProvider<FarmerAuthNotifier, FarmerAuthState>(FarmerAuthNotifier.new);

// Active Tab Filter (Today, Pending, Completed)
class TabFilterNotifier extends Notifier<TaskTabFilter> {
  @override
  TaskTabFilter build() => TaskTabFilter.today;
  void setFilter(TaskTabFilter filter) => state = filter;
}

final taskTabFilterProvider =
    NotifierProvider<TabFilterNotifier, TaskTabFilter>(TabFilterNotifier.new);

// Task Assignments List Notifier
class FarmerTasksNotifier extends AsyncNotifier<List<TaskAssignmentModel>> {
  @override
  Future<List<TaskAssignmentModel>> build() async {
    final taskService = ref.read(taskServiceProvider);
    try {
      return await taskService.fetchAssignments();
    } catch (_) {
      return taskService.getCachedAssignments();
    }
  }

  Future<void> refresh() async {
    final taskService = ref.read(taskServiceProvider);
    try {
      final tasks = await taskService.fetchAssignments(forceRefresh: true);
      state = AsyncData(tasks);
    } catch (_) {
      final cached = taskService.getCachedAssignments();
      state = AsyncData(cached);
    }
  }

  Future<void> startTask(int assignmentId) async {
    final taskService = ref.read(taskServiceProvider);
    await taskService.startTask(assignmentId);
    await refresh();
  }
}

final farmerTasksProvider =
    AsyncNotifierProvider<FarmerTasksNotifier, List<TaskAssignmentModel>>(FarmerTasksNotifier.new);

// Filtered tasks provider
final filteredTasksProvider = Provider<List<TaskAssignmentModel>>((ref) {
  final tasksAsync = ref.watch(farmerTasksProvider);
  final filter = ref.watch(taskTabFilterProvider);
  final taskService = ref.read(taskServiceProvider);

  return tasksAsync.when(
    data: (tasks) {
      switch (filter) {
        case TaskTabFilter.today:
          return taskService.filterTodayTasks(tasks);
        case TaskTabFilter.upcoming:
          return taskService.filterUpcomingTasks(tasks);
        case TaskTabFilter.pending:
          return taskService.filterPendingTasks(tasks);
        case TaskTabFilter.completed:
          return taskService.filterCompletedTasks(tasks);
      }
    },
    loading: () => [],
    error: (_, _) => [],
  );
});

// Selected Task Assignment Notifier
class SelectedAssignmentNotifier extends Notifier<TaskAssignmentModel?> {
  @override
  TaskAssignmentModel? build() {
    final tasks = ref.watch(farmerTasksProvider).asData?.value;
    final selectedId = ref.watch(selectedTaskIdProvider);
    if (tasks == null || tasks.isEmpty) return null;
    if (selectedId.isNotEmpty) {
      try {
        final idInt = int.tryParse(selectedId);
        return tasks.firstWhere(
          (t) => t.id.toString() == selectedId || (idInt != null && t.id == idInt),
          orElse: () => tasks.first,
        );
      } catch (_) {}
    }
    return tasks.first;
  }

  void setAssignment(TaskAssignmentModel assignment) => state = assignment;
}

final selectedAssignmentProvider =
    NotifierProvider<SelectedAssignmentNotifier, TaskAssignmentModel?>(SelectedAssignmentNotifier.new);

final activeAssignmentProvider = selectedAssignmentProvider;

// Offline Synchronization State
class OfflineSyncState {
  final bool isOnline;
  final int pendingCount;
  final bool isSyncing;
  final String? lastSyncMessage;

  const OfflineSyncState({
    this.isOnline = true,
    this.pendingCount = 0,
    this.isSyncing = false,
    this.lastSyncMessage,
  });

  OfflineSyncState copyWith({
    bool? isOnline,
    int? pendingCount,
    bool? isSyncing,
    String? lastSyncMessage,
  }) {
    return OfflineSyncState(
      isOnline: isOnline ?? this.isOnline,
      pendingCount: pendingCount ?? this.pendingCount,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncMessage: lastSyncMessage,
    );
  }
}

class OfflineSyncNotifier extends Notifier<OfflineSyncState> {
  @override
  OfflineSyncState build() {
    final service = ref.read(offlineSyncServiceProvider);
    return OfflineSyncState(
      isOnline: service.isOnline,
      pendingCount: service.pendingCount,
    );
  }

  void toggleOnlineStatus() {
    final service = ref.read(offlineSyncServiceProvider);
    final newStatus = !state.isOnline;
    service.setOnlineStatus(newStatus);
    state = state.copyWith(isOnline: newStatus, pendingCount: service.pendingCount);
  }

  Future<void> syncNow() async {
    if (state.isSyncing) return;
    state = state.copyWith(isSyncing: true, lastSyncMessage: null);

    final service = ref.read(offlineSyncServiceProvider);
    try {
      final synced = await service.syncPendingSubmissions();
      state = state.copyWith(
        isSyncing: false,
        pendingCount: service.pendingCount,
        lastSyncMessage: '$synced টি অফলাইন রিপোর্ট সফলভাবে সার্ভারে সিঙ্ক হয়েছে।',
      );
      // Refresh tasks
      ref.read(farmerTasksProvider.notifier).refresh();
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        lastSyncMessage: 'সিঙ্ক করতে ত্রুটি: $e',
      );
    }
  }

  void updatePendingCount() {
    final service = ref.read(offlineSyncServiceProvider);
    state = state.copyWith(pendingCount: service.pendingCount);
  }
}

final offlineSyncProvider =
    NotifierProvider<OfflineSyncNotifier, OfflineSyncState>(OfflineSyncNotifier.new);

// Notifications State Notifier
class NotificationStateNotifier extends Notifier<List<AppNotificationModel>> {
  @override
  List<AppNotificationModel> build() {
    final service = ref.read(notificationServiceProvider);

    // Listen to real-time FCM events
    final subscription = service.notificationStream.listen((newNotif) {
      state = [newNotif, ...state.where((n) => n.id != newNotif.id)];
    });
    ref.onDispose(() => subscription.cancel());

    // Fetch fresh notifications from server in background
    Future.microtask(() => loadNotifications());

    return service.getNotifications();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  /// Fetch notifications from backend API and update state
  Future<void> loadNotifications({bool forceRefresh = false}) async {
    final service = ref.read(notificationServiceProvider);
    final fresh = await service.fetchNotifications(forceRefresh: forceRefresh);
    state = fresh;
  }

  Future<void> markAsRead(String id) async {
    final service = ref.read(notificationServiceProvider);
    await service.markAsRead(id);
    state = [
      for (final n in state)
        if (n.id == id)
          AppNotificationModel(
            id: n.id,
            eventType: n.eventType,
            title: n.title,
            message: n.message,
            timestamp: n.timestamp,
            assignmentId: n.assignmentId,
            isRead: true,
          )
        else
          n,
    ];
  }

  Future<void> markAllAsRead() async {
    final service = ref.read(notificationServiceProvider);
    await service.markAllAsRead();
    state = [
      for (final n in state)
        AppNotificationModel(
          id: n.id,
          eventType: n.eventType,
          title: n.title,
          message: n.message,
          timestamp: n.timestamp,
          assignmentId: n.assignmentId,
          isRead: true,
        ),
    ];
  }
}

final notificationStateProvider =
    NotifierProvider<NotificationStateNotifier, List<AppNotificationModel>>(
        NotificationStateNotifier.new);
