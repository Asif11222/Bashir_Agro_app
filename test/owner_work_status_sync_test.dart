import 'package:flutter_test/flutter_test.dart';
import 'package:bashir_agro_app_2/data/models/owner_models.dart';

void main() {
  test('Farmer engagement follows unfinished work, not history or location', () {
    const base = {
      'id': 12,
      'name': 'Kamál',
      'locations': [
        {'name': 'South plot', 'area': 3.0}
      ],
      'total_tasks': 2,
      'completed_tasks': 2,
      'progress_percent': 100,
    };

    final finished = FarmerItemModel.fromJson({
      ...base,
      'is_assigned': false,
      'active_tasks': 0,
    });
    expect(finished.isAssigned, false);
    expect(finished.progressPercent, 100);

    final unfinished = FarmerItemModel.fromJson({
      ...base,
      'is_assigned': true,
      'active_tasks': 1,
    });
    expect(unfinished.isAssigned, true);

    // Server flag is authoritative even if a count is inconsistent or stale.
    expect(FarmerItemModel.fromJson({
      ...base,
      'is_assigned': false,
      'active_tasks': 1,
    }).isAssigned, false);

    // Old payloads never treat farms or historical tasks as assignments.
    expect(FarmerItemModel.fromJson(base).isAssigned, false);
    expect(FarmerItemModel.fromJson({
      ...base,
      'active_tasks': 1,
    }).isAssigned, true);
  });

  test('Owner cards use server assignment status without interpreting submission as status', () {
    const base = {
      'id': 18,
      'scheduled_date': '2026-10-23',
      'start_time': '08:00:00',
      'end_time': '09:00:00',
      'task': {'name': 'সার প্রয়োগ'},
      'farmer': {'full_name': 'Sample farmer'},
      'location': {'name': 'Field 1'},
    };
    for (final entry in {
      'assigned': 'নির্ধারিত',
      'pending': 'নির্ধারিত',
      'in_progress': 'চলমান',
      'completed': 'সম্পন্ন',
      'late': 'দেরি',
      'cancelled': 'বাতিল',
    }.entries) {
      final model = OwnerTaskPlanModel.fromJson({...base, 'status': entry.key});
      expect(model.statusText, entry.value);
      expect(model.completionIssueLabel, isNull);
    }
  });

  test('Completed task card statuses use actual submission values', () {
    const base = {
      'id': 18,
      'status': 'completed',
      'submission': {
        'submitted_at': '2026-10-23T10:00:00+06:00',
        'geofence': {'passed': false},
        'is_late': true,
        'evidence_photos': [
          {'url': 'https://example.com/a.jpg'},
          {'url': 'https://example.com/b.jpg'},
        ],
      },
    };
    final model = OwnerTaskPlanModel.fromJson(base);
    expect(model.completionIssueLabel, 'সময় ও লোকেশনে সমস্যা');
    expect(model.photoUrls.length, 2);
    expect(model.hasSubmission, true);
    expect(model.isLate, true);
    expect(model.geofencePassed, false);

    final withoutEvidence = OwnerTaskPlanModel.fromJson({
      ...base, 'submission': null,
    });
    expect(withoutEvidence.hasSubmission, false);
    expect(withoutEvidence.completionIssueLabel, isNull);
    expect(withoutEvidence.photoUrls, isEmpty);
  });

  test('Farmer activities preserve statuses and dates for filtering', () {
    final activity = FarmerActivityItemModel.fromJson({
      'id': 3,
      'status': 'in_progress',
      'scheduled_date': '2026-10-21',
      'start_time': '08:00',
      'task': {'name': 'Water crop'},
    });
    expect(activity.statusText, 'চলমান');
    expect(activity.isCompleted, false);
    expect(activity.scheduledDate, '2026-10-21');
  });

  test('Farmer task engagement lifecycle (unassigned -> assigned -> completed unassigned)', () {
    // 1. Before task assignment: no active tasks, unassigned
    final beforeAssignment = FarmerItemModel.fromJson({
      'id': 5,
      'name': 'Sakib',
      'is_assigned': false,
      'active_tasks': 0,
      'total_tasks': 0,
      'completed_tasks': 0,
    });
    expect(beforeAssignment.isAssigned, false);

    // 2. After task assigned (active / in-progress / pending / late): assigned
    final afterAssignment = FarmerItemModel.fromJson({
      'id': 5,
      'name': 'Sakib',
      'is_assigned': true,
      'active_tasks': 1,
      'total_tasks': 1,
      'completed_tasks': 0,
    });
    expect(afterAssignment.isAssigned, true);

    // 3. After task finished/completed: back to unassigned
    final afterCompletion = FarmerItemModel.fromJson({
      'id': 5,
      'name': 'Sakib',
      'is_assigned': false,
      'active_tasks': 0,
      'total_tasks': 1,
      'completed_tasks': 1,
    });
    expect(afterCompletion.isAssigned, false);

    // 4. Null flag fallback when active_tasks > 0
    final nullFlagWithActive = FarmerItemModel.fromJson({
      'id': 5,
      'name': 'Sakib',
      'is_assigned': null,
      'active_tasks': 1,
      'total_tasks': 1,
      'completed_tasks': 0,
    });
    expect(nullFlagWithActive.isAssigned, true);

    // 5. Null flag fallback when total_tasks > completed_tasks
    final nullFlagWithPending = FarmerItemModel.fromJson({
      'id': 5,
      'name': 'Sakib',
      'is_assigned': null,
      'active_tasks': null,
      'total_tasks': 2,
      'completed_tasks': 1,
    });
    expect(nullFlagWithPending.isAssigned, true);
  });
}

