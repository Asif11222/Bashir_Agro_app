import 'dart:io';
import 'dart:typed_data';
import '../models/task_model.dart';
import '../models/task_photo_model.dart';
import '../../models/task_assignment_model.dart';
import '../../services/api_service.dart';
import '../../services/task_service.dart';
import '../../core/utils/date_formatter.dart';
import 'task_repository.dart';

class ApiTaskRepository implements TaskRepository {
  final TaskService _taskService;
  final ApiService _apiService;
  List<TaskModel> _cachedTasks = [];

  ApiTaskRepository({TaskService? taskService, ApiService? apiService})
      : _taskService = taskService ?? TaskService(),
        _apiService = apiService ?? ApiService();

  @override
  Future<List<TaskModel>> getTodayTasks() async {
    try {
      final assignments = await _taskService.fetchAssignments(forceRefresh: true);
      _cachedTasks = assignments.map(taskModelFromAssignment).toList();
      return List.unmodifiable(_cachedTasks);
    } catch (_) {
      // Offline fallback: try reading from local cache
      final cached = _taskService.getCachedAssignments();
      _cachedTasks = cached.map(taskModelFromAssignment).toList();
      return List.unmodifiable(_cachedTasks);
    }
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    try {
      return _cachedTasks.firstWhere((t) => t.id == id);
    } catch (_) {
      final tasks = await getTodayTasks();
      try {
        return tasks.firstWhere((t) => t.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  @override
  Future<void> addPhotoToTask(String taskId, TaskPhotoModel photo) async {
    final index = _cachedTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedPhotos = List<TaskPhotoModel>.from(_cachedTasks[index].photos)..add(photo);
      _cachedTasks[index] = _cachedTasks[index].copyWith(
        photos: updatedPhotos,
        status: TaskStatus.inProgress,
        badgeText: 'চলছে',
      );
    }

    final assignmentId = int.tryParse(taskId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (assignmentId != null) {
      try {
        await _apiService.startAssignment(assignmentId);
      } catch (_) {
        // Offline handling or ignore if already in progress
      }
    }
  }

  @override
  Future<void> startTask(String taskId) async {
    final nowIso = DateTime.now().toIso8601String();
    final index = _cachedTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _cachedTasks[index] = _cachedTasks[index].copyWith(
        status: TaskStatus.inProgress,
        badgeText: 'চলছে',
        startedAt: _cachedTasks[index].startedAt ?? nowIso,
      );
    }

    final assignmentId = int.tryParse(taskId.replaceAll(RegExp(r'[^0-9]'), ''));
    if (assignmentId != null) {
      try {
        await _apiService.startAssignment(assignmentId);
      } catch (_) {
        // Offline handling
      }
    }
  }

  @override
  Future<void> submitTask(String taskId) async {
    final index = _cachedTasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _cachedTasks[index] = _cachedTasks[index].copyWith(
        status: TaskStatus.completed,
        badgeText: 'সম্পন্ন',
      );
    }
  }

  @override
  Future<TaskModel> submitSelfReportedTask({
    required String description,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationName,
    int? farmLocationId,
    String? photoPath,
  }) async {
    Uint8List? photoBytes;
    String? photoFileName;
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        final file = File(photoPath);
        if (await file.exists()) {
          photoBytes = await file.readAsBytes();
          photoFileName = photoPath.split(Platform.pathSeparator).last;
        }
      } catch (_) {}
    }

    try {
      final createdAssignment = await _apiService.selfReportTask(
        description: description,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        locationId: farmLocationId,
        photoBytes: photoBytes,
        photoFileName: photoFileName,
      );
      final taskModel = taskModelFromAssignment(createdAssignment);
      _cachedTasks.insert(0, taskModel);
      return taskModel;
    } catch (_) {
      // Fallback local task for offline or mock mode
      final nowFormatted = DateFormatter.formatDateTimeToBanglaTime(DateTime.now().toIso8601String());
      final fallbackTask = TaskModel(
        id: 'self_${DateTime.now().millisecondsSinceEpoch}',
        title: description.length > 25 ? '${description.substring(0, 23)}...' : description,
        subTitle: 'স্ব-প্রতিবেদিত কাজ',
        ownerId: '1',
        ownerName: 'বশির এগ্রো',
        farmName: 'ফার্ম',
        locationId: farmLocationId?.toString() ?? '1',
        locationName: locationName ?? 'বাস্তব জিপিএস অবস্থান',
        fullAddress: locationName ?? 'বাস্তব জিপিএস অবস্থান',
        timeRange: 'এখনই সম্পন্ন',
        date: 'আজ',
        description: description,
        instructions: description,
        status: TaskStatus.completed,
        badgeText: 'সম্পন্ন',
        thumbnailType: 'plant',
        isLate: false,
        geofencePassed: true,
        submittedAt: nowFormatted,
        evidencePhotoUrls: photoPath != null ? [photoPath] : [],
      );
      _cachedTasks.insert(0, fallbackTask);
      return fallbackTask;
    }
  }

  @override
  Future<void> resetDemoData() async {
    _cachedTasks = [];
  }

  static TaskModel taskModelFromAssignment(TaskAssignmentModel assignment) {
    TaskStatus status = TaskStatus.scheduled;
    String badgeText = 'আজ করব';
    bool isOverdueTime = false;
    switch (assignment.status) {
      case 'completed':
        status = TaskStatus.completed;
        badgeText = 'সম্পন্ন';
        break;
      case 'in_progress':
        status = TaskStatus.inProgress;
        badgeText = 'চলছে';
        break;
      case 'submitted':
        status = TaskStatus.submitted;
        badgeText = 'রিভিউ অপেক্ষায়';
        break;
      case 'late':
        status = TaskStatus.inProgress;
        badgeText = 'দেরি হয়েছে';
        isOverdueTime = true;
        break;
      case 'assigned':
      case 'pending':
      default:
        status = TaskStatus.scheduled;
        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        if (assignment.scheduledDate.isNotEmpty && assignment.scheduledDate != 'আজ') {
          if (assignment.scheduledDate.compareTo(todayStr) > 0) {
            badgeText = 'আসন্ন (${DateFormatter.formatShortDate(assignment.scheduledDate)})';
          } else if (assignment.scheduledDate.compareTo(todayStr) < 0) {
            badgeText = 'বাকি আছে';
            isOverdueTime = true;
          } else {
            // Scheduled for today - check if end_time has passed
            if (assignment.endTime != null && assignment.endTime!.isNotEmpty) {
              try {
                final endParts = assignment.endTime!.split(':');
                if (endParts.isNotEmpty) {
                  final endHour = int.tryParse(endParts[0]);
                  final endMin = endParts.length > 1 ? int.tryParse(endParts[1]) ?? 0 : 0;
                  if (endHour != null) {
                    final deadline = DateTime(now.year, now.month, now.day, endHour, endMin);
                    if (now.isAfter(deadline)) {
                      isOverdueTime = true;
                      badgeText = 'সময় পার (বিলম্বিত)';
                    } else {
                      badgeText = 'আজ করব';
                    }
                  } else {
                    badgeText = 'আজ করব';
                  }
                }
              } catch (_) {
                badgeText = 'আজ করব';
              }
            } else {
              badgeText = 'আজ করব';
            }
          }
        } else {
          badgeText = 'আজ করব';
        }
        break;
    }

    final cat = (assignment.task?.category ?? '').toLowerCase();
    final name = (assignment.task?.name ?? '').toLowerCase();
    String thumbnail = 'vegetable';
    if (cat.contains('মাছ') || cat.contains('fish') || name.contains('মাছ') || name.contains('পুকুর')) {
      thumbnail = 'fish';
    } else if (cat.contains('ডেইরি') || cat.contains('গরু') || cat.contains('cow') || cat.contains('পশু') || name.contains('দুধ') || name.contains('খামার')) {
      thumbnail = 'cow';
    } else if (name.contains('সার') || cat.contains('সার') || name.contains('fertilizer')) {
      thumbnail = 'fertilizer';
    }

    final timeRange = DateFormatter.formatTimeRange(assignment.startTime, assignment.endTime);

    final sub = assignment.submission;
    final bool isSubmissionLate = sub?.isLate ?? (assignment.status == 'late' || isOverdueTime);
    final bool? geoPassed = sub?.geofencePassed;
    final double? dist = sub?.distanceMeters;
    final String submittedAtStr = DateFormatter.formatDateTimeToBanglaTime(sub?.submittedAt ?? assignment.completedAt);
    final List<String> photoUrls = sub?.photoUrls ?? [];

    return TaskModel(
      id: assignment.id.toString(),
      title: assignment.task?.name ?? 'কৃষি কাজ',
      subTitle: assignment.task?.category ?? 'মাঠ কাজ',
      ownerId: assignment.farmer?['id']?.toString() ?? '1',
      ownerName: assignment.farmer?['full_name']?.toString() ?? 'বশির এগ্রো',
      farmName: 'বশির এগ্রো ফার্ম',
      locationId: assignment.location?.id.toString() ?? '1',
      locationName: assignment.location?.name ?? 'ফার্ম লোকেশন',
      fullAddress: assignment.location?.address ?? '',
      latitude: assignment.location?.latitude,
      longitude: assignment.location?.longitude,
      fieldBoundary: assignment.location?.fieldBoundary,
      geofenceRadiusMeters: assignment.location?.geofenceRadiusMeters ?? 100,
      timeRange: timeRange,
      date: assignment.scheduledDate.isNotEmpty ? assignment.scheduledDate : 'আজ',
      description: assignment.task?.instructions ?? assignment.notes ?? 'নির্ধারিত কাজ সম্পন্ন করে ছবি ও রিপোর্ট জমা দিন।',
      instructions: assignment.task?.instructions ?? 'ক্ষেতে গিয়ে ফসলের বর্তমান অবস্থা বা কাজের পরিষ্কার রিয়েল-টাইম ছবি তুলে পাঠান।',
      minPhotos: assignment.task?.minPhotosRequired ?? 1,
      maxPhotos: 5,
      status: status,
      badgeText: badgeText,
      thumbnailType: thumbnail,
      isLate: isSubmissionLate,
      photos: const [],
      startedAt: assignment.startedAt,
      completedAt: assignment.completedAt,
      geofencePassed: geoPassed,
      distanceMeters: dist,
      submittedAt: submittedAtStr,
      evidencePhotoUrls: photoUrls,
    );
  }
}
