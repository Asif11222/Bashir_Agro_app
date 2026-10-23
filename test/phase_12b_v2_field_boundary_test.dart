import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:bashir_agro_app_2/core/network/api_client.dart';
import 'package:bashir_agro_app_2/core/storage/local_storage_service.dart';
import 'package:bashir_agro_app_2/models/field_boundary_model.dart';
import 'package:bashir_agro_app_2/models/task_assignment_model.dart';
import 'package:bashir_agro_app_2/services/api_service.dart';
import 'package:bashir_agro_app_2/presentation/screens/farm_map/field_boundary_map_screen.dart';
import 'package:bashir_agro_app_2/presentation/widgets/field_boundary_preview_card.dart';

http.Response utf8JsonResponse(Map<String, dynamic> data, int statusCode) {
  return http.Response.bytes(
    utf8.encode(jsonEncode(data)),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalStorageService.instance.clearAll();
  });

  group('Phase 12B V2: Flutter Field Boundary & GPS Verification Tests', () {
    // 1. GeoJSON Polygon Boundary Math & Ray-Casting Tests
    test('1. FieldBoundaryModel: Parses GeoJSON polygon, calculates centroid, area, and ray-casting point-in-polygon', () {
      final geoJson = {
        'type': 'Polygon',
        'coordinates': [
          [
            [90.4145, 23.7802], // [lng, lat]
            [90.4160, 23.7818],
            [90.4172, 23.7809],
            [90.4158, 23.7794],
            [90.4145, 23.7802], // closed
          ]
        ]
      };

      final boundary = FieldBoundaryModel.fromGeoJson(geoJson);

      expect(boundary.isNotEmpty, isTrue);
      expect(boundary.vertexCount, equals(5));
      expect(boundary.isClosed, isTrue);

      // Centroid
      final centroid = boundary.centroid;
      expect(centroid.latitude, closeTo(23.7805, 0.005));
      expect(centroid.longitude, closeTo(90.4158, 0.005));

      // Bounding box
      final bbox = boundary.boundingBox;
      expect(bbox['minLat'], closeTo(23.7794, 0.0001));
      expect(bbox['maxLat'], closeTo(23.7818, 0.0001));

      // Area in acres
      final areaAcres = boundary.calculateAreaAcres();
      expect(areaAcres, greaterThan(0.1));

      // Test Point Inside (near centroid)
      expect(boundary.isPointInside(23.7805, 90.4158), isTrue);

      // Test Point Far Outside
      expect(boundary.isPointInside(23.8500, 90.4800), isFalse);

      // Distance to boundary for outside point
      final dist = boundary.distanceToBoundaryMeters(23.8500, 90.4800);
      expect(dist, greaterThan(1000.0));
    });

    // 2. Farm Location Model & API Serialization
    test('2. FarmLocationDetail: Parses boundary GeoJSON from Laravel API', () {
      final apiJson = {
        'id': 5,
        'location_code': 'LOC-000005',
        'name': 'যাত্রাবাড়ী সবজি ক্ষেত',
        'type': 'সবজি ক্ষেত',
        'address': 'যাত্রাবাড়ী, ঢাকা',
        'area': 0.07,
        'area_unit': 'একর',
        'coordinates': {
          'latitude': 23.7094791,
          'longitude': 90.4338479,
        },
        'geofence_radius_meters': 20,
        'boundary': {
          'type': 'Polygon',
          'coordinates': [
            [
              [90.4338093, 23.7095884],
              [90.4337504, 23.7094781],
              [90.4338119, 23.7093481],
              [90.4339645, 23.7094609],
              [90.4339030, 23.7095197],
              [90.4338093, 23.7095884],
            ]
          ]
        }
      };

      final location = FarmLocationDetail.fromJson(apiJson);

      expect(location.id, equals(5));
      expect(location.locationCode, equals('LOC-000005'));
      expect(location.hasBoundaryPolygon, isTrue);
      expect(location.fieldBoundary?.vertexCount, equals(6));
      expect(location.formattedArea, contains('0.07'));
      expect(location.effectiveLatitude, closeTo(23.7094, 0.001));
    });

    // 3. API Service: Fetches Farms with Field Boundary
    test('3. ApiService: getFarms() fetches farm locations with polygon boundaries', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/farms')) {
          return utf8JsonResponse({
            'success': true,
            'count': 1,
            'data': [
              {
                'id': 5,
                'location_code': 'LOC-000005',
                'name': 'যাত্রাবাড়ী সবজি ক্ষেত',
                'type': 'সবজি ক্ষেত',
                'address': 'যাত্রাবাড়ী',
                'area': 0.07,
                'area_unit': 'একর',
                'center': {'latitude': 23.7094791, 'longitude': 90.4338479},
                'boundary': {
                  'type': 'Polygon',
                  'coordinates': [
                    [
                      [90.4338093, 23.7095884],
                      [90.4337504, 23.7094781],
                      [90.4338119, 23.7093481],
                      [90.4339645, 23.7094609],
                      [90.4339030, 23.7095197],
                      [90.4338093, 23.7095884],
                    ]
                  ]
                }
              }
            ]
          }, 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiClient = ApiClient(client: mockClient);
      final apiService = ApiService(client: apiClient);

      final farms = await apiService.getFarms();

      expect(farms.length, equals(1));
      expect(farms.first.id, equals(5));
      expect(farms.first.hasBoundaryPolygon, isTrue);
      expect(farms.first.fieldBoundary?.vertexCount, equals(6));
    });

    // 4. Widget Test: FieldBoundaryPreviewCard renders inside Task Details Screen
    testWidgets('4. UI: FieldBoundaryPreviewCard renders boundary details and map', (tester) async {
      final boundary = FieldBoundaryModel(
        coordinates: [
          GeoPoint(23.7802, 90.4145),
          GeoPoint(23.7818, 90.4160),
          GeoPoint(23.7809, 90.4172),
          GeoPoint(23.7794, 90.4158),
          GeoPoint(23.7802, 90.4145),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: FieldBoundaryPreviewCard(
                boundary: boundary,
                farmName: 'দক্ষিণ মাঠ, ২ নং ব্লক',
                locationCode: 'LOC-001',
                formattedArea: '১.২৫ একর',
                farmerLat: 23.7805,
                farmerLng: 90.4158,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(FieldBoundaryPreviewCard), findsOneWidget);
      expect(find.text('মাঠের বহুভুজ সীমানা (Field Boundary)'), findsOneWidget);
      expect(find.text('PostGIS যাচাইকৃত'), findsOneWidget);
      expect(find.textContaining('দক্ষিণ মাঠ'), findsOneWidget);
      expect(find.textContaining('১.২৫ একর'), findsOneWidget);
      expect(find.text('সীমানা মানচিত্র (Map)'), findsOneWidget);
    });

    // 5. Widget Test: FieldBoundaryMapScreen renders full-screen satellite map
    testWidgets('5. UI: FieldBoundaryMapScreen renders satellite view and toolbar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FieldBoundaryMapScreen(),
          ),
        ),
      );

      expect(find.byType(FieldBoundaryMapScreen), findsOneWidget);
      expect(find.text('মাঠের বহুভুজ সীমানা'), findsOneWidget);
      expect(find.textContaining('PostGIS'), findsWidgets);
      expect(find.text('দিকনির্দেশনা'), findsOneWidget);
      expect(find.text('ছবি তুলুন'), findsOneWidget);
    });

    // 6. PostGIS 422 Rejection vs 201 Acceptance Handshake
    test('6. Verification Handshake: 422 Geofence rejection throws ApiException with distance', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/assignments/99/submit')) {
          return utf8JsonResponse({
            'success': false,
            'message': 'আপনি নির্ধারিত ফার্ম সীমানার বাইরে অবস্থান করছেন। (সীমানা হতে দূরত্ব: 45.2 মিটার)',
            'geofence': {
              'passed': false,
              'distance_meters': 45.2,
              'radius_meters': 20,
              'polygon_boundary': true,
            }
          }, 422);
        }
        return http.Response('Error', 500);
      });

      final apiClient = ApiClient(client: mockClient);
      final apiService = ApiService(client: apiClient);

      try {
        await apiService.submitAssignment(
          assignmentId: 99,
          latitude: 23.8500,
          longitude: 90.4800,
          accuracy: 5.0,
        );
        fail('Expected ApiException to be thrown on 422');
      } on ApiException catch (e) {
        expect(e.statusCode, equals(422));
        expect(e.message, contains('সীমানার বাইরে'));
        expect(e.message, contains('45.2 মিটার'));
      }
    });
  });
}
