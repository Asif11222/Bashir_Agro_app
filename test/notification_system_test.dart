import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bashir_agro_app_2/core/constants/api_constants.dart';
import 'package:bashir_agro_app_2/core/network/api_client.dart';
import 'package:bashir_agro_app_2/core/storage/local_storage_service.dart';
import 'package:bashir_agro_app_2/models/notification_model.dart';
import 'package:bashir_agro_app_2/presentation/screens/notifications/notifications_screen.dart';
import 'package:bashir_agro_app_2/services/api_service.dart';
import 'package:bashir_agro_app_2/services/notification_service.dart';
import 'package:bashir_agro_app_2/state/farmer_app_state.dart';

http.Response utf8JsonResponse(Map<String, dynamic> data, int statusCode) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorageService.instance.clearAll();
  });

  group('Notification System Tests', () {
    test('1. AppNotificationModel parses Laravel API payload correctly', () {
      final json = {
        'id': 'uuid-1234-5678',
        'event_type': 'newTask',
        'title': 'নতুন কাজ বরাদ্দ',
        'message': 'আপনাকে নতুন একটি কাজ বরাদ্দ করা হয়েছে: ফসল পর্যবেক্ষণ (প্লট ১)',
        'timestamp': '2026-10-16T10:00:00Z',
        'assignment_id': 42,
        'is_read': false,
      };

      final model = AppNotificationModel.fromJson(json);

      expect(model.id, equals('uuid-1234-5678'));
      expect(model.eventType, equals(NotificationEventType.newTask));
      expect(model.eventNameBengali, equals('নতুন কাজ'));
      expect(model.title, equals('নতুন কাজ বরাদ্দ'));
      expect(model.assignmentId, equals(42));
      expect(model.isRead, isFalse);
    });

    test('2. ApiService fetches notifications from backend', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/notifications') && request.method == 'GET') {
          return utf8JsonResponse({
            'success': true,
            'data': [
              {
                'id': 'notif-1',
                'event_type': 'newTask',
                'title': 'নতুন কাজ বরাদ্দ',
                'message': 'ফসল পর্যবেক্ষণ',
                'timestamp': '2026-10-16T12:00:00Z',
                'assignment_id': 10,
                'is_read': false,
              },
            ],
            'meta': {'unread_count': 1, 'total': 1},
          }, 200);
        }
        return utf8JsonResponse({'error': 'Not found'}, 404);
      });

      final apiClient = ApiClient(client: mockClient);
      apiClient.setAuthToken('test-token');
      final apiService = ApiService(client: apiClient);

      final notifications = await apiService.getNotifications();
      expect(notifications.length, equals(1));
      expect(notifications.first.title, equals('নতুন কাজ বরাদ্দ'));
      expect(notifications.first.assignmentId, equals(10));
    });

    test('3. NotificationService caches remote notifications in LocalStorage', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/notifications')) {
          return utf8JsonResponse({
            'success': true,
            'data': [
              {
                'id': 'notif-1',
                'event_type': 'newTask',
                'title': 'নতুন কাজ বরাদ্দ',
                'message': 'কীটনাশক ছিটানো',
                'timestamp': '2026-10-16T14:00:00Z',
                'assignment_id': 25,
                'is_read': false,
              },
            ],
          }, 200);
        }
        return utf8JsonResponse({'error': 'Not found'}, 404);
      });

      final apiClient = ApiClient(client: mockClient);
      apiClient.setAuthToken('test-token');
      final apiService = ApiService(client: apiClient);
      final notificationService = NotificationService(apiService: apiService);

      final fetched = await notificationService.fetchNotifications(forceRefresh: true);
      expect(fetched.length, equals(1));
      expect(fetched.first.id, equals('notif-1'));

      // Check offline cache persistence
      final cached = notificationService.getNotifications();
      expect(cached.length, equals(1));
      expect(cached.first.title, equals('নতুন কাজ বরাদ্দ'));
      expect(notificationService.unreadCount, equals(1));
    });

    test('4. NotificationService marks as read locally and syncs with API', () async {
      bool markedOnServer = false;
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/notifications/notif-1/read')) {
          markedOnServer = true;
          return utf8JsonResponse({'success': true}, 200);
        }
        return utf8JsonResponse({'error': 'Not found'}, 404);
      });

      final apiClient = ApiClient(client: mockClient);
      apiClient.setAuthToken('test-token');
      final apiService = ApiService(client: apiClient);
      final notificationService = NotificationService(apiService: apiService);

      // Seed local storage
      await LocalStorageService.instance.setJson(ApiConstants.notificationsKey, [
        {
          'id': 'notif-1',
          'event_type': 'newTask',
          'title': 'নতুন কাজ',
          'message': 'পরীক্ষা',
          'timestamp': DateTime.now().toIso8601String(),
          'assignment_id': 5,
          'is_read': false,
        }
      ]);

      await notificationService.markAsRead('notif-1');

      expect(notificationService.unreadCount, equals(0));
      expect(notificationService.getNotifications().first.isRead, isTrue);
      expect(markedOnServer, isTrue);
    });

    testWidgets('5. NotificationsScreen renders notifications and marks all as read', (tester) async {
      final notificationService = NotificationService();
      await LocalStorageService.instance.setJson(ApiConstants.notificationsKey, [
        {
          'id': 'notif-test-1',
          'event_type': 'newTask',
          'title': 'নতুন কাজ বরাদ্দ',
          'message': 'আগাছা পরিষ্কার করণ',
          'timestamp': DateTime.now().toIso8601String(),
          'assignment_id': 99,
          'is_read': false,
        }
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(notificationService),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('বিজ্ঞপ্তি ও সতর্কতা'), findsOneWidget);
      expect(find.text('নতুন কাজ বরাদ্দ'), findsOneWidget);
      expect(find.text('আগাছা পরিষ্কার করণ'), findsOneWidget);
      expect(find.text('সব পঠিত'), findsOneWidget);

      // Tap 'সব পঠিত'
      await tester.tap(find.text('সব পঠিত'));
      await tester.pumpAndSettle();

      expect(find.text('সব পঠিত'), findsNothing);
      expect(notificationService.unreadCount, equals(0));
    });
  });
}
