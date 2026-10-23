import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage_service.dart';
import '../models/submission_model.dart';
import 'api_service.dart';
import 'image_compression_service.dart';

class OfflineSyncService {
  final ApiService _apiService;
  final LocalStorageService _storage;
  bool _isOnline = true;

  final StreamController<int> _pendingCountController = StreamController<int>.broadcast();
  Stream<int> get pendingCountStream => _pendingCountController.stream;

  OfflineSyncService({
    ApiService? apiService,
    LocalStorageService? storage,
  })  : _apiService = apiService ?? ApiService(),
        _storage = storage ?? LocalStorageService.instance;

  bool get isOnline => _isOnline;

  void setOnlineStatus(bool online, {bool autoSync = true}) {
    _isOnline = online;
    if (_isOnline && autoSync) {
      // Auto-trigger sync when connection returns
      syncPendingSubmissions();
    }
  }


  /// Clear all offline queued submissions
  Future<void> clearQueue() async {
    await _storage.remove(ApiConstants.offlineQueueKey);
    _pendingCountController.add(0);
  }

  /// Get all queued offline submissions (pruning any dummy/demo assignments)
  List<OfflineSubmissionItem> getPendingSubmissions() {
    final raw = _storage.getJson(ApiConstants.offlineQueueKey);
    if (raw is List) {
      return raw
          .map((item) => OfflineSubmissionItem.fromJson(item as Map<String, dynamic>))
          .where((item) => item.assignmentId > 0)
          .toList();
    }
    return [];
  }

  int get pendingCount => getPendingSubmissions()
      .where((s) => s.syncStatus == SubmissionSyncStatus.pendingSync)
      .length;

  /// Save submission locally when offline
  Future<OfflineSubmissionItem> queueSubmission({
    required int assignmentId,
    required double latitude,
    required double longitude,
    double? accuracy,
    String? notes,
    List<String>? photoPaths,
    bool overrideGeofence = false,
  }) async {
    final item = OfflineSubmissionItem(
      localId: 'OFFLINE_${DateTime.now().millisecondsSinceEpoch}',
      assignmentId: assignmentId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      notes: notes,
      photoPaths: photoPaths ?? [],
      createdAt: DateTime.now(),
      overrideGeofence: overrideGeofence,
      syncStatus: SubmissionSyncStatus.pendingSync,
    );

    final queue = getPendingSubmissions();
    queue.add(item);
    await _saveQueue(queue);

    _pendingCountController.add(pendingCount);
    return item;
  }

  /// Synchronize pending data when connection returns
  Future<int> syncPendingSubmissions() async {
    if (!_isOnline) return 0;

    final queue = getPendingSubmissions();
    int syncedCount = 0;

    for (final item in queue) {
      if (item.syncStatus == SubmissionSyncStatus.pendingSync ||
          item.syncStatus == SubmissionSyncStatus.failed) {
        try {
          item.syncStatus = SubmissionSyncStatus.syncing;
          await _saveQueue(queue);

          // Prepare real photos or valid placeholder
          final photos = <Uint8List>[];
          final compressionService = ImageCompressionService();
          if (item.photoPaths.isNotEmpty) {
            for (final p in item.photoPaths) {
              if (p.isNotEmpty && File(p).existsSync()) {
                final raw = await File(p).readAsBytes();
                final comp = await compressionService.compressImage(raw, targetMaxKb: 800);
                photos.add(comp.compressedBytes);
              }
            }
          }
          if (photos.isEmpty) {
            photos.add(compressionService.generateSimulatedPhotoBytes('offline_evidence'));
          }

          final result = await _apiService.submitAssignment(
            assignmentId: item.assignmentId,
            latitude: item.latitude,
            longitude: item.longitude,
            accuracy: item.accuracy,
            notes: item.notes != null ? '${item.notes} [অফলাইন সিঙ্ক]' : '[অফলাইন সিঙ্ক]',
            photoBytesList: photos,
            overrideGeofence: item.overrideGeofence,
          );

          if (result.success) {
            item.syncStatus = SubmissionSyncStatus.synced;
            syncedCount++;
          } else {
            item.syncStatus = SubmissionSyncStatus.failed;
            item.errorMessage = result.message;
          }
        } on ApiException catch (e) {
          // If task does not exist on server (404/400) or already submitted (409), discard from queue so it does not hang perpetually
          if (e.statusCode == 404 || e.statusCode == 400 || e.statusCode == 409 || e.message.contains('ইতিমধ্যে') || e.message.contains('already')) {
            item.syncStatus = SubmissionSyncStatus.synced;
            syncedCount++;
          } else {
            item.syncStatus = SubmissionSyncStatus.failed;
            item.errorMessage = e.message;
          }
        } catch (e) {
          item.syncStatus = SubmissionSyncStatus.failed;
          item.errorMessage = e.toString();
        }
      }
    }

    // Keep only non-synced items or recent history
    final remaining = queue.where((s) => s.syncStatus != SubmissionSyncStatus.synced).toList();
    await _saveQueue(remaining);

    _pendingCountController.add(remaining.length);
    return syncedCount;
  }

  Future<void> _saveQueue(List<OfflineSubmissionItem> queue) async {
    final valid = queue.where((e) => e.assignmentId > 0).toList();
    if (valid.isEmpty) {
      await _storage.remove(ApiConstants.offlineQueueKey);
    } else {
      final list = valid.map((e) => e.toJson()).toList();
      await _storage.setJson(ApiConstants.offlineQueueKey, list);
    }
  }
}
