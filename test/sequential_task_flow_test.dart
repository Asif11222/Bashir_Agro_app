import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bashir_agro_app_2/core/storage/local_storage_service.dart';
import 'package:bashir_agro_app_2/data/models/task_model.dart';
import 'package:bashir_agro_app_2/models/task_assignment_model.dart';
import 'package:bashir_agro_app_2/presentation/screens/farm_map/field_boundary_map_screen.dart';
import 'package:bashir_agro_app_2/presentation/screens/task_details/task_details_screen.dart';
import 'package:bashir_agro_app_2/state/app_state.dart';
import 'package:bashir_agro_app_2/state/farmer_app_state.dart';

class MockSelectedAssignmentNotifier extends SelectedAssignmentNotifier {
  final TaskAssignmentModel? _initial;
  MockSelectedAssignmentNotifier(this._initial);
  @override
  TaskAssignmentModel? build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorageService.instance.clearAll();
  });

  group('Sequential Task Workflow Tests (Start Work ➔ Take Photos)', () {
    testWidgets('1. Scheduled state: Start Work is enabled, Take Photo is locked & disabled', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final assignment = TaskAssignmentModel(
        id: 1,
        scheduledDate: '2026-10-22',
        status: 'assigned',
        task: const TaskTemplateDetail(
          id: 1,
          taskCode: 'TC-01',
          name: 'গাছের পাতা পর্যবেক্ষণ',
          category: 'ফসল যত্ন',
          minPhotosRequired: 2,
        ),
      );

      final task = TaskModel(
        id: '1',
        title: 'গাছের পাতা পর্যবেক্ষণ',
        subTitle: 'ফসল যত্ন',
        ownerId: '1',
        ownerName: 'বশির আহমেদ',
        farmName: 'বশির অ্যাগ্রো ১',
        locationId: '1',
        locationName: 'উত্তর মাঠ',
        fullAddress: 'গাজীপুর',
        timeRange: 'সকাল ৯:০০ - ১০:০০',
        date: '২২ অক্টোবর ২০২৬',
        description: 'গাছের পাতা পর্যবেক্ষণ করুন',
        instructions: 'রিয়েল-টাইম ছবি তুলুন',
        badgeText: 'আজ করব',
        thumbnailType: 'vegetable',
        status: TaskStatus.scheduled,
        minPhotos: 2,
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

      // Start Work button should be found and enabled
      final startWorkBtnFinder = find.widgetWithText(ElevatedButton, 'কাজ শুরু করুন (Start Work)');
      expect(startWorkBtnFinder, findsOneWidget);
      final ElevatedButton startBtn = tester.widget(startWorkBtnFinder);
      expect(startBtn.onPressed, isNotNull);

      // Lock message should be displayed
      expect(find.text('🔒 কাজ শুরু না করা পর্যন্ত ছবি তোলা যাবে না'), findsOneWidget);

      // Photo button should be disabled (OutlinedButton with null onPressed)
      final photoBtnFinder = find.widgetWithText(OutlinedButton, 'ছবি তুলুন (২টি ছবি আবশ্যক)');
      expect(photoBtnFinder, findsOneWidget);
      final OutlinedButton photoBtn = tester.widget(photoBtnFinder);
      expect(photoBtn.onPressed, isNull);
    });

    testWidgets('2. InProgress state: Start Work is gone, ActiveWorkTimerCard and enabled Take Photo are shown', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final startedTime = DateTime.now().subtract(const Duration(minutes: 15));

      final assignment = TaskAssignmentModel(
        id: 1,
        scheduledDate: '2026-10-22',
        status: 'in_progress',
        startedAt: startedTime.toIso8601String(),
        task: const TaskTemplateDetail(
          id: 1,
          taskCode: 'TC-01',
          name: 'গাছের পাতা পর্যবেক্ষণ',
          category: 'ফসল যত্ন',
          minPhotosRequired: 2,
        ),
      );

      final task = TaskModel(
        id: '1',
        title: 'গাছের পাতা পর্যবেক্ষণ',
        subTitle: 'ফসল যত্ন',
        ownerId: '1',
        ownerName: 'বশির আহমেদ',
        farmName: 'বশির অ্যাগ্রো ১',
        locationId: '1',
        locationName: 'উত্তর মাঠ',
        fullAddress: 'গাজীপুর',
        timeRange: 'সকাল ৯:০০ - ১০:০০',
        date: '২২ অক্টোবর ২০২৬',
        description: 'গাছের পাতা পর্যবেক্ষণ করুন',
        instructions: 'রিয়েল-টাইম ছবি তুলুন',
        badgeText: 'চলছে',
        thumbnailType: 'vegetable',
        status: TaskStatus.inProgress,
        startedAt: startedTime.toIso8601String(),
        minPhotos: 2,
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

      // Start Work button should NOT exist
      expect(find.text('কাজ শুরু করুন (Start Work)'), findsNothing);

      // Active Work Stopwatch Card should exist
      expect(find.byType(ActiveWorkTimerCard), findsOneWidget);
      expect(find.text('কাজ চলমান'), findsOneWidget);
      expect(find.text('সময় অতিবাহিত হয়েছে'), findsOneWidget);

      // Take Photo button is now an enabled ElevatedButton
      final photoBtnFinder = find.widgetWithText(ElevatedButton, 'ছবি তুলুন (২টি ছবি আবশ্যক)');
      expect(photoBtnFinder, findsOneWidget);
      final ElevatedButton photoBtn = tester.widget(photoBtnFinder);
      expect(photoBtn.onPressed, isNotNull);
    });

    testWidgets('3. Completed state: Completed summary card is shown, neither button is active', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final task = TaskModel(
        id: '1',
        title: 'গাছের পাতা পর্যবেক্ষণ',
        subTitle: 'ফসল যত্ন',
        ownerId: '1',
        ownerName: 'বশির আহমেদ',
        farmName: 'বশির অ্যাগ্রো ১',
        locationId: '1',
        locationName: 'উত্তর মাঠ',
        fullAddress: 'গাজীপুর',
        timeRange: 'সকাল ৯:০০ - ১০:০০',
        date: '২২ অক্টোবর ২০২৬',
        description: 'গাছের পাতা পর্যবেক্ষণ করুন',
        instructions: 'রিয়েল-টাইম ছবি তুলুন',
        badgeText: 'সম্পন্ন',
        thumbnailType: 'vegetable',
        status: TaskStatus.completed,
        minPhotos: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTaskProvider.overrideWithValue(task),
          ],
          child: const MaterialApp(
            home: TaskDetailsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Completed summary should be visible
      expect(find.text('কাজ সম্পন্ন হয়েছে'), findsOneWidget);
      expect(find.text('কাজ শুরু করুন (Start Work)'), findsNothing);
      expect(find.textContaining('ছবি আবশ্যক'), findsNothing);
    });

    testWidgets('4. FieldBoundaryMapScreen with scheduled task: Shows "কাজ শুরু করুন" and prevents "ছবি তুলুন"', (tester) async {
      final task = TaskModel(
        id: '1',
        title: 'গাছের পাতা পর্যবেক্ষণ',
        subTitle: 'ফসল যত্ন',
        ownerId: '1',
        ownerName: 'বশির আহমেদ',
        farmName: 'বশির অ্যাগ্রো ১',
        locationId: '1',
        locationName: 'উত্তর মাঠ',
        fullAddress: 'গাজীপুর',
        timeRange: 'সকাল ৯:০০ - ১০:০০',
        date: '২২ অক্টোবর ২০২৬',
        description: 'গাছের পাতা পর্যবেক্ষণ করুন',
        instructions: 'রিয়েল-টাইম ছবি তুলুন',
        badgeText: 'আজ করব',
        thumbnailType: 'vegetable',
        status: TaskStatus.scheduled,
        minPhotos: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTaskProvider.overrideWithValue(task),
          ],
          child: const MaterialApp(
            home: FieldBoundaryMapScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In scheduled state, map screen MUST show "কাজ শুরু করুন" and lock message
      expect(find.widgetWithText(ElevatedButton, 'কাজ শুরু করুন'), findsOneWidget);
      expect(find.text('🔒 কাজ শুরু না করা পর্যন্ত ছবি তোলা যাবে না'), findsOneWidget);
      expect(find.text('ছবি তুলুন'), findsNothing);
    });

    testWidgets('5. FieldBoundaryMapScreen with inProgress task: Shows "ছবি তুলুন" button', (tester) async {
      final task = TaskModel(
        id: '1',
        title: 'গাছের পাতা পর্যবেক্ষণ',
        subTitle: 'ফসল যত্ন',
        ownerId: '1',
        ownerName: 'বশির আহমেদ',
        farmName: 'বশির অ্যাগ্রো ১',
        locationId: '1',
        locationName: 'উত্তর মাঠ',
        fullAddress: 'গাজীপুর',
        timeRange: 'সকাল ৯:০০ - ১০:০০',
        date: '২২ অক্টোবর ২০২৬',
        description: 'গাছের পাতা পর্যবেক্ষণ করুন',
        instructions: 'রিয়েল-টাইম ছবি তুলুন',
        badgeText: 'চলছে',
        thumbnailType: 'vegetable',
        status: TaskStatus.inProgress,
        minPhotos: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentTaskProvider.overrideWithValue(task),
          ],
          child: const MaterialApp(
            home: FieldBoundaryMapScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In inProgress state, map screen MUST show "ছবি তুলুন" button
      expect(find.widgetWithText(ElevatedButton, 'ছবি তুলুন'), findsOneWidget);
      expect(find.text('কাজ শুরু করুন'), findsNothing);
    });
  });
}
