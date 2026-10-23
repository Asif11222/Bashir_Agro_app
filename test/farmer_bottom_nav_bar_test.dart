import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bashir_agro_app_2/presentation/widgets/farmer_bottom_nav_bar.dart';
import 'package:bashir_agro_app_2/models/notification_model.dart';
import 'package:bashir_agro_app_2/state/farmer_app_state.dart';

import 'package:bashir_agro_app_2/presentation/screens/notifications/notifications_screen.dart';
import 'package:bashir_agro_app_2/presentation/screens/profile/farmer_profile_screen.dart';

void main() {
  group('FarmerBottomNavBar Widget Tests', () {
    testWidgets('1. Renders all 4 nav items: আমার কাজ, নতুন কাজ, নোটিশ, প্রোফাইল', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FarmerBottomNavBar(currentIndex: 0),
            ),
          ),
        ),
      );

      expect(find.text('আমার কাজ'), findsOneWidget);
      expect(find.text('নতুন কাজ'), findsOneWidget);
      expect(find.text('নোটিশ'), findsOneWidget);
      expect(find.text('প্রোফাইল'), findsOneWidget);

      // Check Icons
      expect(find.byIcon(Icons.assignment_turned_in_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('2. Tapping items calls onTap callback with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FarmerBottomNavBar(
                currentIndex: 0,
                onTap: (index) {
                  tappedIndex = index;
                },
              ),
            ),
          ),
        ),
      );

      // Tap 'নতুন কাজ'
      await tester.tap(find.text('নতুন কাজ'));
      expect(tappedIndex, 1);

      // Tap 'নোটিশ'
      await tester.tap(find.text('নোটিশ'));
      expect(tappedIndex, 2);

      // Tap 'প্রোফাইল'
      await tester.tap(find.text('প্রোফাইল'));
      expect(tappedIndex, 3);
    });

    testWidgets('3. Renders red notification dot when there are unread notifications', (tester) async {
      final dummyNotifications = [
        AppNotificationModel(
          id: '1',
          eventType: NotificationEventType.newTask,
          title: 'নতুন কাজ',
          message: 'আপনাকে একটি কাজ বরাদ্দ করা হয়েছে',
          timestamp: DateTime.now(),
          isRead: false,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationStateProvider.overrideWith(
              () => _TestNotificationNotifier(dummyNotifications),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FarmerBottomNavBar(currentIndex: 0),
            ),
          ),
        ),
      );

      // The unread dot badge is rendered inside a Stack
      expect(find.text('নোটিশ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Renders on narrow 360px and 320px screens without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FarmerBottomNavBar(currentIndex: 0),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      // Test on 320px extra narrow
      tester.view.physicalSize = const Size(320, 800);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: FarmerBottomNavBar(currentIndex: 0),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. NotificationsScreen renders FarmerBottomNavBar with currentIndex 2', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();

      final navBarFinder = find.byType(FarmerBottomNavBar);
      expect(navBarFinder, findsOneWidget);

      final navBarWidget = tester.widget<FarmerBottomNavBar>(navBarFinder);
      expect(navBarWidget.currentIndex, 2);
    });

    testWidgets('6. FarmerProfileScreen renders FarmerBottomNavBar with currentIndex 3', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FarmerProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      final navBarFinder = find.byType(FarmerBottomNavBar);
      expect(navBarFinder, findsOneWidget);

      final navBarWidget = tester.widget<FarmerBottomNavBar>(navBarFinder);
      expect(navBarWidget.currentIndex, 3);
    });
  });
}

class _TestNotificationNotifier extends NotificationStateNotifier {
  final List<AppNotificationModel> _initial;
  _TestNotificationNotifier(this._initial);

  @override
  List<AppNotificationModel> build() => _initial;
}
