import 'package:bashir_agro_app_2/core/utils/task_thumbnail_resolver.dart';
import 'package:bashir_agro_app_2/data/models/owner_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Farmer and owner work icons follow the same category/name rules', () {
    expect(TaskThumbnailResolver.resolve(category: 'মাছ চাষ', name: 'sample'), 'fish');
    expect(TaskThumbnailResolver.resolve(category: 'সবজি চাষ', name: 'sample work'), 'vegetable');
    expect(TaskThumbnailResolver.resolve(category: 'গরু পালন', name: 'গরু পরিচর্যা'), 'cow');
    expect(TaskThumbnailResolver.resolve(category: 'কৃষি', name: 'সার প্রয়োগ'), 'fertilizer');
    expect(TaskThumbnailResolver.resolve(), 'vegetable');
  });

  test('Owner work cards show the work icon while preserving submitted photos', () {
    const payload = {
      'id': 22,
      'status': 'completed',
      'task': {'name': 'sample', 'category': 'মাছ চাষ'},
      'submission': {
        'evidence_photos': [
          {'url': 'https://example.com/work-photo.jpg'},
        ],
      },
    };
    final ownerTask = OwnerTaskPlanModel.fromJson(payload);
    final farmerActivity = FarmerActivityItemModel.fromJson(payload);

    expect(ownerTask.thumbnailType, 'fish');
    expect(farmerActivity.thumbnailType, 'fish');
    expect(ownerTask.photoUrls, ['https://example.com/work-photo.jpg']);
    expect(farmerActivity.photoUrls, ['https://example.com/work-photo.jpg']);
    expect(ownerTask.isCompleted, true);
    expect(farmerActivity.isCompleted, true);
  });
}
