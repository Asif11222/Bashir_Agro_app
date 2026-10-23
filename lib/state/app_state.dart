import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/models/task_model.dart';
import '../data/models/task_photo_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/task_repository.dart';

import '../data/repositories/api_task_repository.dart';
import 'farmer_app_state.dart';
import '../services/gps_service.dart';

// Single instance repositories
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return ApiTaskRepository(
    taskService: ref.watch(taskServiceProvider),
    apiService: ref.watch(apiServiceProvider),
  );
});

// Authentication state
class CurrentUserNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() {
    final authState = ref.watch(farmerAuthProvider);
    if (authState.isAuthenticated && authState.user != null) {
      return UserModel(
        id: authState.user!.id.toString(),
        name: authState.profile?.fullName.isNotEmpty == true
            ? authState.profile!.fullName
            : authState.user!.name,
        phone: authState.user!.phone,
        password: '',
        role: authState.user!.isOwner ? UserRole.owner : UserRole.farmer,
      );
    }
    return null;
  }

  void setUser(UserModel? user) => state = user;
}

final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, UserModel?>(CurrentUserNotifier.new);

// Selected task ID for details & capture workflow
class SelectedTaskIdNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setTaskId(String id) => state = id;
}

final selectedTaskIdProvider =
    NotifierProvider<SelectedTaskIdNotifier, String>(SelectedTaskIdNotifier.new);

// GPS Simulation & Real-time Tracking Provider
enum GpsTrackingMode {
  insideSimulation,
  outsideSimulation,
  realDeviceGps,
}

class GpsSimulationNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void setInside(bool inside) => state = inside;
}

final gpsSimulationInsideProvider =
    NotifierProvider<GpsSimulationNotifier, bool>(GpsSimulationNotifier.new);

class GpsTrackingModeNotifier extends Notifier<GpsTrackingMode> {
  @override
  GpsTrackingMode build() => GpsTrackingMode.realDeviceGps;

  void setMode(GpsTrackingMode mode) {
    state = mode;
    if (mode == GpsTrackingMode.insideSimulation) {
      ref.read(gpsSimulationInsideProvider.notifier).setInside(true);
    } else if (mode == GpsTrackingMode.outsideSimulation) {
      ref.read(gpsSimulationInsideProvider.notifier).setInside(false);
    }
  }
}

final gpsTrackingModeProvider =
    NotifierProvider<GpsTrackingModeNotifier, GpsTrackingMode>(GpsTrackingModeNotifier.new);

class LiveGpsCoordinateNotifier extends Notifier<GpsCoordinate?> {
  @override
  GpsCoordinate? build() => null;

  void updateCoordinate(GpsCoordinate? coord) => state = coord;
}

final liveGpsCoordinateProvider =
    NotifierProvider<LiveGpsCoordinateNotifier, GpsCoordinate?>(LiveGpsCoordinateNotifier.new);

/// StreamProvider that listens to continuous real device GPS or simulated coordinates
final liveDeviceGpsStreamProvider = StreamProvider.autoDispose<GpsCoordinate?>((ref) async* {
  final mode = ref.watch(gpsTrackingModeProvider);
  final gpsService = GpsService();

  if (mode == GpsTrackingMode.realDeviceGps) {
    gpsService.setSimulationMode(false);
    await for (final coord in gpsService.getRealTimePositionStream()) {
      ref.read(liveGpsCoordinateProvider.notifier).updateCoordinate(coord);
      yield coord;
    }
  } else if (mode == GpsTrackingMode.insideSimulation) {
    gpsService.setSimulationMode(true, true);
    final coord = GpsService.southFieldInside;
    ref.read(liveGpsCoordinateProvider.notifier).updateCoordinate(coord);
    yield coord;
  } else {
    gpsService.setSimulationMode(true, false);
    final coord = GpsService.outsideGeofence;
    ref.read(liveGpsCoordinateProvider.notifier).updateCoordinate(coord);
    yield coord;
  }
});

// Task list state notifier
class TaskListNotifier extends AsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() async {
    final repo = ref.read(taskRepositoryProvider);
    return repo.getTodayTasks();
  }

  Future<void> refresh() async {
    try {
      final repo = ref.read(taskRepositoryProvider);
      final tasks = await repo.getTodayTasks();
      state = AsyncData(tasks);
    } catch (e, st) {
      if (!state.hasValue) {
        state = AsyncError(e, st);
      }
    }
  }

  Future<void> addPhoto(String taskId, TaskPhotoModel photo) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.addPhotoToTask(taskId, photo);
    final updated = await repo.getTodayTasks();
    state = AsyncData(updated);
  }

  Future<void> startTask(String taskId) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.startTask(taskId);
    final updated = await repo.getTodayTasks();
    state = AsyncData(updated);
  }

  Future<void> submitTask(String taskId) async {
    final repo = ref.read(taskRepositoryProvider);
    await repo.submitTask(taskId);
    final updated = await repo.getTodayTasks();
    state = AsyncData(updated);
  }

  Future<TaskModel> submitSelfReportedTask({
    required String description,
    double? latitude,
    double? longitude,
    double? accuracy,
    String? locationName,
    int? farmLocationId,
    String? photoPath,
  }) async {
    final repo = ref.read(taskRepositoryProvider);
    final created = await repo.submitSelfReportedTask(
      description: description,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      locationName: locationName,
      farmLocationId: farmLocationId,
      photoPath: photoPath,
    );
    final updated = await repo.getTodayTasks();
    state = AsyncData(updated);
    return created;
  }
}


final taskListProvider =
    AsyncNotifierProvider<TaskListNotifier, List<TaskModel>>(TaskListNotifier.new);

// Selected Task provider
final currentTaskProvider = Provider<TaskModel?>((ref) {
  final tasksAsync = ref.watch(taskListProvider);
  final selectedId = ref.watch(selectedTaskIdProvider);

  return tasksAsync.when(
    data: (tasks) {
      if (tasks.isEmpty) return null;
      if (selectedId.isNotEmpty) {
        try {
          return tasks.firstWhere((t) => t.id == selectedId);
        } catch (_) {}
      }
      return tasks.first;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

// Captured photos buffer for the current camera session
class CameraSessionNotifier extends Notifier<List<TaskPhotoModel>> {
  @override
  List<TaskPhotoModel> build() => [];

  void addPhoto(TaskPhotoModel photo) {
    state = [...state, photo];
  }

  void removePhotoAt(int index) {
    if (index >= 0 && index < state.length) {
      final updated = List<TaskPhotoModel>.from(state)..removeAt(index);
      state = updated;
    }
  }

  void replacePhotoAt(int index, TaskPhotoModel photo) {
    if (index >= 0 && index < state.length) {
      final updated = List<TaskPhotoModel>.from(state);
      updated[index] = photo;
      state = updated;
    } else {
      addPhoto(photo);
    }
  }

  void removePhotoById(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void clearSession() {
    state = [];
  }
}

final cameraSessionProvider =
    NotifierProvider<CameraSessionNotifier, List<TaskPhotoModel>>(CameraSessionNotifier.new);

// Active photo slot being targeted for retake (null = normal append capture)
class SelectedPhotoSlotNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void selectSlot(int? index) => state = index;
}

final selectedPhotoSlotProvider =
    NotifierProvider<SelectedPhotoSlotNotifier, int?>(SelectedPhotoSlotNotifier.new);

// Latest photo captured to be reviewed in Screen 5
class LatestCapturedPhotoNotifier extends Notifier<TaskPhotoModel?> {
  @override
  TaskPhotoModel? build() => null;

  void setPhoto(TaskPhotoModel? photo) => state = photo;
}

final latestCapturedPhotoProvider =
    NotifierProvider<LatestCapturedPhotoNotifier, TaskPhotoModel?>(LatestCapturedPhotoNotifier.new);

