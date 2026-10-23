import 'package:flutter_test/flutter_test.dart';
import 'package:bashir_agro_app_2/data/models/owner_models.dart';

void main() {
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
}
