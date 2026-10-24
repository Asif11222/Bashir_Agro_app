import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/field_boundary_model.dart';
import '../../models/task_assignment_model.dart';

/// Grid widget displaying submitted evidence photos with:
/// 1. Thumbnail with rounded corners.
/// 2. Photo number & capture time (e.g., ছবি ১ • বিকাল ৪:৪০).
/// 3. Location verification pill: (✓) সঠিক লোকেশনে / (X) লোকেশনের বাইরে.
/// 4. Time verification pill: (✓) সময়ের মধ্যে / (X) সময় পেরিয়েছে.
/// 5. Fullscreen Pinch-to-zoom Lightbox on tap.
class SubmittedPhotosGrid extends StatelessWidget {
  final List<SubmittedPhotoDetail> photos;
  final FieldBoundaryModel? boundary;
  final double? targetLat;
  final double? targetLng;
  final bool taskIsLate;

  const SubmittedPhotosGrid({
    super.key,
    required this.photos,
    this.boundary,
    this.targetLat,
    this.targetLng,
    this.taskIsLate = false,
  });

  static String resolveUrl(String raw) {
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final base = ApiConstants.baseUrl.replaceAll('/api/v1', '');
    final cleanPath = raw.startsWith('/') ? raw.substring(1) : raw;
    return '$base/$cleanPath';
  }

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox.shrink();
    }

    final effectiveBoundary = (boundary != null && boundary!.isNotEmpty)
        ? boundary!
        : (targetLat != null && targetLng != null
            ? FieldBoundaryModel.fromCenterAndRadius(targetLat!, targetLng!, 40.0)
            : const FieldBoundaryModel(coordinates: []));

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
      padding: const EdgeInsets.all(16),
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
                  Icons.photo_library_rounded,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'জমা দেওয়া ছবি (${DateFormatter.toBanglaDigits(photos.length)}টি)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Responsive Grid of Photos
          LayoutBuilder(
            builder: (context, constraints) {
              // 2 columns for phones, 3 for tablets/wide screens
              final crossAxisCount = constraints.maxWidth > 550 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: photos.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  final isInside = photo.insideGeofence ??
                      (photo.latitude != null &&
                              photo.longitude != null &&
                              effectiveBoundary.isNotEmpty
                          ? effectiveBoundary.isPointInside(
                              photo.latitude!,
                              photo.longitude!,
                              20.0,
                            )
                          : true);
                  final isPhotoLate = photo.isLate ?? taskIsLate;

                  return _PhotoCard(
                    photo: photo,
                    index: index + 1,
                    isInside: isInside,
                    isLate: isPhotoLate,
                    onTap: () => _openLightbox(context, index, effectiveBoundary),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 10),

          // Informative helper tip
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 5),
              Text(
                'ছবিতে চাপলে বড় করে ও অবস্থান দেখা যাবে',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openLightbox(
    BuildContext context,
    int initialIndex,
    FieldBoundaryModel boundary,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => PhotoLightboxDialog(
        photos: photos,
        initialIndex: initialIndex,
        boundary: boundary,
        taskIsLate: taskIsLate,
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final SubmittedPhotoDetail photo;
  final int index;
  final bool isInside;
  final bool isLate;
  final VoidCallback onTap;

  const _PhotoCard({
    required this.photo,
    required this.index,
    required this.isInside,
    required this.isLate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = photo.capturedAt != null && photo.capturedAt!.isNotEmpty
        ? DateFormatter.formatDateTimeToBanglaTime(photo.capturedAt)
        : '';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Thumbnail
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageWidget(photo.url),
                      // Top gradient for badge contrast
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Photo Index Tag
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ছবি ${DateFormatter.toBanglaDigits(index)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // View Icon indicator
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Info & Badges
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title and time
                    Text(
                      timeStr.isNotEmpty
                          ? 'ছবি ${DateFormatter.toBanglaDigits(index)} • $timeStr'
                          : 'ছবি ${DateFormatter.toBanglaDigits(index)}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Location Pill
                    _buildPill(
                      label: isInside ? '(✓) সঠিক লোকেশনে' : '(X) লোকেশনের বাইরে',
                      isPositive: isInside,
                      positiveBg: const Color(0xFFDCFCE7),
                      positiveText: const Color(0xFF15803D),
                      negativeBg: const Color(0xFFFEE2E2),
                      negativeText: const Color(0xFFDC2626),
                    ),
                    const SizedBox(height: 4),

                    // Time Pill
                    _buildPill(
                      label: !isLate ? '(✓) সময়ের মধ্যে' : '(X) সময় পেরিয়েছে',
                      isPositive: !isLate,
                      positiveBg: const Color(0xFFDCFCE7),
                      positiveText: const Color(0xFF15803D),
                      negativeBg: const Color(0xFFFEF3C7),
                      negativeText: const Color(0xFFB45309),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required bool isPositive,
    required Color positiveBg,
    required Color positiveText,
    required Color negativeBg,
    required Color negativeText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: isPositive ? positiveBg : negativeBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isPositive ? positiveText : negativeText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildImageWidget(String url) {
    if (url.isEmpty) {
      return _buildPlaceholder();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      );
    }

    // Check local file
    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        );
      }
    } catch (_) {}

    // Resolve relative URL
    final resolved = SubmittedPhotosGrid.resolveUrl(url);
    if (resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(
          Icons.photo_rounded,
          color: Color(0xFF94A3B8),
          size: 32,
        ),
      ),
    );
  }
}

/// Fullscreen Pinch-to-zoom Lightbox Viewer Dialog
class PhotoLightboxDialog extends StatefulWidget {
  final List<SubmittedPhotoDetail> photos;
  final int initialIndex;
  final FieldBoundaryModel boundary;
  final bool taskIsLate;

  const PhotoLightboxDialog({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.boundary,
    this.taskIsLate = false,
  });

  @override
  State<PhotoLightboxDialog> createState() => _PhotoLightboxDialogState();
}

class _PhotoLightboxDialogState extends State<PhotoLightboxDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];
    final isInside = photo.insideGeofence ??
        (photo.latitude != null &&
                photo.longitude != null &&
                widget.boundary.isNotEmpty
            ? widget.boundary.isPointInside(
                photo.latitude!,
                photo.longitude!,
                20.0,
              )
            : true);
    final isPhotoLate = photo.isLate ?? widget.taskIsLate;
    final timeStr = photo.capturedAt != null && photo.capturedAt!.isNotEmpty
        ? DateFormatter.formatDateTimeToBanglaTime(photo.capturedAt)
        : '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.95),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'ছবি ${DateFormatter.toBanglaDigits(_currentIndex + 1)} / ${DateFormatter.toBanglaDigits(widget.photos.length)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Interactive Zoomable Photo PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.photos.length,
                onPageChanged: (idx) => setState(() => _currentIndex = idx),
                itemBuilder: (context, index) {
                  final item = widget.photos[index];
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: _buildFullImage(item.url),
                    ),
                  );
                },
              ),
            ),

            // Bottom Information Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.black87,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (timeStr.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'তোলার সময়: $timeStr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],

                    if (photo.latitude != null && photo.longitude != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'অবস্থান: ${photo.latitude!.toStringAsFixed(6)}, ${photo.longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Status Badges Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isInside
                                  ? const Color(0xFF14532D)
                                  : const Color(0xFF7F1D1D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isInside ? '(✓) সঠিক লোকেশনে' : '(X) লোকেশনের বাইরে',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isInside
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFCA5A5),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: !isPhotoLate
                                  ? const Color(0xFF14532D)
                                  : const Color(0xFF78350F),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              !isPhotoLate ? '(✓) সময়ের মধ্যে' : '(X) সময় পেরিয়েছে',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !isPhotoLate
                                    ? const Color(0xFF86EFAC)
                                    : const Color(0xFFFDE68A),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _errorWidget(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        },
      );
    }

    try {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _errorWidget(),
        );
      }
    } catch (_) {}

    final resolved = SubmittedPhotosGrid.resolveUrl(url);
    if (resolved.startsWith('http')) {
      return Image.network(
        resolved,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _errorWidget(),
      );
    }

    return _errorWidget();
  }

  Widget _errorWidget() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
        SizedBox(height: 10),
        Text(
          'ছবি লোড করা সম্ভব হয়নি',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }
}
