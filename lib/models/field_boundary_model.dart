import 'dart:convert';
import 'dart:math';
import '../data/models/farm_location_model.dart';
export '../data/models/farm_location_model.dart' show GeoPoint;

/// Represents an authoritative agricultural field boundary polygon received
/// from the Laravel REST API (Phase 12A V2 / 12B V2).
class FieldBoundaryModel {
  final String type;
  final List<GeoPoint> coordinates;

  const FieldBoundaryModel({
    this.type = 'Polygon',
    required this.coordinates,
  });

  bool get isEmpty => coordinates.isEmpty;
  bool get isNotEmpty => coordinates.isNotEmpty;
  int get vertexCount => coordinates.length;

  /// Ensure the coordinate ring is closed
  bool get isClosed {
    if (coordinates.length < 3) return false;
    final first = coordinates.first;
    final last = coordinates.last;
    return (first.latitude - last.latitude).abs() < 1e-7 &&
        (first.longitude - last.longitude).abs() < 1e-7;
  }

  /// Generate a realistic circular/polygonal field boundary around a center coordinate
  factory FieldBoundaryModel.fromCenterAndRadius(
    double centerLat,
    double centerLng, [
    double radiusMeters = 40.0,
    int pointsCount = 6,
  ]) {
    final points = <GeoPoint>[];
    const double dLatPerMeter = 1.0 / 111320.0;
    final double dLngPerMeter = 1.0 / (111320.0 * max(0.1, cos(centerLat * pi / 180.0)));

    for (int i = 0; i < pointsCount; i++) {
      final angle = 2.0 * pi * (i / pointsCount);
      final r = radiusMeters * (0.92 + 0.12 * sin(2 * angle));
      final pLat = centerLat + (r * sin(angle) * dLatPerMeter);
      final pLng = centerLng + (r * cos(angle) * dLngPerMeter);
      points.add(GeoPoint(pLat, pLng));
    }
    if (points.isNotEmpty) {
      points.add(points.first);
    }

    return FieldBoundaryModel(
      type: 'Polygon',
      coordinates: points,
    );
  }

  /// Calculates geographic center / centroid of the boundary polygon
  GeoPoint get centroid {
    if (coordinates.isEmpty) {
      return const GeoPoint(24.7471, 90.4203);
    }
    double sumLat = 0.0;
    double sumLng = 0.0;
    final count = coordinates.length;
    for (final pt in coordinates) {
      sumLat += pt.latitude;
      sumLng += pt.longitude;
    }
    return GeoPoint(sumLat / count, sumLng / count);
  }

  /// Calculates bounding box: [minLat, maxLat, minLng, maxLng]
  Map<String, double> get boundingBox {
    if (coordinates.isEmpty) {
      return {
        'minLat': 24.7460,
        'maxLat': 24.7480,
        'minLng': 90.4190,
        'maxLng': 90.4210,
      };
    }
    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (final pt in coordinates) {
      if (pt.latitude < minLat) minLat = pt.latitude;
      if (pt.latitude > maxLat) maxLat = pt.latitude;
      if (pt.longitude < minLng) minLng = pt.longitude;
      if (pt.longitude > maxLng) maxLng = pt.longitude;
    }

    return {
      'minLat': minLat,
      'maxLat': maxLat,
      'minLng': minLng,
      'maxLng': maxLng,
    };
  }

  /// Parse GeoJSON Polygon structure:
  /// { "type": "Polygon", "coordinates": [[[lon, lat], [lon, lat], ...]] }
  factory FieldBoundaryModel.fromGeoJson(dynamic geoJson) {
    if (geoJson == null) {
      return const FieldBoundaryModel(coordinates: []);
    }

    dynamic data = geoJson;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return const FieldBoundaryModel(coordinates: []);
      }
    }

    if (data is! Map) {
      return const FieldBoundaryModel(coordinates: []);
    }

    // Unwrap GeoJSON Feature if present
    if (data['type'] == 'Feature' && data['geometry'] is Map) {
      data = data['geometry'];
    }

    final String type = data['type']?.toString() ?? 'Polygon';
    final rawCoords = data['coordinates'];

    if (rawCoords is! List || rawCoords.isEmpty) {
      return FieldBoundaryModel(type: type, coordinates: []);
    }

    // Standard GeoJSON Polygon coordinates are wrapped in a ring list: [[[lon, lat], ...]]
    final ring = rawCoords[0] is List ? rawCoords[0] as List : rawCoords;
    final points = <GeoPoint>[];

    for (final item in ring) {
      if (item is List && item.length >= 2) {
        final lng = double.tryParse(item[0].toString()) ?? 0.0;
        final lat = double.tryParse(item[1].toString()) ?? 0.0;
        points.add(GeoPoint(lat, lng));
      } else if (item is Map) {
        final lat = double.tryParse((item['latitude'] ?? item['lat'])?.toString() ?? '') ?? 0.0;
        final lng = double.tryParse((item['longitude'] ?? item['lng'])?.toString() ?? '') ?? 0.0;
        points.add(GeoPoint(lat, lng));
      }
    }

    return FieldBoundaryModel(
      type: type,
      coordinates: points,
    );
  }

  /// Convert back to GeoJSON Polygon format
  Map<String, dynamic> toGeoJson() {
    return {
      'type': 'Polygon',
      'coordinates': [
        coordinates.map((p) => [p.longitude, p.latitude]).toList(),
      ],
    };
  }

  /// Check whether a GPS point is inside this polygon boundary (Ray-Casting algorithm)
  bool isPointInside(double latitude, double longitude, [double toleranceMeters = 0.0]) {
    if (coordinates.length < 3) return false;

    // Direct ray-casting test
    bool inside = false;
    final n = coordinates.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = coordinates[i].latitude;
      final yi = coordinates[i].longitude;
      final xj = coordinates[j].latitude;
      final yj = coordinates[j].longitude;

      final intersect = ((yi > longitude) != (yj > longitude)) &&
          (latitude < (xj - xi) * (longitude - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }

    if (inside) return true;

    // If tolerance buffer is specified, check distance to closest boundary segment
    if (toleranceMeters > 0) {
      final dist = distanceToBoundaryMeters(latitude, longitude);
      if (dist <= toleranceMeters) return true;
    }

    return false;
  }

  /// Calculate distance in meters from given point to the nearest polygon edge
  double distanceToBoundaryMeters(double latitude, double longitude) {
    if (coordinates.isEmpty) return double.infinity;
    if (coordinates.length == 1) {
      return _haversineDistance(latitude, longitude, coordinates.first.latitude, coordinates.first.longitude);
    }

    double minDistance = double.infinity;
    final n = coordinates.length;

    for (int i = 0; i < n; i++) {
      final p1 = coordinates[i];
      final p2 = coordinates[(i + 1) % n];

      final dist = _pointToSegmentDistanceMeters(latitude, longitude, p1.latitude, p1.longitude, p2.latitude, p2.longitude);
      if (dist < minDistance) {
        minDistance = dist;
      }
    }

    return minDistance;
  }

  /// Approximate polygon area in acres using spherical polygon formula
  double calculateAreaAcres() {
    if (coordinates.length < 3) return 0.0;
    const double earthRadius = 6378137.0; // meters
    double area = 0.0;
    final n = coordinates.length;

    for (int i = 0; i < n; i++) {
      final p1 = coordinates[i];
      final p2 = coordinates[(i + 1) % n];

      final lat1 = p1.latitude * pi / 180.0;
      final lat2 = p2.latitude * pi / 180.0;
      final dLng = (p2.longitude - p1.longitude) * pi / 180.0;

      area += (dLng) * (2.0 + sin(lat1) + sin(lat2));
    }

    area = (area * earthRadius * earthRadius / 4.0).abs();
    // 1 Acre = 4046.8564224 square meters
    return area / 4046.8564224;
  }

  // --- Helpers for Distance Calculations ---
  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double r = 6371000.0; // Earth radius in meters
    final dLat = (lat2 - lat1) * pi / 180.0;
    final dLon = (lon2 - lon1) * pi / 180.0;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _pointToSegmentDistanceMeters(
    double pLat, double pLon,
    double aLat, double aLon,
    double bLat, double bLon,
  ) {
    // Project P onto line segment AB
    final double abLat = bLat - aLat;
    final double abLon = bLon - aLon;
    final double apLat = pLat - aLat;
    final double apLon = pLon - aLon;

    final double abLenSq = abLat * abLat + abLon * abLon;
    if (abLenSq == 0) {
      return _haversineDistance(pLat, pLon, aLat, aLon);
    }

    // Projection scalar t
    double t = (apLat * abLat + apLon * abLon) / abLenSq;
    t = t.clamp(0.0, 1.0);

    final double closestLat = aLat + t * abLat;
    final double closestLon = aLon + t * abLon;

    return _haversineDistance(pLat, pLon, closestLat, closestLon);
  }
}
