import '../models/task_model.dart';
import '../models/task_photo_model.dart';

abstract class TaskRepository {
  Future<List<TaskModel>> getTodayTasks();
  Future<TaskModel?> getTaskById(String id);
  Future<void> addPhotoToTask(String taskId, TaskPhotoModel photo);
  Future<void> startTask(String taskId);
  Future<void> submitTask(String taskId);
  Future<TaskModel> submitSelfReportedTask({
    required String description,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationName,
    int? farmLocationId,
    String? photoPath,
  });
  Future<void> resetDemoData();
}

class MockTaskRepository implements TaskRepository {
  List<TaskModel> _tasks = [];

  @override
  Future<List<TaskModel>> getTodayTasks() async {
    return List.unmodifiable(_tasks);
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addPhotoToTask(String taskId, TaskPhotoModel photo) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final updatedPhotos = List<TaskPhotoModel>.from(_tasks[index].photos)..add(photo);
      _tasks[index] = _tasks[index].copyWith(
        photos: updatedPhotos,
        status: TaskStatus.inProgress,
        badgeText: 'চলছে',
      );
    }
  }

  @override
  Future<void> startTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: TaskStatus.inProgress,
        badgeText: 'চলছে',
        startedAt: DateTime.now().toIso8601String(),
      );
    }
  }

  @override
  Future<void> submitTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: TaskStatus.submitted,
        badgeText: 'রিভিউ অপেক্ষায়',
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
    final newTask = TaskModel(
      id: 'self_${DateTime.now().millisecondsSinceEpoch}',
      title: description.length > 20 ? '${description.substring(0, 18)}...' : description,
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
      submittedAt: 'এখনই',
      evidencePhotoUrls: photoPath != null ? [photoPath] : [],
    );
    _tasks.insert(0, newTask);
    return newTask;
  }

  @override
  Future<void> resetDemoData() async {
    _tasks = [];
  }
}
