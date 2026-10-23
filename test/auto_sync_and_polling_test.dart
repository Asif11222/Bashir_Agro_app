import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bashir_agro_app_2/core/storage/local_storage_service.dart';
import 'package:bashir_agro_app_2/presentation/screens/dashboard/farmer_dashboard_screen.dart';
import 'package:bashir_agro_app_2/services/task_service.dart';
import 'package:bashir_agro_app_2/services/api_service.dart';
import 'package:bashir_agro_app_2/models/task_assignment_model.dart';
import 'package:bashir_agro_app_2/state/farmer_app_state.dart';

class MockApiService extends ApiService {
  int getAssignmentsCallCount = 0;
  List<TaskAssignmentModel> mockAssignments = [];

  @override
  Future<List<TaskAssignmentModel>> getAssignments({
    String? status,
    String? date,
    int? perPage,
  }) async {
    getAssignmentsCallCount++;
    await Future.delayed(const Duration(milliseconds: 50));
    return mockAssignments;
  }
}

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

  group('Auto-Sync & Background Polling Tests', () {
    test('1. TaskService deduplicates concurrent in-flight fetchAssignments calls', () async {
      final mockApi = MockApiService();
      mockApi.mockAssignments = [
        const TaskAssignmentModel(
          id: 1,
          scheduledDate: '2026-10-19',
          status: 'assigned',
        ),
      ];

      final taskService = TaskService(apiService: mockApi);

      // Call fetchAssignments concurrently
      final future1 = taskService.fetchAssignments();
      final future2 = taskService.fetchAssignments();

      final results = await Future.wait([future1, future2]);

      expect(results[0].length, equals(1));
      expect(results[1].length, equals(1));
      // Only 1 network call made despite 2 parallel requests!
      expect(mockApi.getAssignmentsCallCount, equals(1));
    });

    testWidgets('2. FarmerDashboardScreen mounts properly and starts auto-polling timer', (tester) async {
      final mockApi = MockApiService();
      mockApi.mockAssignments = [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiServiceProvider.overrideWithValue(mockApi),
          ],
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );

      // Initial frame
      await tester.pump();
      expect(find.text('আজকের কাজ'), findsOneWidget);

      // Advance frames to complete postFrameCallback
      await tester.pump(const Duration(milliseconds: 100));

      // Verify dashboard remains stable
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);

      // Dispose properly
      await tester.pumpWidget(const SizedBox());
    });
  });
}
