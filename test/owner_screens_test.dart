import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bashir_agro_app_2/presentation/screens/owner_dashboard/owner_dashboard_screen.dart';
import 'package:bashir_agro_app_2/presentation/screens/farmers/farmers_list_screen.dart';
import 'package:bashir_agro_app_2/presentation/screens/owner_tasks/owner_task_planning_screen.dart';
import 'package:bashir_agro_app_2/presentation/screens/farmers/farmer_activity_screen.dart';
import 'package:bashir_agro_app_2/presentation/screens/owner_photos/owner_photo_details_screen.dart';
import 'package:bashir_agro_app_2/presentation/screens/owner_locations/owner_locations_list_screen.dart';
import 'package:bashir_agro_app_2/presentation/screens/owner_locations/owner_location_map_screen.dart';
import 'package:bashir_agro_app_2/data/models/owner_models.dart';

void main() {
  testWidgets('Owner Dashboard renders greeting and metric cards', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OwnerDashboardScreen(),
        ),
      ),
    );

    expect(find.text('শুভ সকাল,'), findsOneWidget);
    expect(find.text('আব্দুল রহমান'), findsOneWidget);
    expect(find.text('মোট কৃষক'), findsOneWidget);
    expect(find.text('কৃষকদের অগ্রগতি'), findsOneWidget);
  });

  testWidgets('Farmers List renders title, search and farmers', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FarmersListScreen(),
        ),
      ),
    );

    expect(find.text('কৃষকদের তালিকা'), findsOneWidget);
    expect(find.textContaining('মোট কৃষক'), findsOneWidget);
    expect(find.text('ফিল্টার'), findsOneWidget);
  });

  testWidgets('Owner Task Planning renders date and task list', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OwnerTaskPlanningScreen(),
        ),
      ),
    );

    expect(find.text('আজকের কাজের পরিকল্পনা'), findsOneWidget);
    expect(find.textContaining('আজ মোট কাজ'), findsOneWidget);
    expect(find.text('আজ'), findsOneWidget);
    expect(find.text('১ সপ্তাহ'), findsOneWidget);
    expect(find.text('১ মাস'), findsOneWidget);
    expect(find.text('নতুন কাজ যোগ করুন'), findsNothing);

    // Tap 1 Week filter
    await tester.tap(find.text('১ সপ্তাহ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('এই সপ্তাহে মোট কাজ'), findsOneWidget);

    // Tap 1 Month filter
    await tester.tap(find.text('১ মাস'));
    await tester.pumpAndSettle();
    expect(find.textContaining('এই মাসে মোট কাজ'), findsOneWidget);
  });

  testWidgets('Farmer Activity renders profile header and timeline', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FarmerActivityScreen(),
        ),
      ),
    );

    expect(find.byType(FarmerActivityScreen), findsOneWidget);
  });

  testWidgets('Owner Photo Details renders verification and coordinates', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OwnerPhotoDetailsScreen(),
        ),
      ),
    );

    expect(find.text('ছবির বিস্তারিত'), findsOneWidget);
    expect(find.text('সঠিক অবস্থান'), findsOneWidget);
    expect(find.text('23.8103° N, 90.4125° E'), findsOneWidget);
    expect(find.text('নির্ধারিত খামার এলাকা'), findsOneWidget);
  });

  testWidgets('Owner Locations List renders header, search and summary', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OwnerLocationsListScreen(),
        ),
      ),
    );

    expect(find.text('খামারের লোকেশনসমূহ'), findsOneWidget);
    expect(find.text('অ্যাডমিন প্যানেলে যুক্ত সকল প্লট ও জমি'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('লোকেশন সক্রিয় রয়েছে'), findsOneWidget);
  });

  testWidgets('Owner Location Map renders location title and map details', (tester) async {
    const testLocation = OwnerLocationItem(
      id: 1,
      name: 'উত্তর মাঠ',
      locationCode: 'LOC-001',
      type: 'সবজি ক্ষেত',
      address: 'উত্তর ব্লক, কৃষি অঞ্চল-১',
      area: 2.5,
      areaUnit: 'একর',
      latitude: 24.7471,
      longitude: 90.4203,
      status: 'active',
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OwnerLocationMapScreen(
            locationOverride: testLocation,
          ),
        ),
      ),
    );

    expect(find.text('উত্তর মাঠ'), findsWidgets);
    expect(find.textContaining('LOC-001'), findsWidgets);
    expect(find.textContaining('২.৫ একর'), findsWidgets);
    expect(find.text('সব লোকেশন তালিকায় ফিরুন'), findsOneWidget);
  });
}
