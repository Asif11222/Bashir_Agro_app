import 'dart:async';
import '../core/constants/api_constants.dart';
import '../core/storage/local_storage_service.dart';
import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  final LocalStorageService _storage;
  final ApiService? apiService;
  final StreamController<AppNotificationModel> _notificationStreamController =
      StreamController<AppNotificationModel>.broadcast();

  Stream<AppNotificationModel> get notificationStream =>
      _notificationStreamController.stream;

  NotificationService({
    LocalStorageService? storage,
    this.apiService,
  }) : _storage = storage ?? LocalStorageService.instance;

  /// Get stored notifications from local cache
  List<AppNotificationModel> getNotifications() {
    final raw = _storage.getJson(ApiConstants.notificationsKey);
    if (raw is List) {
      return raw
          .map((item) => AppNotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  int get unreadCount => getNotifications().where((n) => !n.isRead).length;

  /// Fetch notifications from backend API and update local cache
  Future<List<AppNotificationModel>> fetchNotifications({bool forceRefresh = false}) async {
    final cached = getNotifications();

    if (apiService == null) {
      return cached;
    }

    try {
      final remoteList = await apiService!.getNotifications();
      await _saveNotifications(remoteList);
      return remoteList;
    } catch (_) {
      // In offline mode or network error, fallback gracefully to cached notifications
      return cached;
    }
  }

  /// Mark single notification as read locally and sync with backend API
  Future<void> markAsRead(String id) async {
    final list = getNotifications();
    try {
      final item = list.firstWhere((n) => n.id == id);
      item.isRead = true;
      await _saveNotifications(list);
    } catch (_) {}

    if (apiService != null) {
      try {
        await apiService!.markNotificationAsRead(id);
      } catch (_) {
        // Ignored if offline or server temporarily unavailable
      }
    }
  }

  /// Mark all as read locally and sync with backend API
  Future<void> markAllAsRead() async {
    final list = getNotifications();
    for (final n in list) {
      n.isRead = true;
    }
    await _saveNotifications(list);

    if (apiService != null) {
      try {
        await apiService!.markAllNotificationsAsRead();
      } catch (_) {
        // Ignored if offline or server temporarily unavailable
      }
    }
  }

  /// Dispatch a real or received push notification event
  Future<AppNotificationModel> dispatchFcmEvent({
    required NotificationEventType eventType,
    required String title,
    required String message,
    int? assignmentId,
  }) async {
    final notification = AppNotificationModel(
      id: 'NOTIF_${DateTime.now().millisecondsSinceEpoch}',
      eventType: eventType,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      assignmentId: assignmentId,
      isRead: false,
    );

    final list = getNotifications();
    list.insert(0, notification);
    await _saveNotifications(list);

    _notificationStreamController.add(notification);
    return notification;
  }

  Future<void> _saveNotifications(List<AppNotificationModel> list) async {
    final jsonList = list.map((e) => e.toJson()).toList();
    await _storage.setJson(ApiConstants.notificationsKey, jsonList);
  }
}
