import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bashir_agro_app_2/data/models/task_model.dart';
import 'package:bashir_agro_app_2/presentation/widgets/completed_task_card.dart';

void main() {
  group('Completed Task 4 Verification States Tests', () {
    test('1. CompletedSubmissionType calculates all 4 states correctly', () {
      // 1. On time & inside geofence
      final t1 = TaskModel(
        id: '1',
        title: 'পুকুরে খাবার দেওয়া',
        subTitle: 'মাছ চাষ',
        ownerId: '1',
        ownerName: 'বশির এগ্রো',
        farmName: 'ফার্ম',
        locationId: '1',
        locationName: 'পুকুর ১',
        fullAddress: 'ঠিকানা',
        timeRange: 'সকাল ৮:০০ – ১০:০০',
        date: 'আজ',
        description: 'বিবরণ',
        instructions: 'নির্দেশনা',
        badgeText: 'সম্পন্ন',
        thumbnailType: 'fish',
        isLate: false,
        geofencePassed: true,
      );
      expect(t1.completedSubmissionType, CompletedSubmissionType.allGood);

      // 2. Late & inside geofence
      final t2 = t1.copyWith(isLate: true, geofencePassed: true);
      expect(t2.completedSubmissionType, CompletedSubmissionType.lateOnly);

      // 3. On time & outside geofence
      final t3 = t1.copyWith(isLate: false, geofencePassed: false);
      expect(t3.completedSubmissionType, CompletedSubmissionType.outsideZoneOnly);

      // 4. Late & outside geofence
      final t4 = t1.copyWith(isLate: true, geofencePassed: false);
      expect(t4.completedSubmissionType, CompletedSubmissionType.bothIssues);
    });

    testWidgets('2. CompletedTaskCard renders State 1 (সব ঠিক) correctly', (tester) async {
      final task = TaskModel(
        id: '1',
        title: 'পুকুরে খাবার দেওয়া',
        subTitle: 'মাছ চাষ',
        ownerId: '1',
        ownerName: 'বশির এগ্রো',
        farmName: 'ফার্ম',
        locationId: '1',
        locationName: 'ধলাইরপাড় • পুকুর ১',
        fullAddress: 'ঠিকানা',
        timeRange: 'সকাল ৮:০০ – ১০:০০',
        date: 'আজ',
        description: 'বিবরণ',
        instructions: 'নির্দেশনা',
        badgeText: 'সম্পন্ন',
        thumbnailType: 'fish',
        isLate: false,
        geofencePassed: true,
        submittedAt: 'সকাল ৯:১৫',
        evidencePhotoUrls: ['url1', 'url2', 'url3'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletedTaskCard(task: task, onTap: () {}),
          ),
        ),
      );

      expect(find.text('পুকুরে খাবার দেওয়া'), findsOneWidget);
      expect(find.text('মাছ চাষ'), findsOneWidget);
      expect(find.text('সব ঠিক'), findsOneWidget);
      expect(find.text('সম্পন্ন'), findsOneWidget);
      expect(find.text('সঠিক লোকেশনে'), findsOneWidget);
      expect(find.text('সময়ের মধ্যে'), findsOneWidget);
      expect(find.text('জমা: সকাল ৯:১৫'), findsOneWidget);
      expect(find.text('৩টি ছবি'), findsOneWidget);
    });

    testWidgets('2. CompletedTaskCard renders State 2 (সময়ে সমস্যা) correctly', (tester) async {
      final task = TaskModel(
        id: '2',
        title: 'সবজি ক্ষেতে পানি দেওয়া',
        subTitle: 'সবজি চাষ',
        ownerId: '1',
        ownerName: 'বশির এগ্রো',
        farmName: 'ফার্ম',
        locationId: '1',
        locationName: 'ধলাইরপাড় • জমি ৩',
        fullAddress: 'ঠিকানা',
        timeRange: 'সকাল ৮:০০ – ১০:০০',
        date: 'আজ',
        description: 'বিবরণ',
        instructions: 'নির্দেশনা',
        badgeText: 'সম্পন্ন',
        thumbnailType: 'vegetable',
        isLate: true,
        geofencePassed: true,
        submittedAt: 'সকাল ১০:৪৫',
        evidencePhotoUrls: ['url1'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletedTaskCard(task: task, onTap: () {}),
          ),
        ),
      );

      expect(find.text('সবজি ক্ষেতে পানি দেওয়া'), findsOneWidget);
      expect(find.text('সময়ে সমস্যা'), findsOneWidget);
      expect(find.text('সঠিক লোকেশনে'), findsOneWidget);
      expect(find.text('সময় পেরিয়েছে'), findsOneWidget);
      expect(find.text('জমা: সকাল ১০:৪৫'), findsOneWidget);
      expect(find.text('১টি ছবি'), findsOneWidget);
    });

    testWidgets('3. CompletedTaskCard renders State 3 (লোকেশনে সমস্যা) correctly', (tester) async {
      final task = TaskModel(
        id: '3',
        title: 'ক্ষেতে সার দেওয়া',
        subTitle: 'সবজি চাষ',
        ownerId: '1',
        ownerName: 'বশির এগ্রো',
        farmName: 'ফার্ম',
        locationId: '1',
        locationName: 'ধলাইরপাড় • জমি ৪',
        fullAddress: 'ঠিকানা',
        timeRange: 'সকাল ৮:০০ – ১০:০০',
        date: 'আজ',
        description: 'বিবরণ',
        instructions: 'নির্দেশনা',
        badgeText: 'সম্পন্ন',
        thumbnailType: 'fertilizer',
        isLate: false,
        geofencePassed: false,
        submittedAt: 'সকাল ৯:৩০',
        evidencePhotoUrls: ['url1', 'url2', 'url3'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletedTaskCard(task: task, onTap: () {}),
          ),
        ),
      );

      expect(find.text('ক্ষেতে সার দেওয়া'), findsOneWidget);
      expect(find.text('লোকেশনে সমস্যা'), findsOneWidget);
      expect(find.text('লোকেশনের বাইরে'), findsOneWidget);
      expect(find.text('সময়ের মধ্যে'), findsOneWidget);
      expect(find.text('জমা: সকাল ৯:৩০'), findsOneWidget);
      expect(find.text('৩টি ছবি'), findsOneWidget);
    });

    testWidgets('4. CompletedTaskCard renders State 4 (সময় ও লোকেশনে সমস্যা) correctly', (tester) async {
      final task = TaskModel(
        id: '4',
        title: 'গরুকে খাবার দেওয়া',
        subTitle: 'গবাদিপশু',
        ownerId: '1',
        ownerName: 'বশির এগ্রো',
        farmName: 'ফার্ম',
        locationId: '1',
        locationName: 'ধলাইরপাড় • শেড ২',
        fullAddress: 'ঠিকানা',
        timeRange: 'সকাল ৮:০০ – ১০:০০',
        date: 'আজ',
        description: 'বিবরণ',
        instructions: 'নির্দেশনা',
        badgeText: 'সম্পন্ন',
        thumbnailType: 'cow',
        isLate: true,
        geofencePassed: false,
        submittedAt: 'সকাল ১১:২০',
        evidencePhotoUrls: ['url1', 'url2', 'url3', 'url4', 'url5'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompletedTaskCard(task: task, onTap: () {}),
          ),
        ),
      );

      expect(find.text('গরুকে খাবার দেওয়া'), findsOneWidget);
      expect(find.text('গবাদিপশু'), findsOneWidget);
      expect(find.text('সময় ও লোকেশনে সমস্যা'), findsOneWidget);
      expect(find.text('লোকেশনের বাইরে'), findsOneWidget);
      expect(find.text('সময় পেরিয়েছে'), findsOneWidget);
      expect(find.text('জমা: সকাল ১১:২০'), findsOneWidget);
      expect(find.text('+৩'), findsOneWidget);
      expect(find.text('৫টি ছবি'), findsOneWidget);
    });

    testWidgets('5. CompletedTaskCard renders on narrow 360px and 320px screens without overflow', (tester) async {
      final task = TaskModel(
        id: '5',
        title: 'ফসল পর্যবেক্ষণ ও দীর্ঘ বিবরণ',
        subTitle: 'মিশ্র কৃষি প্রযুক্তি',
        ownerId: '1',
        ownerName: 'বশির এগ্রো',
        farmName: 'ফার্ম',
        locationId: '1',
        locationName: 'ধলাইরপাড় দীর্ঘ লোকেশন নাম',
        fullAddress: 'ঠিকানা',
        timeRange: 'দুপুর ২:৫২ – বিকাল ৫:০০',
        date: 'আজ',
        description: 'বিবরণ',
        instructions: 'নির্দেশনা',
        badgeText: 'সম্পন্ন',
        thumbnailType: 'fertilizer',
        isLate: true,
        geofencePassed: false,
        submittedAt: 'বিকাল ৫:৫০',
        evidencePhotoUrls: ['url1', 'url2', 'url3', 'url4', 'url5', 'url6', 'url7', 'url8'],
      );

      // Test on 360px wide screen
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: CompletedTaskCard(task: task, onTap: () {}),
            ),
          ),
        ),
      );

      // Verify no exceptions or overflow occurred
      expect(tester.takeException(), isNull);
      expect(find.text('সময় ও লোকেশনে সমস্যা'), findsOneWidget);
      expect(find.text('৮টি ছবি'), findsOneWidget);

      // Test on extra narrow 320px wide screen
      tester.view.physicalSize = const Size(320, 800);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: CompletedTaskCard(task: task, onTap: () {}),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
