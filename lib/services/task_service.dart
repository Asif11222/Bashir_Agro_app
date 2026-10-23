import '../core/constants/api_constants.dart';

import '../core/storage/local_storage_service.dart';
import '../models/task_assignment_model.dart';
import 'api_service.dart';

enum TaskTabFilter {
  today,
  upcoming,
  pending,
  completed,
}

class TaskService {
  final ApiService _apiService;
  final LocalStorageService _storage;

  TaskService({ApiService? apiService, LocalStorageService? storage})
      : _apiService = apiService ?? ApiService(),
        _storage = storage ?? LocalStorageService.instance;

  Future<List<TaskAssignmentModel>>? _inFlightFetch;

  /// Fetch assignments from API or fallback to local cache (with in-flight deduplication)
  Future<List<TaskAssignmentModel>> fetchAssignments({bool forceRefresh = false}) async {
    if (_inFlightFetch != null) {
      return _inFlightFetch!;
    }

    _inFlightFetch = _executeFetchAssignments();
    try {
      return await _inFlightFetch!;
    } finally {
      _inFlightFetch = null;
    }
  }

  Future<List<TaskAssignmentModel>> _executeFetchAssignments() async {
    try {
      final assignments = await _apiService.getAssignments();

      // Save to local cache
      final jsonList = assignments.map((a) => a.toJson()).toList();
      await _storage.setJson(ApiConstants.cachedTasksKey, jsonList);

      return assignments;
    } catch (e) {
      // Network failure -> load from offline cache
      final cached = getCachedAssignments();
      if (cached.isNotEmpty) {
        return cached;
      }
      rethrow;
    }
  }

  /// Read cached assignments
  List<TaskAssignmentModel> getCachedAssignments() {
    final cached = _storage.getJson(ApiConstants.cachedTasksKey);
    if (cached is List) {
      return cached
          .map((item) => TaskAssignmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Get today's tasks
  List<TaskAssignmentModel> filterTodayTasks(List<TaskAssignmentModel> allTasks) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return allTasks.where((task) {
      final isToday = task.scheduledDate == todayStr || task.scheduledDate.isEmpty || task.scheduledDate == 'আজ';
      return isToday && !task.isCompleted;
    }).toList();
  }

  /// Get upcoming tasks (scheduled for future dates)
  List<TaskAssignmentModel> filterUpcomingTasks(List<TaskAssignmentModel> allTasks) {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    return allTasks.where((task) {
      if (task.isCompleted) return false;
      if (task.scheduledDate.isEmpty || task.scheduledDate == 'আজ') return false;
      return task.scheduledDate.compareTo(todayStr) > 0;
    }).toList();
  }

  /// Get pending tasks (assigned, in_progress, overdue)
  List<TaskAssignmentModel> filterPendingTasks(List<TaskAssignmentModel> allTasks) {
    return allTasks.where((task) => !task.isCompleted).toList();
  }

  /// Get completed tasks
  List<TaskAssignmentModel> filterCompletedTasks(List<TaskAssignmentModel> allTasks) {
    return allTasks.where((task) => task.isCompleted).toList();
  }

  /// Start a task
  Future<TaskAssignmentModel> startTask(int assignmentId) async {
    try {
      final updated = await _apiService.startAssignment(assignmentId);
      // Update local cache
      final cached = getCachedAssignments();
      final index = cached.indexWhere((t) => t.id == assignmentId);
      if (index != -1) {
        cached[index] = updated;
        await _storage.setJson(
          ApiConstants.cachedTasksKey,
          cached.map((e) => e.toJson()).toList(),
        );
      }
      return updated;
    } catch (_) {
      // If offline, update locally
      final cached = getCachedAssignments();
      final index = cached.indexWhere((t) => t.id == assignmentId);
      if (index != -1) {
        final current = cached[index];
        final updated = TaskAssignmentModel(
          id: current.id,
          scheduledDate: current.scheduledDate,
          startTime: current.startTime,
          endTime: current.endTime,
          priority: current.priority,
          status: 'in_progress',
          notes: current.notes,
          assignedAt: current.assignedAt,
          startedAt: DateTime.now().toIso8601String(),
          completedAt: current.completedAt,
          task: current.task,
          location: current.location,
          farmer: current.farmer,
        );
        cached[index] = updated;
        await _storage.setJson(
          ApiConstants.cachedTasksKey,
          cached.map((e) => e.toJson()).toList(),
        );
        return updated;
      }
      rethrow;
    }
  }
}
