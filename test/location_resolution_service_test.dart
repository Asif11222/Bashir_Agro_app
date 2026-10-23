import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bashir_agro_app_2/models/task_assignment_model.dart';
import 'package:bashir_agro_app_2/services/location_resolution_service.dart';

void main() {
  group('LocationResolutionService Unit Tests', () {
    test('1. Resolves to Farm Location when user is inside farm circular geofence', () async {
      final mockLocations = <FarmLocationDetail>[
        const FarmLocationDetail(
          id: 1,
          locationCode: 'LOC-001',
          name: 'উত্তর মাঠ',
          type: 'সবজি ক্ষেত',
          address: 'উত্তর ব্লক',
          latitude: 24.7471,
          longitude: 90.4203,
          geofenceRadiusMeters: 50,
        ),
      ];

      final service = LocationResolutionService();
      // Point 10 meters away from center
      final result = await service.resolveLocation(
        latitude: 24.74715,
        longitude: 90.42035,
        accuracy: 5.0,
        availableLocations: mockLocations,
      );

      expect(result.isInsideFarm, isTrue);
      expect(result.displayName, 'উত্তর মাঠ • সবজি ক্ষেত');
      expect(result.badgeText, 'প্লটের ভেতরে আছেন');
      expect(result.farmLocationId, 1);
    });

    test('2. Resolves to Farm Location when user is inside polygon boundary', () async {
      final mockLocations = <FarmLocationDetail>[
        const FarmLocationDetail(
          id: 5,
          locationCode: 'LOC-005',
          name: 'ধানের জমি প্লট',
          type: 'ধান',
          address: 'দক্ষিণ মাঠ',
          latitude: 23.7018,
          longitude: 90.4339,
          geofenceRadiusMeters: 20,
          boundary: {
            'type': 'Polygon',
            'coordinates': [
              [
                [90.4330, 23.7010],
                [90.4350, 23.7010],
                [90.4350, 23.7030],
                [90.4330, 23.7030],
                [90.4330, 23.7010],
              ]
            ],
          },
        ),
      ];

      final service = LocationResolutionService();
      // Inside polygon (23.7020, 90.4340)
      final result = await service.resolveLocation(
        latitude: 23.7020,
        longitude: 90.4340,
        availableLocations: mockLocations,
      );

      expect(result.isInsideFarm, isTrue);
      expect(result.displayName, 'ধানের জমি প্লট • ধান');
      expect(result.badgeText, 'প্লটের ভেতরে আছেন');
      expect(result.farmLocationId, 5);
    });

    test('3. Resolves to real Reverse Geocoded address in Bangla when outside all farm plots', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'address': {
              'suburb': 'মিরপুর ১০',
              'city': 'ঢাকা',
              'country': 'বাংলাদেশ',
            },
            'display_name': 'মিরপুর ১০, ঢাকা, বাংলাদেশ',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = LocationResolutionService(httpClient: mockHttpClient);
      // Coordinates away from any farm (e.g. Mirpur, Dhaka)
      final result = await service.resolveLocation(
        latitude: 23.8071,
        longitude: 90.3686,
        availableLocations: [],
      );

      expect(result.isInsideFarm, isFalse);
      expect(result.displayName, 'মিরপুর ১০, ঢাকা');
      expect(result.badgeText, 'জিপিএস অবস্থান');
      expect(result.farmLocationId, isNull);
    });

    test('4. Falls back to formatted Bangla coordinates when offline or geocoder fails', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = LocationResolutionService(httpClient: mockHttpClient);
      final result = await service.resolveLocation(
        latitude: 23.8103,
        longitude: 90.4125,
        availableLocations: [],
      );

      expect(result.isInsideFarm, isFalse);
      expect(result.displayName, contains('২৩.৮১০৩'));
      expect(result.displayName, contains('৯০.৪১২৫'));
      expect(result.badgeText, 'জিপিএস অবস্থান');
    });
  });
}
