import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bashir_agro_app_2/data/models/task_model.dart';
import 'package:bashir_agro_app_2/models/field_boundary_model.dart';
import 'package:bashir_agro_app_2/models/task_assignment_model.dart';
import 'package:bashir_agro_app_2/presentation/screens/task_details/completed_task_details_view.dart';
import 'package:bashir_agro_app_2/presentation/screens/task_details/completed_task_full_map_screen.dart';
import 'package:bashir_agro_app_2/presentation/widgets/submitted_photos_grid.dart';

void main() {
  group('Completed Task Details View & 4-State Verification Matrix Tests', () {
    final boundary = FieldBoundaryModel(
      coordinates: [
        GeoPoint(23.7800, 90.4150),
        GeoPoint(23.7820, 90.4150),
        GeoPoint(23.7820, 90.4170),
        GeoPoint(23.7800, 90.4170),
        GeoPoint(23.7800, 90.4150),
      ],
    );

    final baseTask = TaskModel(
      id: 'task_101',
      title: 'পুকুরে খাবার প্রয়োগ',
      subTitle: 'মাছ চাষ',
      ownerId: '1',
      ownerName: 'বশির এগ্রো',
      farmName: 'বশির এগ্রো ফার্ম',
      locationId: 'LOC-01',
      locationName: 'উত্তর ব্লক পুকুর',
      fullAddress: 'কালীগঞ্জ, গাজীপুর',
      latitude: 23.7810,
      longitude: 90.4160,
      fieldBoundary: boundary,
      timeRange: 'সকাল ৮:০০ – বিকাল ৫:০০',
      date: '2026-10-24',
      description: 'নিয়মিত খাবার সরবরাহ সম্পন্ন করা',
      instructions: 'মাছের ওজন অনুপাতে খাদ্য ছিটিয়ে দিন।',
      status: TaskStatus.completed,
      badgeText: 'সম্পন্ন',
      thumbnailType: 'fish',
      submittedAt: '2026-10-24T17:20:00Z',
      submittedPhotos: [
        SubmittedPhotoDetail(
          id: 1,
          url: 'https://example.com/photo1.jpg',
          latitude: 23.7812,
          longitude: 90.4162,
          capturedAt: '2026-10-24T16:40:00Z',
          insideGeofence: true,
          isLate: false,
        ),
        SubmittedPhotoDetail(
          id: 2,
          url: 'https://example.com/photo2.jpg',
          latitude: 23.7815,
          longitude: 90.4165,
          capturedAt: '2026-10-24T16:45:00Z',
          insideGeofence: true,
          isLate: false,
        ),
      ],
    );

    testWidgets('1. Renders State 1 (সব ঠিক) with top banner, pills, and photos', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CompletedTaskDetailsView(
            task: baseTask,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Top Success Banner
      expect(find.text('কাজের তথ্য জমা হয়েছে'), findsOneWidget);

      // Title & Badge
      expect(find.text('পুকুরে খাবার প্রয়োগ'), findsOneWidget);
      expect(find.text('সম্পন্ন'), findsOneWidget);

      // Key Info Card
      expect(find.text('কাজের সময়'), findsOneWidget);
      expect(find.text('নির্ধারিত স্থান'), findsOneWidget);
      expect(find.text('জমা দেওয়ার সময়'), findsOneWidget);

      // 4-State Header & Verification Pills
      expect(find.text('(✓) সব ঠিক'), findsOneWidget);
      expect(find.text('(✓) সঠিক লোকেশনে'), findsWidgets);
      expect(find.text('(✓) সময়ের মধ্যে'), findsWidgets);

      // Photos Grid & Instructions
      expect(find.text('জমা দেওয়া ছবি (২টি)'), findsOneWidget);
      expect(find.text('নির্দেশনা'), findsOneWidget);
      expect(find.text('কাজের তালিকায় ফিরুন'), findsOneWidget);
    });

    testWidgets('2. Renders State 2 (!) সময়ে সমস্যা when task is late', (tester) async {
      final lateTask = baseTask.copyWith(
        isLate: true,
        submittedPhotos: [
          SubmittedPhotoDetail(
            id: 1,
            url: 'https://example.com/p1.jpg',
            latitude: 23.7812,
            longitude: 90.4162,
            capturedAt: '2026-10-24T17:30:00Z',
            insideGeofence: true,
            isLate: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CompletedTaskDetailsView(
            task: lateTask,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('(!) সময়ে সমস্যা'), findsOneWidget);
      expect(find.text('(✓) সঠিক লোকেশনে'), findsWidgets);
      expect(find.text('(X) সময় পেরিয়েছে'), findsWidgets);
    });

    testWidgets('3. Renders State 3 (!) লোকেশনে সমস্যা when photo is outside geofence', (tester) async {
      final outsideTask = baseTask.copyWith(
        geofencePassed: false,
        submittedPhotos: [
          SubmittedPhotoDetail(
            id: 1,
            url: 'https://example.com/p1.jpg',
            latitude: 23.7900, // outside polygon
            longitude: 90.4200,
            capturedAt: '2026-10-24T16:30:00Z',
            insideGeofence: false,
            isLate: false,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CompletedTaskDetailsView(
            task: outsideTask,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('(!) লোকেশনে সমস্যা'), findsOneWidget);
      expect(find.text('(X) লোকেশনের বাইরে'), findsWidgets);
      expect(find.text('(✓) সময়ের মধ্যে'), findsWidgets);

      // Outside warning banner in map
      expect(find.text('১টি ছবি নির্ধারিত এলাকার বাইরে তোলা হয়েছে'), findsOneWidget);
    });

    testWidgets('4. Renders State 4 (X) সময় ও লোকেশনে সমস্যা when both late and outside', (tester) async {
      final bothTask = baseTask.copyWith(
        isLate: true,
        geofencePassed: false,
        submittedPhotos: [
          SubmittedPhotoDetail(
            id: 1,
            url: 'https://example.com/p1.jpg',
            latitude: 23.7900,
            longitude: 90.4200,
            capturedAt: '2026-10-24T17:45:00Z',
            insideGeofence: false,
            isLate: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CompletedTaskDetailsView(
            task: bothTask,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('(X) সময় ও লোকেশনে সমস্যা'), findsOneWidget);
      expect(find.text('(X) লোকেশনের বাইরে'), findsWidgets);
      expect(find.text('(X) সময় পেরিয়েছে'), findsWidgets);
    });

    testWidgets('5. SubmittedPhotosGrid opens Lightbox Dialog on photo tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SubmittedPhotosGrid(
                photos: [
                  SubmittedPhotoDetail(
                    id: 1,
                    url: 'https://example.com/demo.jpg',
                    latitude: 23.7812,
                    longitude: 90.4162,
                    capturedAt: '2026-10-24T16:40:00Z',
                    insideGeofence: true,
                    isLate: false,
                  ),
                ],
                boundary: boundary,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on photo card
      await tester.tap(find.textContaining('ছবি ১').first);
      await tester.pumpAndSettle();

      // Lightbox opened
      expect(find.byType(PhotoLightboxDialog), findsOneWidget);
      expect(find.text('ছবি ১ / ১'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoLightboxDialog), findsNothing);
    });

    testWidgets('6. Tapping full map button or hint badge in CompletedTaskDetailsView opens CompletedTaskFullMapScreen', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CompletedTaskDetailsView(
            task: baseTask,
            onBack: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the fullscreen button
      final openMapButton = find.byTooltip('পূর্ণ ম্যাপ দেখুন');
      expect(openMapButton, findsOneWidget);

      await tester.tap(openMapButton);
      await tester.pumpAndSettle();

      // CompletedTaskFullMapScreen should now be in tree
      expect(find.byType(CompletedTaskFullMapScreen), findsOneWidget);
      expect(find.text('ছবির অবস্থান ও মাঠ সীমানা'), findsOneWidget);
      expect(find.textContaining('উত্তর ব্লক পুকুর'), findsWidgets);
    });

    testWidgets('7. CompletedTaskFullMapScreen displays green pins for inside photos and red pins for outside photos', (tester) async {
      final mixedPhotos = [
        SubmittedPhotoDetail(
          id: 1,
          url: 'https://example.com/p1.jpg',
          latitude: 23.7812, // Inside boundary
          longitude: 90.4162,
          capturedAt: '2026-10-24T16:40:00Z',
          insideGeofence: true,
          isLate: false,
        ),
        SubmittedPhotoDetail(
          id: 2,
          url: 'https://example.com/p2.jpg',
          latitude: 23.7830, // Outside boundary
          longitude: 90.4180,
          capturedAt: '2026-10-24T16:45:00Z',
          insideGeofence: false,
          isLate: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CompletedTaskFullMapScreen(
            boundary: boundary,
            farmName: 'বশির এগ্রো ফার্ম',
            locationCode: 'LOC-01',
            photos: mixedPhotos,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check legend displays inside & outside counts
      expect(find.textContaining('সবুজ: এলাকার ভিতরে (১টি)'), findsOneWidget);
      expect(find.textContaining('লাল: এলাকার বাইরে (১টি)'), findsOneWidget);

      // Verify photo thumbnails in selector
      expect(find.textContaining('ছবি ১'), findsWidgets);
      expect(find.textContaining('ছবি ২'), findsWidgets);
    });
  });
}
