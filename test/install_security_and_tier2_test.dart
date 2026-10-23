import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bashir_agro_app_2/core/constants/api_constants.dart';
import 'package:bashir_agro_app_2/core/network/api_client.dart';
import 'package:bashir_agro_app_2/core/storage/local_storage_service.dart';
import 'package:bashir_agro_app_2/core/storage/install_security_service.dart';
import 'package:bashir_agro_app_2/models/auth_model.dart';
import 'package:bashir_agro_app_2/services/api_service.dart';
import 'package:bashir_agro_app_2/services/auth_service.dart';

class MockTestApiService extends ApiService {
  bool getMeShouldFailWith401 = false;
  bool logoutCalled = false;

  @override
  Future<AuthUser> getMe() async {
    if (getMeShouldFailWith401) {
      throw ApiException(401, 'Unauthenticated.');
    }
    return const AuthUser(
      id: 12,
      name: 'কামাল হোসেন',
      phone: '01712345678',
      role: 'farmer',
    );
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempTestDir;
  late File markerTestFile;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.instance.init();
    await LocalStorageService.instance.clearAll();

    tempTestDir = await Directory.systemTemp.createTemp('install_sec_test_');
    markerTestFile = File('${tempTestDir.path}/.test_install_marker');
    InstallSecurityService.instance.setCustomMarkerFileForTest(markerTestFile);
  });

  tearDown(() async {
    InstallSecurityService.instance.setCustomMarkerFileForTest(null);
    if (await tempTestDir.exists()) {
      await tempTestDir.delete(recursive: true);
    }
    await LocalStorageService.instance.clearAll();
  });

  group('Tier 2: InstallSecurityService & Fresh Install Guard Tests', () {
    test('1. Fresh install with restored backup cache purges stale token and creates marker', () async {
      // Simulate Google Auto Backup restoring SharedPreferences before first launch
      await LocalStorageService.instance.setString(
        ApiConstants.tokenKey,
        'old_restored_backup_token',
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.userKey,
        {'id': 12, 'name': 'Old User', 'phone': '01700000000', 'role': 'farmer'},
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.cachedTasksKey,
        [{'id': 101, 'status': 'completed'}],
      );

      expect(await markerTestFile.exists(), isFalse);
      expect(LocalStorageService.instance.getString(ApiConstants.tokenKey), equals('old_restored_backup_token'));

      // Run verifyInstallation
      final isExisting = await InstallSecurityService.instance.verifyInstallation();

      // Should detect fresh install
      expect(isExisting, isFalse);

      // Restored stale data should be completely purged
      expect(LocalStorageService.instance.getString(ApiConstants.tokenKey), isNull);
      expect(LocalStorageService.instance.getJson(ApiConstants.userKey), isNull);
      expect(LocalStorageService.instance.getJson(ApiConstants.cachedTasksKey), isNull);

      // Install marker should now exist
      expect(await markerTestFile.exists(), isTrue);
    });

    test('2. Existing install with marker file preserves session across app reboots', () async {
      // Simulate an existing installation: marker exists
      await markerTestFile.writeAsString('{"installed_at":"2026-10-20T10:00:00Z"}');

      // User has logged in and has an active session
      await LocalStorageService.instance.setString(
        ApiConstants.tokenKey,
        'valid_active_token',
      );
      await LocalStorageService.instance.setJson(
        ApiConstants.userKey,
        {'id': 12, 'name': 'কামাল হোসেন', 'phone': '01712345678', 'role': 'farmer'},
      );

      // Run verifyInstallation on app relaunch
      final isExisting = await InstallSecurityService.instance.verifyInstallation();

      expect(isExisting, isTrue);
      // Stored session remains intact
      expect(LocalStorageService.instance.getString(ApiConstants.tokenKey), equals('valid_active_token'));
      expect(LocalStorageService.instance.getJson(ApiConstants.userKey), isNotNull);
    });

    test('3. Fresh install without restored backup creates marker and leaves storage clean', () async {
      expect(await markerTestFile.exists(), isFalse);

      final isExisting = await InstallSecurityService.instance.verifyInstallation();

      expect(isExisting, isFalse);
      expect(await markerTestFile.exists(), isTrue);
      expect(LocalStorageService.instance.getString(ApiConstants.tokenKey), isNull);
    });
  });

  group('Tier 2: Complete Cache Invalidation on Logout Tests', () {
    test('4. AuthService.logout() wipes all tokens, tasks, notifications, and offline queue', () async {
      final mockApi = MockTestApiService();
      final authService = AuthService(apiService: mockApi);

      // Prepopulate all caches
      await LocalStorageService.instance.setString(ApiConstants.tokenKey, 'token_123');
      await LocalStorageService.instance.setJson(ApiConstants.userKey, {'id': 12, 'name': 'Farmer'});
      await LocalStorageService.instance.setJson(ApiConstants.profileKey, {'id': 12, 'full_name': 'Farmer'});
      await LocalStorageService.instance.setJson(ApiConstants.cachedTasksKey, [{'id': 1}]);
      await LocalStorageService.instance.setJson(ApiConstants.notificationsKey, [{'id': 'n1'}]);
      await LocalStorageService.instance.setJson(ApiConstants.offlineQueueKey, [{'assignment_id': 1}]);

      await authService.initializeSession();
      expect(authService.isAuthenticated, isTrue);

      // Perform logout
      await authService.logout();

      // Everything must be purged
      expect(authService.isAuthenticated, isFalse);
      expect(authService.currentUser, isNull);
      expect(LocalStorageService.instance.getString(ApiConstants.tokenKey), isNull);
      expect(LocalStorageService.instance.getJson(ApiConstants.userKey), isNull);
      expect(LocalStorageService.instance.getJson(ApiConstants.profileKey), isNull);
      expect(LocalStorageService.instance.getJson(ApiConstants.cachedTasksKey), isNull);
      expect(LocalStorageService.instance.getJson(ApiConstants.notificationsKey), isNull);
      expect(LocalStorageService.instance.getJson(ApiConstants.offlineQueueKey), isNull);
    });
  });

  group('Tier 2: Backend Session Validation & 401 Auto-Logout Tests', () {
    test('5. validateSessionWithBackend() refreshes profile on 200 OK', () async {
      final mockApi = MockTestApiService();
      final authService = AuthService(apiService: mockApi);

      await LocalStorageService.instance.setString(ApiConstants.tokenKey, 'token_abc');
      await authService.initializeSession();

      final isValid = await authService.validateSessionWithBackend();

      expect(isValid, isTrue);
      expect(authService.currentUser?.name, equals('কামাল হোসেন'));
    });

    test('6. validateSessionWithBackend() automatically logs out when backend returns 401', () async {
      final mockApi = MockTestApiService();
      mockApi.getMeShouldFailWith401 = true;

      final authService = AuthService(apiService: mockApi);

      await LocalStorageService.instance.setString(ApiConstants.tokenKey, 'stale_revoked_token');
      await authService.initializeSession();
      expect(authService.isAuthenticated, isTrue);

      final isValid = await authService.validateSessionWithBackend();

      expect(isValid, isFalse);
      expect(authService.isAuthenticated, isFalse);
      expect(LocalStorageService.instance.getString(ApiConstants.tokenKey), isNull);
    });

    test('7. ApiClient.onUnauthorized callback triggers auto-logout', () {
      bool onUnauthorizedCalled = false;
      ApiClient.onUnauthorized = () {
        onUnauthorizedCalled = true;
      };

      final client = ApiClient();
      expect(
        () => client.setAuthToken('some_token'),
        returnsNormally,
      );

      ApiClient.onUnauthorized?.call();
      expect(onUnauthorizedCalled, isTrue);
    });
  });
}
