import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/config/mapbox_config.dart';
import '../../models/field_boundary_model.dart';

/// High-fidelity interactive Mapbox / Satellite Tile Map Widget for Bashir Agro.
/// Renders:
/// 1. Real geographic Satellite imagery (Mapbox / Google Hybrid) & OpenStreetMap Street layer.
/// 2. Authoritative PostGIS agricultural polygon boundary overlay.
/// 3. Boundary vertex corner pins.
/// 4. Farm centroid pin with name callout.
/// 5. Farmer real-time GPS location with animated radar pulse and accuracy wave.
/// 6. Live status pill indicator (Inside Geofence vs Distance to Boundary).
/// 7. Interactive map controls (Zoom +, Zoom -, Fit Boundary, Center My Location, Satellite Toggle).
class FieldBoundaryMapWidget extends StatefulWidget {
  final FieldBoundaryModel boundary;
  final String farmName;
  final String locationCode;
  final String farmType;
  final String formattedArea;
  final double? farmerLat;
  final double? farmerLng;
  final double? targetLat;
  final double? targetLng;
  final double gpsAccuracy;
  final bool isInteractive;
  final double height;
  final VoidCallback? onNavigate;

  const FieldBoundaryMapWidget({
    super.key,
    required this.boundary,
    this.farmName = 'কৃষি জমি',
    this.locationCode = 'LOC-001',
    this.farmType = 'সবজি ক্ষেত',
    this.formattedArea = '',
    this.farmerLat,
    this.farmerLng,
    this.targetLat,
    this.targetLng,
    this.gpsAccuracy = 4.5,
    this.isInteractive = true,
    this.height = 360,
    this.onNavigate,
  });

  @override
  State<FieldBoundaryMapWidget> createState() => _FieldBoundaryMapWidgetState();
}

class _FieldBoundaryMapWidgetState extends State<FieldBoundaryMapWidget>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isSatelliteStyle = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    try {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(_mapController.camera.center, (currentZoom + 1.0).clamp(3.0, 21.0));
    } catch (_) {}
  }

  void _zoomOut() {
    try {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(_mapController.camera.center, (currentZoom - 1.0).clamp(3.0, 21.0));
    } catch (_) {}
  }

  void _fitBoundary() {
    try {
      final points = _getBoundaryPoints();
      if (points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(points);
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(48.0),
            maxZoom: 18.5,
          ),
        );
      } else {
        final center = _getEffectiveCenter();
        _mapController.move(center, 16.5);
      }
    } catch (_) {}
  }

  void _focusFarmer() {
    if (widget.farmerLat != null && widget.farmerLng != null) {
      try {
        _mapController.move(LatLng(widget.farmerLat!, widget.farmerLng!), 17.5);
      } catch (_) {}
    } else {
      try {
        _mapController.move(_getEffectiveCenter(), 16.5);
      } catch (_) {}
    }
  }

  LatLng _getEffectiveCenter() {
    if (widget.boundary.isNotEmpty) {
      return LatLng(widget.boundary.centroid.latitude, widget.boundary.centroid.longitude);
    }
    final lat = widget.targetLat ?? 24.7471;
    final lng = widget.targetLng ?? 90.4203;
    return LatLng(lat, lng);
  }

  List<LatLng> _getBoundaryPoints() {
    final effectiveBoundary = widget.boundary.isNotEmpty
        ? widget.boundary
        : (widget.targetLat != null && widget.targetLng != null
            ? FieldBoundaryModel.fromCenterAndRadius(
                widget.targetLat!,
                widget.targetLng!,
                40.0,
              )
            : const FieldBoundaryModel(coordinates: []));

    return effectiveBoundary.coordinates
        .map((coord) => LatLng(coord.latitude, coord.longitude))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFarmerLocation = widget.farmerLat != null && widget.farmerLng != null;
    final fLat = widget.farmerLat;
    final fLng = widget.farmerLng;

    final effectiveBoundary = widget.boundary.isNotEmpty
        ? widget.boundary
        : (widget.targetLat != null && widget.targetLng != null
            ? FieldBoundaryModel.fromCenterAndRadius(widget.targetLat!, widget.targetLng!, 40.0)
            : const FieldBoundaryModel(coordinates: []));

    final bool isInside = hasFarmerLocation && effectiveBoundary.isNotEmpty
        ? effectiveBoundary.isPointInside(fLat!, fLng!, 20.0)
        : false;
    final double distanceToField = hasFarmerLocation && effectiveBoundary.isNotEmpty
        ? effectiveBoundary.distanceToBoundaryMeters(fLat!, fLng!)
        : 0.0;
    final boundaryPoints = _getBoundaryPoints();
    final centerPoint = _getEffectiveCenter();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: widget.height,
        color: _isSatelliteStyle ? const Color(0xFF0F1B15) : const Color(0xFFE2E8F0),
        child: Stack(
          children: [
            // 1. Real Interactive Mapbox / Satellite Tile Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: centerPoint,
                initialZoom: 16.8,
                minZoom: 3.0,
                maxZoom: 21.0,
                interactionOptions: InteractionOptions(
                  flags: widget.isInteractive
                      ? InteractiveFlag.all
                      : InteractiveFlag.none,
                ),
              ),
              children: [
                // Satellite / Street Raster Tile Layer
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
                  tileBuilder: (context, tileWidget, tile) {
                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 250),
                      child: tileWidget,
                    );
                  },
                ),

                // Authoritative PostGIS Field Boundary Polygon Layer
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

                // Markers Layer: Farm Centroid, Boundary Vertices, and Farmer Live GPS Marker
                MarkerLayer(
                  markers: [
                    // Farm Center Label Marker (when interactive)
                    if (widget.isInteractive)
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

                    // Boundary Corner Vertex Pins
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

                    // Farmer Real-time Location Marker with Pulsing Radar Effect
                    if (hasFarmerLocation)
                      Marker(
                        point: LatLng(fLat!, fLng!),
                        width: 190,
                      height: 110,
                      alignment: Alignment.center,
                      child: AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) {
                          final pulse = _pulseAnimation.value;
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Radar pulse circle stack
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Outer Expanding Pulse Wave
                                    Transform.scale(
                                      scale: 1.0 + (pulse * 1.4),
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF00E5FF)
                                              .withValues(alpha: max(0.0, 0.45 * (1.0 - pulse))),
                                        ),
                                      ),
                                    ),
                                    // Middle Accuracy Glow Ring
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0x3300E5FF),
                                        border: Border.all(
                                          color: const Color(0xFF00E5FF).withValues(alpha: 0.6),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    // Core Bright GPS Dot
                                    Container(
                                      width: 15,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF00E5FF),
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x8000E5FF),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              // "আমার অবস্থান (You)" Label Tag
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF00E5FF), width: 1.0),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isInside ? const Color(0xFF00E676) : Colors.redAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'আমার অবস্থান (You)',
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
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 2. Top Geofence Status Bar: Inside / Outside Field Pill Badge
            Positioned(
              top: 12,
              left: 12,
              right: widget.isInteractive ? 64 : 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: !hasFarmerLocation
                      ? const Color(0xE6E65100)
                      : isInside
                          ? const Color(0xE6087A45)
                          : const Color(0xE6C62828),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      !hasFarmerLocation
                          ? Icons.gps_not_fixed_rounded
                          : isInside
                              ? Icons.verified_rounded
                              : Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        !hasFarmerLocation
                            ? 'জিপিএস অবস্থান নেওয়া হচ্ছে...'
                            : isInside
                                ? 'সীমানার ভেতরে (Inside Boundary)'
                                : 'সীমানা থেকে ${distanceToField >= 1000 ? '${(distanceToField / 1000).toStringAsFixed(1)} কিমি' : '${distanceToField.toStringAsFixed(0)} মি.'} দূরে (Outside)',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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

            // 3. Right Floating Map Toolbar
            if (widget.isInteractive)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    _buildMapIconButton(
                      icon: _isSatelliteStyle ? Icons.map_rounded : Icons.satellite_alt_rounded,
                      tooltip: _isSatelliteStyle ? 'ম্যাপ ভিউ' : 'স্যাটেলাইট ভিউ',
                      onTap: () {
                        setState(() => _isSatelliteStyle = !_isSatelliteStyle);
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildMapIconButton(
                      icon: Icons.add_rounded,
                      tooltip: 'জুম ইন',
                      onTap: _zoomIn,
                    ),
                    const SizedBox(height: 6),
                    _buildMapIconButton(
                      icon: Icons.remove_rounded,
                      tooltip: 'জুম আউট',
                      onTap: _zoomOut,
                    ),
                    const SizedBox(height: 6),
                    _buildMapIconButton(
                      icon: Icons.crop_free_rounded,
                      tooltip: 'সম্পূর্ণ প্লট দেখুন',
                      onTap: _fitBoundary,
                    ),
                    const SizedBox(height: 6),
                    _buildMapIconButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'আমার অবস্থান',
                      iconColor: const Color(0xFF00E5FF),
                      onTap: _focusFarmer,
                    ),
                  ],
                ),
              ),

            // 4. Bottom Area & Vertex Counter Chip
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.polyline_rounded, color: Color(0xFF00E676), size: 14),
                    const SizedBox(width: 5),
                    Text(
                      'বহুভুজ সীমানা: ${effectiveBoundary.vertexCount} বিন্দু',
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w500),
                    ),
                    if (widget.formattedArea.isNotEmpty) ...[
                      const Text(' • ', style: TextStyle(color: Colors.white54)),
                      Text(
                        widget.formattedArea,
                        style: const TextStyle(color: Color(0xFF81C784), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 0.8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: iconColor),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }
}
