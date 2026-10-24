import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../core/config/mapbox_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/field_boundary_model.dart';
import '../../models/task_assignment_model.dart';

/// Satellite Map widget for Completed Task Details showing:
/// 1. Authoritative field polygon boundary.
/// 2. Photo markers:
///    - Green 🟢 pins for photos captured inside the boundary.
///    - Red 🔴 pins for photos captured outside the boundary.
/// 3. Status legend (সবুজ: এলাকার ভিতরে • লাল: এলাকার বাইরে).
/// 4. Warning banner if any photo was taken outside the boundary.
class CompletedTaskMapWidget extends StatefulWidget {
  final FieldBoundaryModel boundary;
  final String farmName;
  final String locationCode;
  final double? targetLat;
  final double? targetLng;
  final List<SubmittedPhotoDetail> photos;
  final VoidCallback? onOpenFullMap;
  final void Function(SubmittedPhotoDetail photo, int index)? onPhotoTap;

  const CompletedTaskMapWidget({
    super.key,
    required this.boundary,
    this.farmName = 'মাঠ',
    this.locationCode = 'LOC-001',
    this.targetLat,
    this.targetLng,
    this.photos = const [],
    this.onOpenFullMap,
    this.onPhotoTap,
  });

  @override
  State<CompletedTaskMapWidget> createState() => _CompletedTaskMapWidgetState();
}

class _CompletedTaskMapWidgetState extends State<CompletedTaskMapWidget> {
  late final MapController _mapController;
  bool _isSatelliteStyle = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fitBoundary();
      }
    });
  }

  void _fitBoundary() {
    final points = _getBoundaryPoints();
    if (points.isNotEmpty) {
      try {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(40.0),
            maxZoom: 18.5,
          ),
        );
        return;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  FieldBoundaryModel get _effectiveBoundary {
    if (widget.boundary.isNotEmpty) {
      return widget.boundary;
    }
    if (widget.targetLat != null && widget.targetLng != null) {
      return FieldBoundaryModel.fromCenterAndRadius(
        widget.targetLat!,
        widget.targetLng!,
        40.0,
      );
    }
    return const FieldBoundaryModel(coordinates: []);
  }

  List<LatLng> _getBoundaryPoints() {
    return _effectiveBoundary.coordinates
        .map((c) => LatLng(c.latitude, c.longitude))
        .toList();
  }

  LatLng _getEffectiveCenter() {
    if (_effectiveBoundary.isNotEmpty) {
      final center = _effectiveBoundary.centroid;
      return LatLng(center.latitude, center.longitude);
    }
    if (widget.targetLat != null && widget.targetLng != null) {
      return LatLng(widget.targetLat!, widget.targetLng!);
    }
    for (final p in widget.photos) {
      if (p.latitude != null && p.longitude != null) {
        return LatLng(p.latitude!, p.longitude!);
      }
    }
    return const LatLng(23.7808, 90.4152); // Dhaka fallback
  }

  void _fitAllMarkers() {
    final List<LatLng> allPoints = [..._getBoundaryPoints()];
    for (final p in widget.photos) {
      if (p.latitude != null && p.longitude != null) {
        allPoints.add(LatLng(p.latitude!, p.longitude!));
      }
    }
    if (allPoints.isEmpty) return;

    try {
      if (allPoints.length == 1) {
        _mapController.move(allPoints.first, 17.5);
        return;
      }
      double minLat = 90.0, maxLat = -90.0;
      double minLng = 180.0, maxLng = -180.0;
      for (final pt in allPoints) {
        minLat = min(minLat, pt.latitude);
        maxLat = max(maxLat, pt.latitude);
        minLng = min(minLng, pt.longitude);
        maxLng = max(maxLng, pt.longitude);
      }
      final bounds = LatLngBounds(
        LatLng(minLat, minLng),
        LatLng(maxLat, maxLng),
      );
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(32),
          maxZoom: 18.5,
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBoundary = _effectiveBoundary;
    final boundaryPoints = _getBoundaryPoints();
    final centerPoint = _getEffectiveCenter();

    // Determine photo locations & boundary containment
    int outsideCount = 0;
    final List<_PhotoMarkerData> markerDataList = [];

    for (int i = 0; i < widget.photos.length; i++) {
      final photo = widget.photos[i];
      double? lat = photo.latitude ?? widget.targetLat;
      double? lng = photo.longitude ?? widget.targetLng;

      if (lat == null || lng == null) {
        lat = centerPoint.latitude;
        lng = centerPoint.longitude;
      }

      // If photo had no specific GPS, slightly offset each marker around centroid
      if (photo.latitude == null && widget.photos.length > 1) {
        final angle = (2 * pi / widget.photos.length) * i;
        lat += 0.00012 * sin(angle);
        lng += 0.00012 * cos(angle);
      }

      final bool isInside = photo.insideGeofence ??
          (effectiveBoundary.isNotEmpty
              ? effectiveBoundary.isPointInside(lat, lng, 20.0)
              : true);
      if (!isInside) {
        outsideCount++;
      }
      markerDataList.add(
        _PhotoMarkerData(
          index: i + 1,
          photo: photo.latitude == null ? photo.copyWith(latitude: lat, longitude: lng) : photo,
          point: LatLng(lat, lng),
          isInside: isInside,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.layers_rounded,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'মাঠের বহুভুজ সীমানা ও ছবির অবস্থান',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${widget.farmName} (${widget.locationCode})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Map style toggle button
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: _isSatelliteStyle ? 'সাধারণ ম্যাপ' : 'স্যাটেলাইট ভিউ',
                icon: Icon(
                  _isSatelliteStyle ? Icons.satellite_alt_rounded : Icons.map_rounded,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                onPressed: () => setState(() => _isSatelliteStyle = !_isSatelliteStyle),
              ),
              // Fullscreen map button
              if (widget.onOpenFullMap != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'পূর্ণ ম্যাপ দেখুন',
                  icon: const Icon(
                    Icons.open_in_full_rounded,
                    color: AppColors.primaryGreen,
                    size: 20,
                  ),
                  onPressed: widget.onOpenFullMap,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Map Container
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 240,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: centerPoint,
                      initialZoom: 16.5,
                      minZoom: 3.0,
                      maxZoom: 21.0,
                      onTap: (tapPosition, point) {
                        if (widget.onOpenFullMap != null) {
                          widget.onOpenFullMap!();
                        }
                      },
                    ),
                    children: [
                      // Satellite / Street Tile Layer
                      TileLayer(
                        urlTemplate: _isSatelliteStyle
                            ? MapboxConfig.getSatelliteTileUrl()
                            : MapboxConfig.getStreetTileUrl(),
                        subdomains: _isSatelliteStyle
                            ? MapboxConfig.getSatelliteSubdomains()
                            : MapboxConfig.getStreetSubdomains(),
                        userAgentPackageName: 'com.itqanconsulting.farmtrack',
                        maxZoom: 21,
                        maxNativeZoom: _isSatelliteStyle ? 20 : 19,
                      ),

                      // Authoritative Field Boundary Polygon
                      if (boundaryPoints.length >= 3)
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: boundaryPoints,
                              color: const Color(0x5200E676), // 32% translucent neon emerald
                              borderColor: const Color(0xFF00E676), // Glowing neon green border
                              borderStrokeWidth: 3.2,
                            ),
                          ],
                        ),

                      // Markers Layer: Farm Badge, Boundary Vertices, and Photo Pins
                      MarkerLayer(
                        markers: [
                          // Central Farm Name Pill Badge (Image 2 style)
                          Marker(
                            point: centerPoint,
                            width: 140,
                            height: 38,
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF00E676), width: 1.4),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.eco_rounded, color: Color(0xFF00E676), size: 14),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      widget.farmName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Boundary Corner Vertex Pins (Image 2 style)
                          ...boundaryPoints.map(
                            (pt) => Marker(
                              point: pt,
                              width: 16,
                              height: 16,
                              alignment: Alignment.center,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF00E676), width: 3.0),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Submitted Photo pins
                          ...markerDataList.map((m) {
                            final pinColor = m.isInside
                                ? const Color(0xFF16A34A) // Green 🟢
                                : const Color(0xFFDC2626); // Red 🔴

                            return Marker(
                              point: m.point,
                              width: 36,
                              height: 42,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () {
                                  if (widget.onPhotoTap != null) {
                                    widget.onPhotoTap!(m.photo, m.index - 1);
                                  } else if (widget.onOpenFullMap != null) {
                                    widget.onOpenFullMap!();
                                  }
                                },
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: pinColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        DateFormatter.toBanglaDigits(m.index),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    // Pointer triangle
                                    CustomPaint(
                                      size: const Size(8, 5),
                                      painter: _PinTrianglePainter(color: pinColor),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),

                  // Tap to enlarge hint badge
                  if (widget.onOpenFullMap != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: GestureDetector(
                        onTap: widget.onOpenFullMap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 1),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.open_in_full_rounded, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'পূর্ণ ম্যাপে দেখতে ট্যাপ করুন',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Fit Bounds Quick Control
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.crop_free_rounded, color: Colors.white, size: 20),
                        tooltip: 'সব পিন একসাথে দেখুন',
                        onPressed: _fitAllMarkers,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Map Legend Row (Wrap avoids overflow on narrow screens)
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 4,
              children: [
                // Inside Legend
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'সবুজ: এলাকার ভিতরে',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
                const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                // Outside Legend
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'লাল: এলাকার বাইরে',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Outside Geofence Warning Box (if any photos outside)
          if (outsideCount > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${DateFormatter.toBanglaDigits(outsideCount)}টি ছবি নির্ধারিত এলাকার বাইরে তোলা হয়েছে',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                  if (widget.onOpenFullMap != null)
                    InkWell(
                      onTap: widget.onOpenFullMap,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ম্যাপে দেখুন',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_outward_rounded,
                              size: 14,
                              color: Color(0xFFDC2626),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PhotoMarkerData {
  final int index;
  final SubmittedPhotoDetail photo;
  final LatLng point;
  final bool isInside;

  _PhotoMarkerData({
    required this.index,
    required this.photo,
    required this.point,
    required this.isInside,
  });
}

class _PinTrianglePainter extends CustomPainter {
  final Color color;
  _PinTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
