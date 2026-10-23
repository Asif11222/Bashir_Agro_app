import 'dart:math';

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      double.tryParse((json['latitude'] ?? json['lat'])?.toString() ?? '0') ?? 0.0,
      double.tryParse((json['longitude'] ?? json['lng'])?.toString() ?? '0') ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          (latitude - other.latitude).abs() < 1e-7 &&
          (longitude - other.longitude).abs() < 1e-7;

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

class FarmLocationModel {
  final String id;
  final String ownerId;
  final String propertyId;
  final String name;
  final String type;
  final String address;
  final List<GeoPoint> polygonPoints;
  final double toleranceMeters;

  const FarmLocationModel({
    required this.id,
    required this.ownerId,
    required this.propertyId,
    required this.name,
    required this.type,
    required this.address,
    required this.polygonPoints,
    this.toleranceMeters = 20.0,
  });

  bool get hasPolygon => polygonPoints.length >= 3;

  double get centroidLat {
    if (polygonPoints.isEmpty) return 23.7808;
    return polygonPoints.map((p) => p.latitude).reduce((a, b) => a + b) / polygonPoints.length;
  }

  double get centroidLng {
    if (polygonPoints.isEmpty) return 90.4152;
    return polygonPoints.map((p) => p.longitude).reduce((a, b) => a + b) / polygonPoints.length;
  }

  /// Ray-casting point-in-polygon verification
  bool containsPoint(double lat, double lng) {
    if (polygonPoints.length < 3) return false;
    bool inside = false;
    final n = polygonPoints.length;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = polygonPoints[i].latitude;
      final yi = polygonPoints[i].longitude;
      final xj = polygonPoints[j].latitude;
      final yj = polygonPoints[j].longitude;

      final intersect = ((yi > lng) != (yj > lng)) &&
          (lat < (xj - xi) * (lng - yi) / (yj - yi) + xi);
      if (intersect) inside = !inside;
    }

    if (inside) return true;

    // Check with tolerance
    if (toleranceMeters > 0) {
      final dist = distanceToBoundaryMeters(lat, lng);
      if (dist <= toleranceMeters) return true;
    }

    return false;
  }

  /// Calculates shortest distance in meters to boundary
  double distanceToBoundaryMeters(double lat, double lng) {
    if (polygonPoints.isEmpty) return double.infinity;
    double minDistance = double.infinity;
    final n = polygonPoints.length;
    for (int i = 0; i < n; i++) {
      final p1 = polygonPoints[i];
      final p2 = polygonPoints[(i + 1) % n];

      final dist = _pointToSegmentDistance(lat, lng, p1.latitude, p1.longitude, p2.latitude, p2.longitude);
      if (dist < minDistance) minDistance = dist;
    }
    return minDistance;
  }

  static double _pointToSegmentDistance(
    double pLat, double pLon,
    double aLat, double aLon,
    double bLat, double bLon,
  ) {
    const double r = 6371000.0;
    final double abLat = bLat - aLat;
    final double abLon = bLon - aLon;
    final double apLat = pLat - aLat;
    final double apLon = pLon - aLon;

    final double abLenSq = abLat * abLat + abLon * abLon;
    if (abLenSq == 0) {
      final dLat = (aLat - pLat) * pi / 180.0;
      final dLon = (aLon - pLon) * pi / 180.0;
      final a = sin(dLat / 2) * sin(dLat / 2) +
          cos(pLat * pi / 180.0) * cos(aLat * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
      return r * 2 * atan2(sqrt(a), sqrt(1 - a));
    }

    double t = (apLat * abLat + apLon * abLon) / abLenSq;
    t = t.clamp(0.0, 1.0);

    final closestLat = aLat + t * abLat;
    final closestLon = aLon + t * abLon;

    final dLat = (closestLat - pLat) * pi / 180.0;
    final dLon = (closestLon - pLon) * pi / 180.0;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(pLat * pi / 180.0) * cos(closestLat * pi / 180.0) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
