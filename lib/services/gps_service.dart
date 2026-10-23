import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class GpsCoordinate {
  final double latitude;
  final double longitude;
  final double accuracy; // meters
  final DateTime? timestamp;
  final double? heading;
  final double? speed;

  const GpsCoordinate({
    required this.latitude,
    required this.longitude,
    this.accuracy = 5.0,
    this.timestamp,
    this.heading,
    this.speed,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    if (heading != null) 'heading': heading,
    if (speed != null) 'speed': speed,
  };
}

class GpsService {
  static final GpsService _instance = GpsService._();
  factory GpsService() => _instance;
  GpsService._();

  // Known field locations for simulation/testing
  static const GpsCoordinate southFieldInside = GpsCoordinate(
    latitude: 23.7808,
    longitude: 90.4152,
    accuracy: 4.5,
  );

  static const GpsCoordinate outsideGeofence = GpsCoordinate(
    latitude: 23.8500,
    longitude: 90.4800,
    accuracy: 12.0,
  );

  bool _simulationMode = false;
  bool _simulateInside = true;

  bool get simulationMode => _simulationMode;
  bool get simulateInside => _simulateInside;

  void setSimulationMode(bool enabled, [bool inside = true]) {
    _simulationMode = enabled;
    _simulateInside = inside;
  }

  /// Check if location services (GPS hardware switch) are enabled on the phone
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Check current location permission status
  Future<LocationPermission> checkPermission() async {
    try {
      return await Geolocator.checkPermission();
    } catch (_) {
      return LocationPermission.denied;
    }
  }

  /// Open device location settings so user can turn on GPS
  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  /// Open app settings if permission is denied forever
  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Request location permissions if needed
  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('GpsService permission check error: $e');
      return false;
    }
  }

  /// Get current GPS location (Latitude, Longitude, Accuracy)
  /// Returns null if hardware GPS cannot be obtained and fallbackToTarget is false.
  Future<GpsCoordinate?> getCurrentLocation({
    double? targetLatitude,
    double? targetLongitude,
    bool forceHardware = false,
    bool fallbackToTarget = false,
  }) async {
    // If simulation mode is active and hardware is not forced
    if (_simulationMode && !forceHardware) {
      if (_simulateInside) {
        final lat = targetLatitude ?? 23.7808;
        final lng = targetLongitude ?? 90.4152;
        return GpsCoordinate(
          latitude: lat,
          longitude: lng,
          accuracy: 4.2,
          timestamp: DateTime.now(),
        );
      } else {
        return GpsCoordinate(
          latitude: 23.8500,
          longitude: 90.4800,
          accuracy: 15.0,
          timestamp: DateTime.now(),
        );
      }
    }

    // Try hardware device GPS
    try {
      final hasPerm = await requestPermission();
      if (hasPerm) {
        // Fast fix from last known position if available
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          // If fresh enough (within 30 seconds), can return or use while fetching current
          final age = DateTime.now().difference(lastKnown.timestamp);
          if (age.inSeconds < 30) {
            return GpsCoordinate(
              latitude: lastKnown.latitude,
              longitude: lastKnown.longitude,
              accuracy: lastKnown.accuracy,
              heading: lastKnown.heading,
              speed: lastKnown.speed,
              timestamp: lastKnown.timestamp,
            );
          }
        }

        // Fetch current fresh hardware GPS fix
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        return GpsCoordinate(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          heading: pos.heading,
          speed: pos.speed,
          timestamp: pos.timestamp,
        );
      }
    } catch (e) {
      debugPrint('Hardware GPS fetch error: $e');
      // If error happened but last known position is present, return it
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return GpsCoordinate(
            latitude: lastKnown.latitude,
            longitude: lastKnown.longitude,
            accuracy: lastKnown.accuracy,
            heading: lastKnown.heading,
            speed: lastKnown.speed,
            timestamp: lastKnown.timestamp,
          );
        }
      } catch (_) {}
    }

    // Only fallback to target if explicitly requested (e.g. testing)
    if (fallbackToTarget) {
      final lat = targetLatitude ?? 23.7808;
      final lng = targetLongitude ?? 90.4152;
      return GpsCoordinate(
        latitude: lat,
        longitude: lng,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  /// Stream real-time location updates from device hardware GPS
  Stream<GpsCoordinate> getRealTimePositionStream() async* {
    final hasPerm = await requestPermission();
    if (!hasPerm) return;

    // Immediately yield last known position for instant responsiveness
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        yield GpsCoordinate(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
          accuracy: lastKnown.accuracy,
          heading: lastKnown.heading,
          speed: lastKnown.speed,
          timestamp: lastKnown.timestamp,
        );
      }
    } catch (e) {
      debugPrint('Last known position error: $e');
    }

    // Continuous real-time position stream from device hardware GPS
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Update every 2 meters
      ),
    ).map((pos) => GpsCoordinate(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          heading: pos.heading,
          speed: pos.speed,
          timestamp: pos.timestamp,
        ));
  }

  /// Calculate distance in meters between two coordinates (Haversine formula)
  double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
