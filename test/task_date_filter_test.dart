import 'package:flutter_test/flutter_test.dart';
import 'package:bashir_agro_app_2/core/utils/date_formatter.dart';
import 'package:bashir_agro_app_2/models/task_assignment_model.dart';
import 'package:bashir_agro_app_2/services/task_service.dart';

void main() {
  group('DateFormatter Tests', () {
    test('formatDateString formats ISO date string to Bangla', () {
      final formatted = DateFormatter.formatDateString('2026-10-22');
      expect(formatted, contains('২২'));
      expect(formatted, contains('অক্টোবর'));
      expect(formatted, contains('২০২৬'));
    });

    test('formatDateString formats ISO datetime string properly', () {
      final formatted = DateFormatter.formatDateString('2026-10-22 08:00:00');
      expect(formatted, contains('২২'));
      expect(formatted, contains('অক্টোবর'));
      expect(formatted, contains('২০২৬'));
    });

    test('formatShortDate formats date string to short Bangla month and day', () {
      final short = DateFormatter.formatShortDate('2026-10-22');
      expect(short, equals('২২ অক্টো'));
    });
  });

  group('TaskService Date Filtering Tests', () {
    final taskService = TaskService();

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final futureDate = now.add(const Duration(days: 6));
    final futureStr = '${futureDate.year}-${futureDate.month.toString().padLeft(2, '0')}-${futureDate.day.toString().padLeft(2, '0')}';
    final pastDate = now.subtract(const Duration(days: 2));
    final pastStr = '${pastDate.year}-${pastDate.month.toString().padLeft(2, '0')}-${pastDate.day.toString().padLeft(2, '0')}';

    final taskToday = TaskAssignmentModel(
      id: 1,
      scheduledDate: todayStr,
      status: 'assigned',
      startTime: '08:00',
      endTime: '10:00',
    );

    final taskFuture = TaskAssignmentModel(
      id: 2,
      scheduledDate: futureStr,
      status: 'assigned',
      startTime: '09:00',
      endTime: '11:00',
    );

    final taskPast = TaskAssignmentModel(
      id: 3,
      scheduledDate: pastStr,
      status: 'assigned',
      startTime: '10:00',
      endTime: '12:00',
    );

    final taskCompleted = TaskAssignmentModel(
      id: 4,
      scheduledDate: futureStr,
      status: 'completed',
      startTime: '08:00',
      endTime: '10:00',
    );

    final allTasks = [taskToday, taskFuture, taskPast, taskCompleted];

    test('filterTodayTasks does NOT include future tasks', () {
      final todayTasks = taskService.filterTodayTasks(allTasks);
      expect(todayTasks.any((t) => t.id == 2), isFalse);
      expect(todayTasks.any((t) => t.id == 1), isTrue);
    });

    test('filterUpcomingTasks includes only future incomplete tasks', () {
      final upcomingTasks = taskService.filterUpcomingTasks(allTasks);
      expect(upcomingTasks.any((t) => t.id == 2), isTrue);
      expect(upcomingTasks.any((t) => t.id == 1), isFalse);
      expect(upcomingTasks.any((t) => t.id == 3), isFalse);
      expect(upcomingTasks.any((t) => t.id == 4), isFalse); // Completed task should not be in upcoming
    });

    test('filterPendingTasks includes all active tasks', () {
      final pendingTasks = taskService.filterPendingTasks(allTasks);
      expect(pendingTasks.any((t) => t.id == 1), isTrue);
      expect(pendingTasks.any((t) => t.id == 2), isTrue);
      expect(pendingTasks.any((t) => t.id == 3), isTrue);
      expect(pendingTasks.any((t) => t.id == 4), isFalse);
    });
  });
}
