import 'package:bashir_agro_app_2/data/models/owner_models.dart';
import 'package:bashir_agro_app_2/presentation/screens/owner_dashboard/owner_dashboard_screen.dart';
import 'package:bashir_agro_app_2/state/owner_state.dart';
import 'package:bashir_agro_app_2/state/app_appearance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Keep this test independent of network requests and backend data.
class _DashboardWithManyLocations extends OwnerDashboardNotifier {
  @override
  OwnerDashboardState build() => OwnerDashboardState(
        selectedDate: DateTime(2026, 10, 23),
        locations: List.generate(
          25,
          (index) => OwnerLocationItem(
            id: index + 1,
            name: 'লোকেশন ${index + 1}',
            locationCode: 'LOC-${index + 1}',
            type: 'খামার',
            address: 'বাংলাদেশ',
            area: 1,
            areaUnit: 'একর',
            latitude: 23.8,
            longitude: 90.4,
            status: 'active',
          ),
        ),
      );

  @override
  Future<void> loadDashboard({
    DateTime? date,
    OwnerLocationItem? location,
    bool clearLocation = false,
  }) async {}
}

void main() {
  testWidgets('Location picker stays scrollable without overflow on short screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ownerDashboardProvider.overrideWith(_DashboardWithManyLocations.new),
          appAppearanceProvider.overrideWith((ref) async => const AppAppearance({}, {})),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData.fromView(tester.view).copyWith(
              textScaler: const TextScaler.linear(1.5),
            ),
            child: const OwnerDashboardScreen(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('সব লোকেশন'));
    await tester.pumpAndSettle();
    expect(find.text('লোকেশন নির্বাচন করুন'), findsOneWidget);
    expect(tester.takeException(), isNull);

    final list = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(Scrollable),
    );
    expect(list, findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('লোকেশন ২৫'),
      160,
      scrollable: list,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('লোকেশন ২৫'));
    await tester.pumpAndSettle();
    expect(find.text('লোকেশন নির্বাচন করুন'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
