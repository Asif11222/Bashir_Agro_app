import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bashir_agro_app_2/core/storage/local_storage_service.dart';
import 'package:bashir_agro_app_2/core/utils/date_formatter.dart';
import 'package:bashir_agro_app_2/data/models/task_model.dart';
import 'package:bashir_agro_app_2/data/models/task_photo_model.dart';
import 'package:bashir_agro_app_2/models/task_assignment_model.dart';
import 'package:bashir_agro_app_2/presentation/screens/task_details/task_details_screen.dart';
import 'package:bashir_agro_app_2/presentation/screens/photo_review/photo_review_screen.dart';
import 'package:bashir_agro_app_2/state/app_state.dart';
import 'package:bashir_agro_app_2/state/farmer_app_state.dart';

class MockSelectedAssignmentNotifier extends SelectedAssignmentNotifier {
  final TaskAssignmentModel? _initial;
  MockSelectedAssignmentNotifier(this._initial);
  @override
  TaskAssignmentModel? build() => _initial;
}

class MockCameraSessionNotifier extends CameraSessionNotifier {
  final List<TaskPhotoModel> _initial;
  MockCameraSessionNotifier(this._initial);
  @override
  List<TaskPhotoModel> build() => _initial;
}

class MockLatestCapturedPhotoNotifier extends LatestCapturedPhotoNotifier {
  final TaskPhotoModel? _initial;
  MockLatestCapturedPhotoNotifier(this._initial);
  @override
  TaskPhotoModel? build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorageService.instance.clearAll();
  });

  group('Photo Counter and Requirements Tests', () {
    test('1. TaskAssignmentModel correctly calculates minPhotosRequired from nested task', () {
      final jsonWith3 = {
        'id': 101,
        'scheduled_date': '2026-10-16',
        'status': 'assigned',
        'task': {
          'id': 1,
          'task_code': 'TC-01',
          'name': 'গাছের গোড়ায় সার প্রয়োগ',
          'category': 'সার প্রয়োগ',
          'min_photos_required': 3,
        },
      };
      final model3 = TaskAssignmentModel.fromJson(jsonWith3);
      expect(model3.minPhotosRequired, 3);

      final jsonWithDefault = {
        'id': 102,
        'scheduled_date': '2026-10-16',
        'status': 'assigned',
        'task': {
          'id': 2,
          'task_code': 'TC-02',
          'name': 'কীটনাশক স্প্রে',
          'category': 'কীটনাশক',
        },
      };
      final modelDefault = TaskAssignmentModel.fromJson(jsonWithDefault);
      expect(modelDefault.minPhotosRequired, 1);
    });

    test('2. DateFormatter converts digits to Bengali correctly', () {
      expect(DateFormatter.toBanglaDigits(1), '১');
      expect(DateFormatter.toBanglaDigits(3), '৩');
      expect(DateFormatter.toBanglaDigits(10), '১০');
    });

    testWidgets('3. TaskDetailsScreen renders dynamic photo requirement info and button counter', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final assignment = TaskAssignmentModel(
        id: 1,
        scheduledDate: '2026-10-16',
        status: 'assigned',
        task: const TaskTemplateDetail(
          id: 1,
          taskCode: 'TC-01',
          name: 'গাছের গোড়ায় সার প্রয়োগ',
          category: 'সার প্রয়োগ',
          minPhotosRequired: 3,
        ),
      );

      final task = TaskModel(
        id: '1',
        title: 'গাছের গোড়ায় সার প্রয়োগ',
        subTitle: 'সার প্রয়োগ',
        ownerId: '1',
        ownerName: 'বশির আহমেদ',
        farmName: 'বশির অ্যাগ্রো ১',
        locationId: '1',
        locationName: 'উত্তর মাঠ',
        fullAddress: 'গাজীপুর',
        timeRange: 'সকাল ৯:০০ - ১০:০০',
        date: '১৬ অক্টোবর ২০২৬',
        description: 'সার প্রয়োগ করতে হবে',
        instructions: 'সঠিক নিয়মে সার দিন',
        badgeText: 'জরুরি',
        thumbnailType: 'vegetable',
        status: TaskStatus.scheduled,
        minPhotos: 3,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTaskProvider.overrideWithValue(task),
            activeAssignmentProvider.overrideWith(() => MockSelectedAssignmentNotifier(assignment)),
          ],
          child: const MaterialApp(
            home: TaskDetailsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check that redundant photo rules card is removed and dynamic count is displayed in button
      expect(find.textContaining('ছবি তোলার নিয়ম'), findsNothing);
      expect(find.textContaining('ছবি তুলুন (৩টি ছবি আবশ্যক)'), findsOneWidget);
    });

    testWidgets('4. PhotoReviewScreen shows requirement progress card and prevents under-capture submission', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final assignment = TaskAssignmentModel(
        id: 1,
        scheduledDate: '2026-10-16',
        status: 'assigned',
        task: const TaskTemplateDetail(
          id: 1,
          taskCode: 'TC-01',
          name: 'সার প্রয়োগ',
          category: 'সার প্রয়োগ',
          minPhotosRequired: 3,
        ),
      );

      final singlePhoto = TaskPhotoModel(
        id: 'p1',
        localPath: 'test_photo_1.jpg',
        capturedAt: DateTime.now(),
        latitude: 23.7808,
        longitude: 90.4152,
        gpsAccuracy: 4.5,
        insideGeofence: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAssignmentProvider.overrideWith(() => MockSelectedAssignmentNotifier(assignment)),
            cameraSessionProvider.overrideWith(() => MockCameraSessionNotifier([singlePhoto])),
            latestCapturedPhotoProvider.overrideWith(() => MockLatestCapturedPhotoNotifier(singlePhoto)),
          ],
          child: const MaterialApp(
            home: PhotoReviewScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check requirement card elements
      expect(find.text('আরও ছবি আবশ্যক'), findsOneWidget);
      expect(find.text('ছবি তোলা হয়েছে: ১ / ৩ টি'), findsOneWidget);
      expect(find.text('বাকি ২টি'), findsOneWidget);

      // Check next photo button
      expect(find.textContaining('পরবর্তী ছবি তুলুন (আর ২টি আবশ্যক)'), findsOneWidget);

      // Tap submit button with under-captured count
      final submitBtn = find.textContaining('জমা দিন (১/৩ টি ছবি)');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Under-capture warning dialog should appear
      expect(find.text('ছবি তোলা সম্পূর্ণ হয়নি!'), findsOneWidget);
      expect(find.textContaining('কমপক্ষে ৩টি প্রামাণ্য ছবি প্রয়োজন'), findsOneWidget);
      expect(find.text('বাকি ছবি তুলুন'), findsOneWidget);
    });

    testWidgets('5. PhotoReviewScreen displays completed requirement card and primary submit button when min count met', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final assignment = TaskAssignmentModel(
        id: 1,
        scheduledDate: '2026-10-16',
        status: 'assigned',
        task: const TaskTemplateDetail(
          id: 1,
          taskCode: 'TC-01',
          name: 'সার প্রয়োগ',
          category: 'সার প্রয়োগ',
          minPhotosRequired: 2,
        ),
      );

      final photo1 = TaskPhotoModel(
        id: 'p1',
        localPath: 'test_photo_1.jpg',
        capturedAt: DateTime.now(),
        latitude: 23.7808,
        longitude: 90.4152,
        gpsAccuracy: 4.5,
        insideGeofence: true,
      );
      final photo2 = TaskPhotoModel(
        id: 'p2',
        localPath: 'test_photo_2.jpg',
        capturedAt: DateTime.now(),
        latitude: 23.7808,
        longitude: 90.4152,
        gpsAccuracy: 4.5,
        insideGeofence: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAssignmentProvider.overrideWith(() => MockSelectedAssignmentNotifier(assignment)),
            cameraSessionProvider.overrideWith(() => MockCameraSessionNotifier([photo1, photo2])),
            latestCapturedPhotoProvider.overrideWith(() => MockLatestCapturedPhotoNotifier(photo2)),
          ],
          child: const MaterialApp(
            home: PhotoReviewScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check requirement completed elements
      expect(find.text('প্রয়োজনীয় ছবি তোলা সম্পন্ন'), findsOneWidget);
      expect(find.text('ছবি তোলা হয়েছে: ২ / ২ টি'), findsOneWidget);
      expect(find.text('সম্পূর্ণ'), findsOneWidget);

      // Primary submit button with total count
      expect(find.textContaining('ছবি আপলোড ও জমা দিন (২টি ছবি)'), findsOneWidget);

      // Verify optional extra photo option is NOT shown when requirement is met
      expect(find.textContaining('আরেকটি ছবি যোগ করুন'), findsNothing);
      expect(find.textContaining('ঐচ্ছিক'), findsNothing);
    });

    testWidgets('6. PhotoReviewScreen shows outside boundary warning dialog when photo is outside geofence', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final assignment = TaskAssignmentModel(
        id: 2,
        scheduledDate: '2026-10-22',
        status: 'in_progress',
        task: const TaskTemplateDetail(
          id: 2,
          taskCode: 'TC-02',
          name: 'পানি সেচ',
          category: 'সেচ',
          minPhotosRequired: 1,
        ),
      );

      final photoOutside = TaskPhotoModel(
        id: 'p_out',
        localPath: 'outside_crop.jpg',
        capturedAt: DateTime.now(),
        latitude: 24.1200,
        longitude: 89.2500,
        gpsAccuracy: 5.0,
        insideGeofence: false, // Farmer captured outside the farm!
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeAssignmentProvider.overrideWith(() => MockSelectedAssignmentNotifier(assignment)),
            cameraSessionProvider.overrideWith(() => MockCameraSessionNotifier([photoOutside])),
            latestCapturedPhotoProvider.overrideWith(() => MockLatestCapturedPhotoNotifier(photoOutside)),
          ],
          child: const MaterialApp(
            home: PhotoReviewScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Submit button is present
      final submitBtn = find.textContaining('ছবি আপলোড ও জমা দিন (১টি ছবি)');
      expect(submitBtn, findsOneWidget);

      // Tap submit button while outside geofence
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify warning dialog appears with the exact warning message
      expect(find.text('মাঠের বাইরে অবস্থান!'), findsOneWidget);
      expect(find.textContaining('আপনি নির্ধারিত মাঠের সীমানার বাইরে আছেন'), findsOneWidget);
      expect(find.text('না, পরে করব'), findsOneWidget);
      expect(find.text('হ্যাঁ, জমা দিন'), findsOneWidget);

      // Farmer taps "হ্যাঁ, জমা দিন"
      await tester.tap(find.text('হ্যাঁ, জমা দিন'));
      await tester.pumpAndSettle();

      // Warning dialog closes and submission completes (showing result dialog or success)
      expect(find.text('মাঠের বাইরে অবস্থান!'), findsNothing);
    });
  });
}
