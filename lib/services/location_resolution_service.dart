import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../core/utils/date_formatter.dart';
import '../models/field_boundary_model.dart';
import '../models/task_assignment_model.dart';
import 'api_service.dart';

class ResolvedLocation {
  final String displayName;
  final String badgeText;
  final bool isInsideFarm;
  final int? farmLocationId;
  final double latitude;
  final double longitude;
  final double accuracy;

  const ResolvedLocation({
    required this.displayName,
    required this.badgeText,
    required this.isInsideFarm,
    this.farmLocationId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
  });
}

class LocationResolutionService {
  final ApiService? apiService;
  final http.Client? httpClient;

  LocationResolutionService({
    this.apiService,
    this.httpClient,
  });

  /// Resolves the human-readable Bangla location and farm membership.
  /// 1. Checks if within any registered FarmLocation boundary/radius.
  /// 2. If outside, reverse-geocodes via OpenStreetMap Nominatim in Bangla.
  /// 3. Falls back to formatted Bangla coordinates if offline.
  Future<ResolvedLocation> resolveLocation({
    required double latitude,
    required double longitude,
    double accuracy = 10.0,
    List<FarmLocationDetail>? availableLocations,
  }) async {
    List<FarmLocationDetail> locations = availableLocations ?? [];

    if (locations.isEmpty && apiService != null) {
      try {
        final list = await apiService!.getFarmLocations();
        locations = list
            .map<FarmLocationDetail>(
              (l) => FarmLocationDetail(
                id: l.id,
                locationCode: l.locationCode,
                name: l.name,
                type: l.type,
                address: l.address,
                latitude: l.latitude,
                longitude: l.longitude,
                geofenceRadiusMeters: l.geofenceRadiusMeters,
                boundary: l.boundary,
              ),
            )
            .toList();
      } catch (e) {
        debugPrint('Could not fetch farm locations for matching: $e');
      }
    }

    // Step 1: Check if inside any registered farm location
    for (final farm in locations) {
      // Polygon boundary check via built-in getter
      final boundary = farm.fieldBoundary;
      if (boundary != null && boundary.isNotEmpty) {
        if (boundary.isPointInside(latitude, longitude, 20.0)) {
          final typeSuffix = farm.type.isNotEmpty ? ' • ${farm.type}' : '';
          return ResolvedLocation(
            displayName: '${farm.name}$typeSuffix',
            badgeText: 'প্লটের ভেতরে আছেন',
            isInsideFarm: true,
            farmLocationId: farm.id,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
          );
        }
      }

      // Circular radius check
      if (farm.latitude != null && farm.longitude != null) {
        final dist = Geolocator.distanceBetween(
          latitude,
          longitude,
          farm.latitude!,
          farm.longitude!,
        );
        final threshold = farm.geofenceRadiusMeters > 0 ? farm.geofenceRadiusMeters.toDouble() : 40.0;
        if (dist <= threshold) {
          final typeSuffix = (farm.type != null && farm.type!.isNotEmpty) ? ' • ${farm.type}' : '';
          return ResolvedLocation(
            displayName: '${farm.name}$typeSuffix',
            badgeText: 'প্লটের ভেতরে আছেন',
            isInsideFarm: true,
            farmLocationId: farm.id,
            latitude: latitude,
            longitude: longitude,
            accuracy: accuracy,
          );
        }
      }
    }

    // Step 2: Outside farm - Perform reverse geocoding via OpenStreetMap Nominatim
    String? geocodedName;
    try {
      final client = httpClient ?? http.Client();
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&accept-language=bn',
      );
      final response = await client.get(
        url,
        headers: {
          'User-Agent': 'BashirAgroApp/1.0 (info@bashiragro.com)',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final address = data['address'] as Map<String, dynamic>?;
          if (address != null) {
            final road = address['road'] ?? address['neighbourhood'];
            final sub = address['suburb'] ?? address['quarter'] ?? address['village'] ?? address['residential'];
            final city = address['city'] ?? address['town'] ?? address['county'] ?? address['state_district'] ?? address['district'];

            final parts = <String>[];
            if (sub != null && sub.toString().trim().isNotEmpty) {
              parts.add(sub.toString().trim());
            } else if (road != null && road.toString().trim().isNotEmpty) {
              parts.add(road.toString().trim());
            }
            if (city != null && city.toString().trim().isNotEmpty) {
              parts.add(city.toString().trim());
            }
            if (parts.isNotEmpty) {
              geocodedName = parts.join(', ');
            }
          }

          if (geocodedName == null || geocodedName.isEmpty) {
            final displayName = data['display_name']?.toString();
            if (displayName != null && displayName.isNotEmpty) {
              final tokens = displayName.split(',');
              if (tokens.length >= 2) {
                geocodedName = '${tokens[0].trim()}, ${tokens[1].trim()}';
              } else {
                geocodedName = tokens[0].trim();
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Reverse geocoding error or timeout: $e');
    }

    // Step 3: Fallback coordinates if reverse geocoding failed or offline
    final latBn = DateFormatter.toBanglaDigits(latitude.toStringAsFixed(4));
    final lngBn = DateFormatter.toBanglaDigits(longitude.toStringAsFixed(4));
    final fallbackCoords = 'জিপিএস: $latBn° N, $lngBn° E';

    return ResolvedLocation(
      displayName: (geocodedName != null && geocodedName.isNotEmpty) ? geocodedName : fallbackCoords,
      badgeText: 'জিপিএস অবস্থান',
      isInsideFarm: false,
      farmLocationId: null,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
    );
  }
}
