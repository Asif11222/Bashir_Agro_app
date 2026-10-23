import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bashir_agro_app_2/core/constants/api_constants.dart';
import 'package:bashir_agro_app_2/core/storage/local_storage_service.dart';
import 'package:bashir_agro_app_2/presentation/routes/app_router.dart';
import 'package:bashir_agro_app_2/services/auth_service.dart';
import 'package:bashir_agro_app_2/state/app_state.dart';
import 'package:bashir_agro_app_2/state/farmer_app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.instance.init();
    await LocalStorageService.instance.clearAll();
  });

  tearDown(() async {
    await LocalStorageService.instance.clearAll();
  });

  group('Session Persistence & Auto-Login Tests', () {
    test('1. getInitialLocation returns /login when no session is stored', () {
      expect(getInitialLocation(), equals('/login'));
    });

    test('2. getInitialLocation returns /dashboard when farmer session is stored', () async {
      await LocalStorageService.instance.setString(
        ApiConstants.tokenKey,
        '101|sanctum_farmer_test_token',
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.userKey,
        {
          'id': 12,
          'name': 'কামাল হোসেন',
          'phone': '01712345678',
          'role': 'farmer',
        },
      );

      expect(getInitialLocation(), equals('/dashboard'));
    });

    test('3. getInitialLocation returns /owner-dashboard when owner session is stored', () async {
      await LocalStorageService.instance.setString(
        ApiConstants.tokenKey,
        '202|sanctum_owner_test_token',
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.userKey,
        {
          'id': 1,
          'name': 'বশির আহমেদ',
          'phone': '01812345678',
          'role': 'owner',
        },
      );

      expect(getInitialLocation(), equals('/owner-dashboard'));
    });

    test('4. AuthService automatically restores session from local storage upon instantiation', () async {
      await LocalStorageService.instance.setString(
        ApiConstants.tokenKey,
        '303|sanctum_persisted_token',
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.userKey,
        {
          'id': 5,
          'name': 'করিম মিয়া',
          'phone': '01911223344',
          'role': 'farmer',
        },
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.profileKey,
        {
          'id': 5,
          'farmer_code': 'FAR-005',
          'full_name': 'করিম মিয়া',
          'phone': '01911223344',
        },
      );

      // Create fresh AuthService instance (simulating app relaunch)
      final authService = AuthService();
      expect(authService.isAuthenticated, isTrue);
      expect(authService.token, equals('303|sanctum_persisted_token'));
      expect(authService.currentUser?.name, equals('করিম মিয়া'));
      expect(authService.farmerProfile?.farmerCode, equals('FAR-005'));
    });

    test('5. FarmerAuthNotifier and CurrentUserNotifier auto-initialize from persisted session', () async {
      await LocalStorageService.instance.setString(
        ApiConstants.tokenKey,
        '404|sanctum_riverpod_token',
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.userKey,
        {
          'id': 9,
          'name': 'রফিকুল ইসলাম',
          'phone': '01611223344',
          'role': 'farmer',
        },
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final farmerAuth = container.read(farmerAuthProvider);
      expect(farmerAuth.isAuthenticated, isTrue);
      expect(farmerAuth.user?.phone, equals('01611223344'));

      final currentUser = container.read(currentUserProvider);
      expect(currentUser, isNotNull);
      expect(currentUser?.name, equals('রফিকুল ইসলাম'));
      expect(currentUser?.isFarmer, isTrue);
    });

    test('6. Logging out clears session and restores unauthenticated state', () async {
      await LocalStorageService.instance.setString(
        ApiConstants.tokenKey,
        '505|sanctum_logout_token',
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.userKey,
        {
          'id': 7,
          'name': 'লগআউট পরীক্ষার্থী',
          'phone': '01511223344',
          'role': 'farmer',
        },
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(farmerAuthProvider).isAuthenticated, isTrue);

      await container.read(farmerAuthProvider.notifier).logout();

      expect(container.read(farmerAuthProvider).isAuthenticated, isFalse);
      expect(container.read(currentUserProvider), isNull);
      expect(LocalStorageService.instance.getString(ApiConstants.tokenKey), isNull);
      expect(getInitialLocation(), equals('/login'));
    });

    testWidgets('7. App navigates directly to Farmer Dashboard when session is already stored', (tester) async {
      await LocalStorageService.instance.setString(
        ApiConstants.tokenKey,
        '707|sanctum_autologin_token',
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.userKey,
        {
          'id': 15,
          'name': 'আব্দুল হালিম',
          'phone': '01700112233',
          'role': 'farmer',
        },
      );

      final testRouter = createAppRouter();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Farmer Dashboard header should be visible, and login CTA should not be present
      expect(find.text('আজকের কাজ'), findsOneWidget);
      expect(find.text('লগইন'), findsNothing);
    });
  });
}
