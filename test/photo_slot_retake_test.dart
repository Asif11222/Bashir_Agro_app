import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bashir_agro_app_2/data/models/task_photo_model.dart';
import 'package:bashir_agro_app_2/state/app_state.dart';

void main() {
  group('CameraSessionNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    final photo1 = TaskPhotoModel(
      id: 'photo_1',
      localPath: '/path/photo1.jpg',
      capturedAt: DateTime.now(),
      latitude: 23.7808,
      longitude: 90.4152,
      gpsAccuracy: 4.5,
      insideGeofence: true,
      locationName: 'উত্তর মাঠ',
    );

    final photo2 = TaskPhotoModel(
      id: 'photo_2',
      localPath: '/path/photo2.jpg',
      capturedAt: DateTime.now(),
      latitude: 23.7808,
      longitude: 90.4152,
      gpsAccuracy: 4.5,
      insideGeofence: true,
      locationName: 'উত্তর মাঠ',
    );

    final photoRetake = TaskPhotoModel(
      id: 'photo_retake_1',
      localPath: '/path/photo1_retake.jpg',
      capturedAt: DateTime.now(),
      latitude: 23.7808,
      longitude: 90.4152,
      gpsAccuracy: 4.5,
      insideGeofence: true,
      locationName: 'উত্তর মাঠ',
    );

    test('addPhoto adds photos to session buffer', () {
      final notifier = container.read(cameraSessionProvider.notifier);
      notifier.addPhoto(photo1);
      expect(container.read(cameraSessionProvider).length, equals(1));

      notifier.addPhoto(photo2);
      expect(container.read(cameraSessionProvider).length, equals(2));
      expect(container.read(cameraSessionProvider)[0].id, equals('photo_1'));
      expect(container.read(cameraSessionProvider)[1].id, equals('photo_2'));
    });

    test('removePhotoAt removes the exact target photo', () {
      final notifier = container.read(cameraSessionProvider.notifier);
      notifier.addPhoto(photo1);
      notifier.addPhoto(photo2);

      // Remove photo1 (slot 0)
      notifier.removePhotoAt(0);

      final photos = container.read(cameraSessionProvider);
      expect(photos.length, equals(1));
      expect(photos[0].id, equals('photo_2'));
    });

    test('replacePhotoAt replaces photo in-place at the selected slot', () {
      final notifier = container.read(cameraSessionProvider.notifier);
      notifier.addPhoto(photo1);
      notifier.addPhoto(photo2);

      // Retake/replace slot 0 with photoRetake
      notifier.replacePhotoAt(0, photoRetake);

      final photos = container.read(cameraSessionProvider);
      expect(photos.length, equals(2));
      expect(photos[0].id, equals('photo_retake_1'));
      expect(photos[1].id, equals('photo_2'));
    });

    test('selectedPhotoSlotProvider manages active slot state correctly', () {
      final slotNotifier = container.read(selectedPhotoSlotProvider.notifier);
      expect(container.read(selectedPhotoSlotProvider), isNull);

      // Select slot 0 for retake
      slotNotifier.selectSlot(0);
      expect(container.read(selectedPhotoSlotProvider), equals(0));

      // Deselect slot
      slotNotifier.selectSlot(null);
      expect(container.read(selectedPhotoSlotProvider), isNull);
    });

    test('clearSession empties all session photos', () {
      final notifier = container.read(cameraSessionProvider.notifier);
      notifier.addPhoto(photo1);
      notifier.addPhoto(photo2);
      expect(container.read(cameraSessionProvider).length, equals(2));

      notifier.clearSession();
      expect(container.read(cameraSessionProvider), isEmpty);
    });
  });
}
