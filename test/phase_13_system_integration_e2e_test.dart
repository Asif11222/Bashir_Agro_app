import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bashir_agro_app_2/core/constants/api_constants.dart';
import 'package:bashir_agro_app_2/core/network/api_client.dart';
import 'package:bashir_agro_app_2/core/storage/local_storage_service.dart';
import 'package:bashir_agro_app_2/services/api_service.dart';
import 'package:bashir_agro_app_2/services/auth_service.dart';
import 'package:bashir_agro_app_2/services/task_service.dart';
import 'package:bashir_agro_app_2/services/gps_service.dart';
import 'package:bashir_agro_app_2/services/image_compression_service.dart';
import 'package:bashir_agro_app_2/services/offline_sync_service.dart';
import 'package:bashir_agro_app_2/services/notification_service.dart';
import 'package:bashir_agro_app_2/models/notification_model.dart';


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

  group('Phase 13: Flutter Farmer App System Integration & E2E Tests', () {
    // 1. Mobile Authentication & Persistent Session Flow
    test('1. Mobile Auth: Authenticates with Sanctum Bearer token and restores session across app restarts', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          final body = jsonDecode(request.body);
          if (body['login'] == '01711998877' && body['password'] == 'pass12345') {
            return utf8JsonResponse({
              'success': true,
              'message': 'লগইন সফল হয়েছে।',
              'data': {
                'token': '13|sanctum_p13_e2e_token',
                'token_type': 'Bearer',
                'user': {
                  'id': 10,
                  'name': 'আব্দুর রহিম',
                  'phone': '01711998877',
                  'role': 'farmer',
                },
                'farmer_profile': {
                  'id': 5,
                  'farmer_code': 'FAR-P13-01',
                  'full_name': 'আব্দুর রহিম',
                  'phone': '01711998877',
                  'primary_activity': 'শাকসবজি চাষ',
                },
              },
            }, 200);
          }
        } else if (request.url.path.endsWith('/auth/me')) {
          if (request.headers['Authorization'] == 'Bearer 13|sanctum_p13_e2e_token') {
            return utf8JsonResponse({
              'success': true,
              'data': {
                'user': {
                  'id': 10,
                  'name': 'আব্দুর রহিম',
                  'phone': '01711998877',
                  'role': 'farmer',
                },
              },
            }, 200);
          }
          return utf8JsonResponse({'message': 'Unauthenticated'}, 401);
        } else if (request.url.path.endsWith('/auth/logout')) {
          return utf8JsonResponse({'success': true, 'message': 'Logged out'}, 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final apiService = ApiService(client: apiClient);
      final authService = AuthService(apiService: apiService);

      // Login
      final loginResult = await authService.login('01711998877', 'pass12345');
      expect(loginResult.success, isTrue);
      expect(authService.isAuthenticated, isTrue);
      expect(authService.token, equals('13|sanctum_p13_e2e_token'));

      // Token saved in local storage
      expect(LocalStorageService.instance.getString(ApiConstants.tokenKey), equals('13|sanctum_p13_e2e_token'));

      // Session restore on second instance (simulating app relaunch)
      final restoredAuth = AuthService(apiService: apiService);
      final hasRestoredSession = await restoredAuth.initializeSession();
      expect(hasRestoredSession, isTrue);
      expect(restoredAuth.currentUser?.phone, equals('01711998877'));

      // Logout
      await authService.logout();
      expect(authService.isAuthenticated, isFalse);
      expect(LocalStorageService.instance.getString(ApiConstants.tokenKey), isNull);
    });

    // 2. Complete End-to-End Workflow on Mobile:
    // Farmer logs in -> fetches assigned task -> starts work -> captures GPS & compresses photo -> submits with PostGIS validation
    test('2. Complete Workflow: Task Reception -> Start -> GPS Capture -> Photo Compression -> Submit', () async {
      int startCalled = 0;
      int submitCalled = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/assignments')) {
          return utf8JsonResponse({
            'success': true,
            'data': [
              {
                'id': 201,
                'scheduled_date': '2026-09-30',
                'start_time': '08:00',
                'end_time': '11:00',
                'priority': 'important',
                'status': 'assigned',
                'task': {
                  'id': 15,
                  'task_code': 'TSK-101',
                  'name': 'জৈব সার প্রয়োগ ও আগাছা পরিষ্কার',
                  'category': 'সার ও পুষ্টি',
                  'instructions': 'গাছের গোড়ায় ২ কেজি হারে কম্পোস্ট সার প্রদান করুন।',
                  'requires_evidence_photo': true,
                  'min_photos_required': 1,
                },
                'location': {
                  'id': 8,
                  'location_code': 'LOC-08',
                  'name': 'পূর্বাঞ্চলীয় সবজি প্লট',
                  'type': 'সবজি ক্ষেত',
                  'address': 'ময়মনসিংহ কৃষি জোন',
                  'coordinates': {'latitude': 24.747100, 'longitude': 90.420300},
                  'geofence_radius_meters': 60,
                },
              },
            ],
          }, 200);
        } else if (request.url.path.contains('/assignments/201/start')) {
          startCalled++;
          return utf8JsonResponse({
            'success': true,
            'data': {
              'id': 201,
              'status': 'in_progress',
              'task': {'id': 15, 'name': 'জৈব সার প্রয়োগ ও আগাছা পরিষ্কার'},
            },
          }, 200);
        } else if (request.url.path.contains('/assignments/201/submit')) {
          submitCalled++;
          return utf8JsonResponse({
            'success': true,
            'message': 'কাজের প্রমাণ ও প্রতিবেদন সফলভাবে জমা হয়েছে।',
            'data': {
              'id': 77,
              'status': 'submitted',
              'verification_status': 'pending',
              'geofence': {
                'passed': true,
                'distance_meters': 8.5,
              },
            },
          }, 201);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      apiClient.setAuthToken('13|sanctum_p13_e2e_token');
      final apiService = ApiService(client: apiClient);
      final taskService = TaskService(apiService: apiService);

      // Step A: Farmer fetches assignments
      final tasks = await taskService.fetchAssignments();
      expect(tasks.length, equals(1));
      final task = tasks.first;
      expect(task.id, equals(201));
      expect(task.task?.name, equals('জৈব সার প্রয়োগ ও আগাছা পরিষ্কার'));
      expect(task.location?.name, equals('পূর্বাঞ্চলীয় সবজি প্লট'));
      expect(task.location?.geofenceRadiusMeters, equals(60));

      // Step B: Farmer starts work
      final startedTask = await taskService.startTask(task.id);
      expect(startCalled, equals(1));
      expect(startedTask.status, equals('in_progress'));

      // Step C: GPS module captures coordinates and validates distance
      final gpsService = GpsService();
      gpsService.setSimulationMode(true, true); // simulates inside plot
      final position = await gpsService.getCurrentLocation();
      expect(position, isNotNull);
      expect(position!.latitude, isNotNull);
      expect(position.longitude, isNotNull);

      // Calculate distance to farm plot
      final distance = gpsService.calculateDistanceMeters(
        position.latitude,
        position.longitude,
        task.location?.latitude ?? 24.7471,
        task.location?.longitude ?? 90.4203,
      );
      expect(distance, isA<double>());

      // Step D: Capture and compress image
      final compressionService = ImageCompressionService();
      final simulatedPhotoBytes = compressionService.generateSimulatedPhotoBytes('fertilizer_work');
      final compressed = await compressionService.compressImage(simulatedPhotoBytes, targetMaxKb: 800);
      expect(compressed.compressedSize, lessThanOrEqualTo(800 * 1024));

      // Step E: Submit completion to server
      final submission = await apiService.submitAssignment(
        assignmentId: task.id,
        latitude: 24.747120,
        longitude: 90.420310,
        accuracy: 4.8,
        notes: 'কাজ সম্পন্ন হয়েছে।',
        photoBytesList: [compressed.compressedBytes],
      );

      expect(submitCalled, equals(1));
      expect(submission.success, isTrue);
      expect(submission.geofencePassed, isTrue);
      expect(submission.distanceMeters, equals(8.5));
    });

    // 3. Offline Synchronization Workflow (Page 3 & 4 of PDF)
    // No internet -> Save data locally -> Internet returns -> Sync with server -> Server receives update
    test('3. Offline Synchronization: Saves to local storage offline, auto-syncs when online', () async {
      int networkUploads = 0;

      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/submit')) {
          networkUploads++;
          return utf8JsonResponse({
            'success': true,
            'message': 'কাজের প্রমাণ সফলভাবে জমা হয়েছে।',
            'data': {'id': 99, 'status': 'submitted', 'geofence': {'passed': true}},
          }, 201);
        }
        return http.Response('Error', 500);
      });

      final apiClient = ApiClient(client: mockClient);
      final apiService = ApiService(client: apiClient);
      final offlineService = OfflineSyncService(apiService: apiService);

      // Condition 1: No Internet
      offlineService.setOnlineStatus(false, autoSync: false);
      expect(offlineService.isOnline, isFalse);

      // Action: Queue submission locally
      final queued = await offlineService.queueSubmission(
        assignmentId: 201,
        latitude: 24.747120,
        longitude: 90.420310,
        accuracy: 4.5,
        notes: 'মাঠের কাজ সমাপ্ত। [অফলাইন]',
        photoPaths: ['offline_plot_photo.jpg'],
      );

      expect(queued.assignmentId, equals(201));
      expect(offlineService.pendingCount, equals(1));
      expect(networkUploads, equals(0)); // Zero network calls while offline

      // Condition 2: Internet returns
      offlineService.setOnlineStatus(true, autoSync: false);
      expect(offlineService.isOnline, isTrue);

      // Action: Synchronize pending queue
      final count = await offlineService.syncPendingSubmissions();
      expect(count, equals(1));
      expect(networkUploads, equals(1)); // Uploaded to server
      expect(offlineService.pendingCount, equals(0)); // Local queue cleared
    });

    // 4. PostGIS Geofence Testing: Inside radius (Accept) vs Outside radius (Reject/Flag)
    test('4. PostGIS Geofence: Inside radius accepts, outside radius rejects/flags', () async {
      final mockClient = MockClient((request) async {
        final body = request.body;
        // Check if coordinates correspond to outside radius
        if (body.contains('24.00135')) {
          return utf8JsonResponse({
            'success': false,
            'message': 'আপনি নির্ধারিত ফার্ম লোকেশনের জিও-ফেন্স পরিধির বাইরে অবস্থান করছেন।',
            'geofence': {
              'passed': false,
              'distance_meters': 152.0,
              'radius_meters': 30,
            },
          }, 422);
        }

        // Inside radius
        return utf8JsonResponse({
          'success': true,
          'message': 'কাজের প্রমাণ সফলভাবে গৃহীত হয়েছে।',
          'data': {
            'id': 120,
            'status': 'submitted',
            'geofence': {
              'passed': true,
              'distance_meters': 12.0,
              'radius_meters': 50,
            },
          },
        }, 201);
      });

      final apiClient = ApiClient(client: mockClient);
      final apiService = ApiService(client: apiClient);

      // Inside radius submission
      final insideResult = await apiService.submitAssignment(
        assignmentId: 301,
        latitude: 24.000050,
        longitude: 89.000050,
        accuracy: 3.5,
      );
      expect(insideResult.success, isTrue);
      expect(insideResult.geofencePassed, isTrue);

      // Outside radius submission
      try {
        await apiService.submitAssignment(
          assignmentId: 302,
          latitude: 24.001350,
          longitude: 89.000000,
          accuracy: 5.0,
        );
        fail('Should have thrown ApiException on 422 geofence rejection');
      } on ApiException catch (e) {
        expect(e.statusCode, equals(422));
        expect(e.message, contains('জিও-ফেন্স'));
      }
    });

    // 5. Notification Dispatch & Local Events
    test('5. Notifications: Handles Task Assignment, Reminders, and Admin Approvals', () async {
      final notifService = NotificationService();
      final initialCount = notifService.getNotifications().length;
      final initialUnread = notifService.unreadCount;

      // New task assigned event
      await notifService.dispatchFcmEvent(
        eventType: NotificationEventType.newTask,
        title: 'নতুন কাজ বরাদ্দ',
        message: 'আপনাকে "জৈব সার প্রয়োগ" কাজটি বরাদ্দ করা হয়েছে।',
      );

      // Reminder event
      await notifService.dispatchFcmEvent(
        eventType: NotificationEventType.reminder,
        title: 'কাজের সময়সূচি',
        message: 'কাজের সময়সীমা শেষ হতে ১ ঘণ্টা বাকি আছে।',
      );

      // Admin approval event
      await notifService.dispatchFcmEvent(
        eventType: NotificationEventType.approval,
        title: 'প্রতিবেদন অনুমোদিত',
        message: 'আপনার জমা দেওয়া কাজের প্রতিবেদন অনুমোদিত হয়েছে।',
      );

      final list = notifService.getNotifications();
      expect(list.length, equals(initialCount + 3));

      // Mark first as read
      await notifService.markAsRead(list.first.id);
      expect(notifService.unreadCount, equals(initialUnread + 2));
    });
  });
}
