import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/config/mapbox_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/field_boundary_model.dart';
import '../../../models/task_assignment_model.dart';
import '../../widgets/submitted_photos_grid.dart';

/// Fullscreen Interactive Satellite Map Screen for Completed Tasks showing:
/// 1. Interactive Satellite Map with Mapbox/Google Hybrid Satellite tiles.
/// 2. PostGIS agricultural field polygon boundary (neon green outline + translucent fill).
/// 3. Farm centroid marker.
/// 4. All submitted photos pinned:
///    - Green 🟢 pins for photos inside the field boundary.
///    - Red 🔴 pins for photos outside the field boundary.
/// 5. Tap pin to reveal interactive photo preview callout.
/// 6. Bottom photo selector carousel to quickly fly to any photo's pin.
/// 7. Fit all bounds & satellite/street style toggle.
class CompletedTaskFullMapScreen extends StatefulWidget {
  final FieldBoundaryModel boundary;
  final String farmName;
  final String locationCode;
  final double? targetLat;
  final double? targetLng;
  final List<SubmittedPhotoDetail> photos;
  final bool taskIsLate;
  final int? initialPhotoIndex;

  const CompletedTaskFullMapScreen({
    super.key,
    required this.boundary,
    this.farmName = 'মাঠ',
    this.locationCode = 'LOC-001',
    this.targetLat,
    this.targetLng,
    this.photos = const [],
    this.taskIsLate = false,
    this.initialPhotoIndex,
  });

  @override
  State<CompletedTaskFullMapScreen> createState() => _CompletedTaskFullMapScreenState();
}

class _CompletedTaskFullMapScreenState extends State<CompletedTaskFullMapScreen> {
  late final MapController _mapController;
  bool _isSatelliteStyle = true;
  int? _selectedPhotoIndex;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialPhotoIndex != null &&
        widget.initialPhotoIndex! >= 0 &&
        widget.initialPhotoIndex! < widget.photos.length) {
      _selectedPhotoIndex = widget.initialPhotoIndex;
    } else if (widget.photos.isNotEmpty) {
      _selectedPhotoIndex = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final markers = _computeMarkers();
      if (widget.initialPhotoIndex != null &&
          widget.initialPhotoIndex! >= 0 &&
          widget.initialPhotoIndex! < markers.length) {
        _mapController.move(markers[widget.initialPhotoIndex!].point, 18.0);
      } else if (markers.isNotEmpty || _getBoundaryPoints().isNotEmpty) {
        _fitAllPins(markers);
      }
    });
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
    return const LatLng(23.7808, 90.4152);
  }

  List<_FullPhotoMarker> _computeMarkers() {
    final effectiveBoundary = _effectiveBoundary;
    final List<_FullPhotoMarker> markers = [];
    final fallbackCenter = _getEffectiveCenter();

    for (int i = 0; i < widget.photos.length; i++) {
      final photo = widget.photos[i];
      double? lat = photo.latitude ?? widget.targetLat;
      double? lng = photo.longitude ?? widget.targetLng;

      if (lat == null || lng == null) {
        lat = fallbackCenter.latitude;
        lng = fallbackCenter.longitude;
      }

      // If photo had no specific GPS, slightly offset each marker around centroid
      if (photo.latitude == null && widget.photos.length > 1) {
        final angle = (2 * pi / widget.photos.length) * i;
        lat += 0.00015 * sin(angle);
        lng += 0.00015 * cos(angle);
      }

      final bool isInside = photo.insideGeofence ??
          (effectiveBoundary.isNotEmpty
              ? effectiveBoundary.isPointInside(lat, lng, 20.0)
              : true);

      markers.add(
        _FullPhotoMarker(
          index: i + 1,
          photo: photo.latitude == null ? photo.copyWith(latitude: lat, longitude: lng) : photo,
          point: LatLng(lat, lng),
          isInside: isInside,
        ),
      );
    }
    return markers;
  }

  void _fitAllPins(List<_FullPhotoMarker> markers) {
    final List<LatLng> allPoints = [..._getBoundaryPoints()];
    for (final m in markers) {
      allPoints.add(m.point);
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
          padding: const EdgeInsets.only(top: 40, left: 32, right: 32, bottom: 180),
          maxZoom: 18.5,
        ),
      );
    } catch (_) {}
  }

  void _flyToMarker(_FullPhotoMarker marker, int index) {
    setState(() => _selectedPhotoIndex = index);
    try {
      _mapController.move(marker.point, 18.0);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final boundaryPoints = _getBoundaryPoints();
    final centerPoint = _getEffectiveCenter();
    final markers = _computeMarkers();

    final insideCount = markers.where((m) => m.isInside).length;
    final outsideCount = markers.where((m) => !m.isInside).length;

    _FullPhotoMarker? selectedMarker;
    if (_selectedPhotoIndex != null && _selectedPhotoIndex! < markers.length) {
      selectedMarker = markers[_selectedPhotoIndex!];
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ছবির অবস্থান ও মাঠ সীমানা',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              '${widget.farmName} (${widget.locationCode})',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isSatelliteStyle ? 'সাধারণ ম্যাপ' : 'স্যাটেলাইট ভিউ',
            icon: Icon(
              _isSatelliteStyle ? Icons.satellite_alt_rounded : Icons.map_rounded,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isSatelliteStyle = !_isSatelliteStyle),
          ),
          IconButton(
            tooltip: 'সব পিন একসাথে দেখুন',
            icon: const Icon(Icons.crop_free_rounded, color: Colors.white),
            onPressed: () => _fitAllPins(markers),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Fullscreen Interactive Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerPoint,
              initialZoom: 16.8,
              minZoom: 3.0,
              maxZoom: 21.0,
            ),
            children: [
              // Satellite / Street Raster Tiles
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

              // Authoritative Field Polygon Boundary
              if (boundaryPoints.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: boundaryPoints,
                      color: const Color(0x5200E676), // 32% translucent emerald
                      borderColor: const Color(0xFF00E676), // Glowing neon green border
                      borderStrokeWidth: 3.5,
                    ),
                  ],
                ),

              // Pins Layer
              MarkerLayer(
                markers: [
                  // Central Farm Name Pill Badge
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

                  // Photo Markers
                  ...markers.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final m = entry.value;
                    final isSelected = _selectedPhotoIndex == idx;
                    final pinColor = m.isInside
                        ? const Color(0xFF16A34A) // Green 🟢
                        : const Color(0xFFDC2626); // Red 🔴

                    return Marker(
                      point: m.point,
                      width: isSelected ? 44 : 36,
                      height: isSelected ? 50 : 42,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _flyToMarker(m, idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSelected ? 6 : 4),
                                decoration: BoxDecoration(
                                  color: pinColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.yellowAccent : Colors.white,
                                    width: isSelected ? 2.5 : 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected ? pinColor.withValues(alpha: 0.6) : Colors.black38,
                                      blurRadius: isSelected ? 8 : 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  DateFormatter.toBanglaDigits(m.index),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSelected ? 12.5 : 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: Size(isSelected ? 10 : 8, isSelected ? 6 : 5),
                                painter: _TrianglePainter(color: pinColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. Selected Photo Floating Callout Card
          if (selectedMarker != null)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: _buildFloatingCallout(selectedMarker),
            ),

          // 3. Bottom Panel: Legend + Photo Carousel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(markers, insideCount, outsideCount),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingCallout(_FullPhotoMarker marker) {
    final photo = marker.photo;
    final timeStr = photo.capturedAt != null && photo.capturedAt!.isNotEmpty
        ? DateFormatter.formatDateTimeToBanglaTime(photo.capturedAt)
        : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: marker.isInside ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 52,
              height: 52,
              child: _buildThumbnailImage(photo.url),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'ছবি ${DateFormatter.toBanglaDigits(marker.index)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: marker.isInside ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        marker.isInside ? '(✓) সঠিক লোকেশনে' : '(X) লোকেশনের বাইরে',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: marker.isInside ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'তোলার সময়: $timeStr',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          // Zoom Button
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded, color: AppColors.primaryGreen, size: 26),
            tooltip: 'বড় করে দেখুন',
            onPressed: () => _openLightbox(marker.index - 1),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(List<_FullPhotoMarker> markers, int insideCount, int outsideCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -3)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Legend bar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  color: const Color(0xFF16A34A),
                  label: 'সবুজ: এলাকার ভিতরে (${DateFormatter.toBanglaDigits(insideCount)}টি)',
                ),
                const SizedBox(width: 14),
                const Text('•', style: TextStyle(color: Color(0xFF94A3B8))),
                const SizedBox(width: 14),
                _buildLegendItem(
                  color: const Color(0xFFDC2626),
                  label: 'লাল: এলাকার বাইরে (${DateFormatter.toBanglaDigits(outsideCount)}টি)',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Horizontal Photo Selector
            if (markers.isNotEmpty)
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: markers.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    final m = markers[idx];
                    final isSelected = _selectedPhotoIndex == idx;
                    final borderColor = m.isInside
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626);

                    return GestureDetector(
                      onTap: () => _flyToMarker(m, idx),
                      child: Container(
                        width: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? Colors.yellow.shade700 : borderColor,
                            width: isSelected ? 3.0 : 2.0,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: borderColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildThumbnailImage(m.photo.url),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: borderColor.withValues(alpha: 0.85),
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    'ছবি ${DateFormatter.toBanglaDigits(m.index)}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnailImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    final resolved = SubmittedPhotosGrid.resolveUrl(url);
    if (resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.photo_rounded, size: 24, color: Color(0xFF94A3B8)),
      ),
    );
  }

  void _openLightbox(int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) => PhotoLightboxDialog(
        photos: widget.photos,
        initialIndex: initialIndex,
        boundary: _effectiveBoundary,
        taskIsLate: widget.taskIsLate,
      ),
    );
  }
}

class _FullPhotoMarker {
  final int index;
  final SubmittedPhotoDetail photo;
  final LatLng point;
  final bool isInside;

  _FullPhotoMarker({
    required this.index,
    required this.photo,
    required this.point,
    required this.isInside,
  });
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

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
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
