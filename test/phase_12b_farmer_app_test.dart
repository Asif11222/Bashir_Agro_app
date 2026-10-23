import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:bashir_agro_app_2/presentation/screens/camera/live_camera_screen.dart';
import 'package:bashir_agro_app_2/services/camera_service.dart';

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

  group('Phase 12B: Flutter Farmer App Tests', () {
    // 1. Test: Login
    test('1. Login: Authenticates farmer and securely persists Sanctum Bearer token', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/auth/login')) {
          final body = jsonDecode(request.body);
          if (body['login'] == '01700000001' && body['password'] == '123456') {
            return utf8JsonResponse({
              'success': true,
              'message': 'লগইন সফল হয়েছে।',
              'data': {
                'token': '1|sanctum_farmer_token_abc123',
                'token_type': 'Bearer',
                'user': {
                  'id': 1,
                  'name': 'আব্দুল রহমান',
                  'phone': '01700000001',
                  'role': 'farmer',
                },
                'farmer_profile': {
                  'id': 1,
                  'farmer_code': 'FAR-001',
                  'full_name': 'আব্দুল রহমান',
                  'phone': '01700000001',
                  'primary_activity': 'শাকসবজি চাষ',
                  'experience_years': 8,
                },
              },
            }, 200);
          }
          return utf8JsonResponse({'message': 'প্রদত্ত তথ্য সঠিক নয়'}, 422);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final apiService = ApiService(client: apiClient);
      final authService = AuthService(apiService: apiService);

      final loginResult = await authService.login('01700000001', '123456');

      expect(loginResult.success, isTrue);
      expect(loginResult.token, equals('1|sanctum_farmer_token_abc123'));
      expect(authService.token, equals('1|sanctum_farmer_token_abc123'));
      expect(authService.isAuthenticated, isTrue);

      // Verify token is stored in persistent LocalStorageService
      final savedToken = LocalStorageService.instance.getString(ApiConstants.tokenKey);
      expect(savedToken, equals('1|sanctum_farmer_token_abc123'));

      // Test session restoration
      final restoredAuthService = AuthService(apiService: apiService);
      final hasSession = await restoredAuthService.initializeSession();
      expect(hasSession, isTrue);
      expect(restoredAuthService.currentUser?.phone, equals('01700000001'));
    });

    // 2. Test: API Connection
    test('2. API connection: Injects Authorization Bearer and handles requests/errors', () async {
      String? sentAuthHeader;

      final mockClient = MockClient((request) async {
        sentAuthHeader = request.headers['Authorization'];

        if (request.url.path.endsWith('/farmer/profile')) {
          return utf8JsonResponse({
            'success': true,
            'data': {
              'id': 1,
              'farmer_code': 'FAR-001',
              'full_name': 'আব্দুল রহমান',
              'phone': '01700000001',
            },
          }, 200);
        }
        return utf8JsonResponse({'message': 'Unauthorized'}, 401);
      });

      final apiClient = ApiClient(client: mockClient);
      apiClient.setAuthToken('test_sanctum_token');
      final apiService = ApiService(client: apiClient);

      final profile = await apiService.getFarmerProfile();

      expect(sentAuthHeader, equals('Bearer test_sanctum_token'));
      expect(profile.farmerCode, equals('FAR-001'));
      expect(profile.fullName, equals('আব্দুল রহমান'));
    });

    // 3. Test: Task Loading
    test('3. Task loading: Fetches assignments and filters Today, Pending and Completed tasks', () async {
      final mockClient = MockClient((request) async {
        return utf8JsonResponse({
          'success': true,
          'data': [
            {
              'id': 101,
              'scheduled_date': '2026-09-30',
              'start_time': 'সকাল ৮:০০',
              'end_time': '১০:০০',
              'status': 'assigned',
              'task': {
                'id': 1,
                'task_code': 'TSK-001',
                'name': 'সবজি ক্ষেত পরিদর্শন',
                'category': 'শাকসবজি চাষ',
                'requires_evidence_photo': true,
                'min_photos_required': 1,
              },
              'location': {
                'id': 1,
                'location_code': 'LOC-001',
                'name': 'দক্ষিণ মাঠ, ২ নং ব্লক',
                'type': 'সবজি ক্ষেত',
                'address': 'দক্ষিণ পাড়া',
                'coordinates': {'latitude': 23.7808, 'longitude': 90.4152},
                'geofence_radius_meters': 100,
              },
            },
            {
              'id': 102,
              'scheduled_date': '2026-09-30',
              'start_time': 'দুপুর ১২:০০',
              'end_time': '১২:৩০',
              'status': 'in_progress',
              'task': {
                'id': 2,
                'task_code': 'TSK-002',
                'name': 'মাছের খাবার দেওয়া',
                'category': 'মৎস্য',
              },
            },
            {
              'id': 103,
              'scheduled_date': '2026-09-29',
              'status': 'completed',
              'task': {
                'id': 3,
                'task_code': 'TSK-003',
                'name': 'গোয়ালঘর পরিষ্কার',
                'category': 'ডেইরি',
              },
            },
          ],
        }, 200);
      });

      final apiClient = ApiClient(client: mockClient);
      final apiService = ApiService(client: apiClient);
      final taskService = TaskService(apiService: apiService);

      final assignments = await taskService.fetchAssignments();
      expect(assignments.length, equals(3));

      // Filter Pending
      final pending = taskService.filterPendingTasks(assignments);
      expect(pending.length, equals(2));
      expect(pending.any((t) => t.id == 101), isTrue);
      expect(pending.any((t) => t.id == 102), isTrue);

      // Filter Completed
      final completed = taskService.filterCompletedTasks(assignments);
      expect(completed.length, equals(1));
      expect(completed.first.id, equals(103));

      // Verify cached in LocalStorage
      final cached = taskService.getCachedAssignments();
      expect(cached.length, equals(3));
    });

    // 4. Test: Camera Viewfinder & Image Compression
    testWidgets('4. Camera: Viewfinder renders reticle framing guides and controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LiveCameraScreen(),
          ),
        ),
      );

      // Camera viewfinder elements
      expect(find.byType(LiveCameraScreen), findsOneWidget);
      expect(find.text('ছবি তুলুন'), findsOneWidget);
      expect(find.textContaining('রিয়েল টাইমে'), findsOneWidget);

      // Test CameraService singleton and headless safety
      final cameraService = CameraService.instance;
      expect(cameraService, isNotNull);
      expect(cameraService.isInitialized, isFalse);

      // Test image compression service
      final compressionService = ImageCompressionService();
      final dummyRawBytes = Uint8List(2 * 1024 * 1024); // 2 MB raw image
      final compressed = await compressionService.compressImage(dummyRawBytes, targetMaxKb: 800);

      expect(compressed.compressedSize, lessThanOrEqualTo(800 * 1024));
      expect(compressed.originalSize, equals(2 * 1024 * 1024));
    });

    // 5. Test: GPS Module
    test('5. GPS: Captures Latitude, Longitude, Accuracy and calculates distance for Geofence', () async {
      final gpsService = GpsService();

      // Test inside geofence capture
      gpsService.setSimulationMode(true, true);
      final locInside = await gpsService.getCurrentLocation();
      expect(locInside, isNotNull);
      expect(locInside!.latitude, closeTo(23.7808, 0.001));
      expect(locInside.longitude, closeTo(90.4152, 0.001));
      expect(locInside.accuracy, lessThanOrEqualTo(10.0));

      // Test distance inside South Field
      final distInside = gpsService.calculateDistanceMeters(
        locInside.latitude,
        locInside.longitude,
        23.7808,
        90.4152,
      );
      expect(distInside, closeTo(0, 1.0));

      // Test outside geofence simulation
      gpsService.setSimulationMode(true, false);
      final locOutside = await gpsService.getCurrentLocation();
      expect(locOutside, isNotNull);
      final distOutside = gpsService.calculateDistanceMeters(
        locOutside!.latitude,
        locOutside.longitude,
        23.7808,
        90.4152,
      );
      // Distance should exceed 1000m (outside geofence radius)
      expect(distOutside, greaterThan(1000.0));
    });

    // 6. Test: Offline Synchronization Workflow
    test('6. Offline synchronization: No internet -> Save locally -> Connection returns -> Synchronize', () async {
      int apiCallCount = 0;

      final mockClient = MockClient((request) async {
        apiCallCount++;
        return utf8JsonResponse({
          'success': true,
          'message': 'কাজের রিপোর্ট সফলভাবে জমা হয়েছে।',
          'data': {'id': 99, 'status': 'submitted', 'geofence': {'passed': true}},
        }, 200);
      });

      final apiClient = ApiClient(client: mockClient);
      final apiService = ApiService(client: apiClient);
      final syncService = OfflineSyncService(apiService: apiService);

      // Step 1: No internet
      syncService.setOnlineStatus(false, autoSync: false);
      expect(syncService.isOnline, isFalse);

      // Step 2: Save locally
      await syncService.queueSubmission(
        assignmentId: 101,
        latitude: 23.7808,
        longitude: 90.4152,
        accuracy: 4.5,
        notes: 'মাঠে প্রচুর লাউ ধরেছে।',
        photoPaths: ['photo_offline_1.jpg'],
      );

      expect(syncService.pendingCount, equals(1));
      expect(apiCallCount, equals(0)); // Nothing sent over network

      // Step 3: Connection returns
      syncService.setOnlineStatus(true, autoSync: false);
      expect(syncService.isOnline, isTrue);

      // Step 4: Synchronize data
      final syncedCount = await syncService.syncPendingSubmissions();
      expect(syncedCount, equals(1));
      expect(apiCallCount, equals(1));
      expect(syncService.pendingCount, equals(0));
    });

    // 7. Test: Submission Flow
    test('7. Submission flow: Notes, GPS coordinates and photo evidence uploaded to Laravel API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/assignments/101/submit')) {
          return utf8JsonResponse({
            'success': true,
            'message': 'কাজের প্রমাণ ও প্রতিবেদন সফলভাবে জমা হয়েছে।',
            'data': {
              'id': 55,
              'status': 'submitted',
              'verification_status': 'pending',
              'geofence': {
                'passed': true,
                'distance_meters': 14.5,
              },
            },
          }, 201);
        }
        return http.Response('Error', 400);
      });

      final apiClient = ApiClient(client: mockClient);
      final apiService = ApiService(client: apiClient);

      final dummyPhoto = ImageCompressionService().generateSimulatedPhotoBytes('evidence');

      final submissionResult = await apiService.submitAssignment(
        assignmentId: 101,
        latitude: 23.7808,
        longitude: 90.4152,
        accuracy: 4.5,
        notes: 'ক্ষেতে সেচ ও সার প্রয়োগ সম্পন্ন।',
        photoBytesList: [dummyPhoto],
      );

      expect(submissionResult.success, isTrue);
      expect(submissionResult.geofencePassed, isTrue);
      expect(submissionResult.distanceMeters, equals(14.5));
      expect(submissionResult.submissionId, equals(55));
    });

    // Bonus: Test FCM Notification Events (New task, Reminder, Approval, Rejection)
    test('Notifications: FCM events (New task, Reminder, Approval, Rejection)', () async {
      final notifService = NotificationService();

      final initialCount = notifService.getNotifications().length;

      // Dispatch 4 FCM events
      await notifService.dispatchFcmEvent(
        eventType: NotificationEventType.newTask,
        title: 'নতুন কাজ',
        message: 'সবজি ক্ষেতের কাজ নির্ধারিত হয়েছে',
      );
      await notifService.dispatchFcmEvent(
        eventType: NotificationEventType.reminder,
        title: 'কাজের তাগিদ',
        message: 'আর ৩০ মিনিট বাকি',
      );
      await notifService.dispatchFcmEvent(
        eventType: NotificationEventType.approval,
        title: 'প্রতিবেদন অনুমোদিত',
        message: 'রিপোর্ট অনুমোদিত হয়েছে',
      );
      await notifService.dispatchFcmEvent(
        eventType: NotificationEventType.rejection,
        title: 'পুনরায় যাচাই',
        message: 'ছবি অস্পষ্ট, পুনরায় তুলুন',
      );

      final list = notifService.getNotifications();
      expect(list.length, equals(initialCount + 4));

      expect(list.any((n) => n.eventType == NotificationEventType.newTask), isTrue);
      expect(list.any((n) => n.eventType == NotificationEventType.reminder), isTrue);
      expect(list.any((n) => n.eventType == NotificationEventType.approval), isTrue);
      expect(list.any((n) => n.eventType == NotificationEventType.rejection), isTrue);
    });
  });
}
