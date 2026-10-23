import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bashir_agro_app_2/presentation/screens/new_task/new_task_screen.dart';
import 'package:bashir_agro_app_2/state/app_state.dart';
import 'package:bashir_agro_app_2/state/farmer_app_state.dart';
import 'package:bashir_agro_app_2/services/gps_service.dart';
import 'package:bashir_agro_app_2/services/location_resolution_service.dart';
import 'package:bashir_agro_app_2/data/repositories/task_repository.dart';
import 'package:bashir_agro_app_2/models/task_assignment_model.dart';

class MockLocationResolutionService extends LocationResolutionService {
  final ResolvedLocation stubResult;
  MockLocationResolutionService(this.stubResult);

  @override
  Future<ResolvedLocation> resolveLocation({
    required double latitude,
    required double longitude,
    double accuracy = 10.0,
    List<FarmLocationDetail>? availableLocations,
  }) async {
    return stubResult;
  }
}

void main() {
  const defaultStubLocation = ResolvedLocation(
    displayName: 'মিরপুর ১০, ঢাকা',
    badgeText: 'জিপিএস অবস্থান',
    isInsideFarm: false,
    latitude: 23.8071,
    longitude: 90.3686,
    accuracy: 8.0,
  );

  setUp(() {
    GpsService().setSimulationMode(true, true);
  });
  tearDown(() {
    GpsService().setSimulationMode(false);
  });

  Widget createWidget({ResolvedLocation? location}) {
    return ProviderScope(
      overrides: [
        taskRepositoryProvider.overrideWithValue(MockTaskRepository()),
        locationResolutionServiceProvider.overrideWithValue(
          MockLocationResolutionService(location ?? defaultStubLocation),
        ),
      ],
      child: const MaterialApp(
        home: NewTaskScreen(),
      ),
    );
  }

  group('NewTaskScreen UI and Dynamic Location Tests', () {
    testWidgets('1. Renders top appbar, instructions, mic button, and section headings', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Top Header
      expect(find.text('নতুন কাজ যোগ করুন'), findsOneWidget);
      expect(find.text('যে কাজ করেছেন, তা বলুন বা লিখুন'), findsOneWidget);

      // Section 1: Voice & instruction
      expect(find.text('কী কাজ করেছেন?'), findsOneWidget);
      expect(find.text('কীভাবে বলবেন শুনুন'), findsOneWidget);
      expect(find.text('চাপ দিয়ে বলুন'), findsOneWidget);
      expect(find.text('আপনার কথা বাংলায় লেখা হবে'), findsOneWidget);

      // Section 2: Text description
      expect(find.text('কাজের বিবরণ'), findsOneWidget);
      expect(find.text('আজ সবজি ক্ষেতে সেচের পাইপ মেরামত করেছি।'), findsOneWidget);
      expect(find.text('ভুল হলে ঠিক করুন বা আবার বলুন'), findsOneWidget);
      expect(find.text('আবার বলুন'), findsOneWidget);

      // Section 3: Photo (optional)
      expect(find.text('কাজের ছবি'), findsOneWidget);
      expect(find.text('ঐচ্ছিক'), findsOneWidget);
      expect(find.text('ছবি তুলুন বা যোগ করুন'), findsOneWidget);
      expect(find.text('এখন ছবি না দিলেও কাজ জমা হবে। পরে ছবি যোগ করতে পারবেন।'), findsOneWidget);

      // Section 4: Metadata (Location & Time)
      expect(find.text('স্বয়ংক্রিয়ভাবে যুক্ত হবে'), findsOneWidget);
      expect(find.text('বর্তমান লোকেশন'), findsOneWidget);
      expect(find.text('মিরপুর ১০, ঢাকা'), findsOneWidget);
      expect(find.text('জিপিএস অবস্থান'), findsOneWidget);
      expect(find.text('জমা দেওয়ার সময় লোকেশন ও সময় নেওয়া হবে'), findsOneWidget);

      // Section 5: Guarantee banner
      expect(find.text('জমা দিলে কাজটি সম্পন্ন হিসেবে যুক্ত হবে'), findsOneWidget);

      // Section 6: Submit button
      expect(find.text('কাজ জমা দিন'), findsOneWidget);
    });

    testWidgets('2. Tapping "কীভাবে বলবেন শুনুন" opens audio guide modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('কীভাবে বলবেন শুনুন'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('মাইক্রোফোন বাটনে চাপ দিয়ে স্পষ্ট বাংলায় বলুন আপনি আজ খামারে কী কাজ সম্পন্ন করেছেন।'), findsOneWidget);
      expect(find.text('বুঝেছি'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('বুঝেছি'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('মাইক্রোফোন বাটনে চাপ দিয়ে স্পষ্ট বাংলায় বলুন আপনি আজ খামারে কী কাজ সম্পন্ন করেছেন।'), findsNothing);
    });

    testWidgets('3. Tapping photo box opens photo options modal bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.ensureVisible(find.text('ছবি তুলুন বা যোগ করুন'));
      await tester.tap(find.text('ছবি তুলুন বা যোগ করুন'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('কাজের ছবি যোগ করুন (ঐচ্ছিক)'), findsOneWidget);
      expect(find.text('সরাসরি ক্যামেরা দিয়ে ছবি তুলুন'), findsOneWidget);
      expect(find.text('ডেমো স্যাম্পল ছবি নির্বাচন করুন'), findsOneWidget);

      // Select demo sample photo
      await tester.tap(find.text('ডেমো স্যাম্পল ছবি নির্বাচন করুন'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('১টি ছবি নির্বাচিত হয়েছে'), findsOneWidget);
    });

    testWidgets('4. Submitting valid task triggers celebration dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to submit button and tap
      await tester.ensureVisible(find.text('কাজ জমা দিন'));
      await tester.tap(find.text('কাজ জমা দিন'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('কাজ সফলভাবে জমা হয়েছে!'), findsOneWidget);
      expect(find.text('আপনার নতুন কাজটি "সম্পন্ন কাজ" তালিকায় যুক্ত করা হয়েছে।'), findsOneWidget);
      expect(find.text('সম্পন্ন কাজের তালিকা দেখুন'), findsOneWidget);
    });

    testWidgets('5. Displays farm name and "প্লটের ভেতরে আছেন" when inside farm plot', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const stubFarmLocation = ResolvedLocation(
        displayName: 'উত্তর মাঠ • সবজি ক্ষেত',
        badgeText: 'প্লটের ভেতরে আছেন',
        isInsideFarm: true,
        farmLocationId: 1,
        latitude: 24.7471,
        longitude: 90.4203,
        accuracy: 4.5,
      );

      await tester.pumpWidget(createWidget(location: stubFarmLocation));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('উত্তর মাঠ • সবজি ক্ষেত'), findsOneWidget);
      expect(find.text('প্লটের ভেতরে আছেন'), findsOneWidget);
    });
  });
}
