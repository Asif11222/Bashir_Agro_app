import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/app_appearance.dart';

/// Shared responsive title layout for admin pages with the illustrated banner.
/// Keeps header actions outside the text area at narrow device widths.
class OwnerFarmPageHeader extends ConsumerWidget {
  final String screenKey;
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool filledAction;

  const OwnerFarmPageHeader({
    super.key,
    required this.title,
    this.screenKey = 'owner_tasks',
    required this.onBack,
    this.subtitle,
    this.actionIcon,
    this.onAction,
    this.filledAction = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(appAppearanceProvider).value?.forScreen(screenKey) ??
        const HeaderStyle({});
    final shownSubtitle = style.label('subtitle', subtitle ?? '');
    return OwnerFarmHeaderBackground(
      height: OwnerFarmHeaderBackground.standardHeight,
      screenKey: screenKey,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: IconButton(
                      onPressed: onBack,
                      tooltip: 'ফিরে যান',
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      style.label('title', title),
                      textAlign: style.textAlign,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: style.fontSize,
                        height: 1.24,
                        fontWeight: FontWeight.bold,
                        color: style.titleColor,
                        shadows: style.shadows,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: actionIcon == null
                        ? const SizedBox.shrink()
                        : DecoratedBox(
                            decoration: BoxDecoration(
                              color: filledAction
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.20),
                              shape: BoxShape.circle,
                            ),
                            child: onAction == null
                                ? Icon(
                                    actionIcon,
                                    color: filledAction
                                        ? const Color(0xFF006B3B)
                                        : Colors.white,
                                    size: 23,
                                  )
                                : IconButton(
                                    onPressed: onAction,
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      actionIcon,
                                      color: filledAction
                                          ? const Color(0xFF006B3B)
                                          : Colors.white,
                                      size: 23,
                                    ),
                                  ),
                          ),
                  ),
                ],
              ),
              if (shownSubtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  shownSubtitle,
                  textAlign: style.textAlign,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                    color: style.titleColor.withValues(alpha: 0.90),
                    shadows: style.shadows,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OwnerFarmHeaderBackground extends ConsumerWidget {
  final String screenKey;
  static const double standardHeight = 190;
  final double height;
  final Widget child;

  const OwnerFarmHeaderBackground({
    super.key,
    required this.height,
    required this.child,
    this.screenKey = 'owner_dashboard',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(appAppearanceProvider).value?.forScreen(screenKey) ?? const HeaderStyle({});
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Base Lush Green Gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF005228),
                    Color(0xFF00753E),
                    Color(0xFF0A8A4C),
                  ],
                ),
              ),
            ),

            // Farm Scenery with Greenhouse, Pond, Barn & Cows
            if (style.imageUrl == null)
              CustomPaint(painter: _OwnerFarmSceneryPainter())
            else
              Image.network(
                style.imageUrl!,
                fit: BoxFit.cover,
                cacheWidth: (MediaQuery.sizeOf(context).width * MediaQuery.devicePixelRatioOf(context)).round().clamp(320, 1440).toInt(),
                errorBuilder: (_, _, _) => CustomPaint(painter: _OwnerFarmSceneryPainter()),
              ),

            // Soft top gradient for crisp text legibility
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: style.overlay),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Content
            child,
          ],
        ),
      ),
    );
  }
}

class _OwnerFarmSceneryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Rising Morning Sun
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFE082).withValues(alpha: 0.40),
          const Color(0xFFFFF59D).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.68, h * 0.65), radius: w * 0.28));
    canvas.drawCircle(Offset(w * 0.68, h * 0.65), w * 0.28, sunGlow);

    final sunPaint = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.55);
    canvas.drawCircle(Offset(w * 0.68, h * 0.65), 24, sunPaint);

    // 2. Rolling Distant Hills
    final hill1 = Paint()..color = const Color(0xFF004D25).withValues(alpha: 0.7);
    final hillPath1 = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.3, h * 0.64, w * 0.6, h * 0.70)
      ..quadraticBezierTo(w * 0.8, h * 0.74, w, h * 0.66)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath1, hill1);

    // 3. Green crop ground / hills in foreground
    final hill2 = Paint()..color = const Color(0xFF0A6E37);
    final hillPath2 = Path()
      ..moveTo(0, h * 0.80)
      ..quadraticBezierTo(w * 0.25, h * 0.74, w * 0.55, h * 0.78)
      ..quadraticBezierTo(w * 0.75, h * 0.82, w, h * 0.76)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath2, hill2);

    // 4. White Greenhouse Polyhouse (Center-right, w * 0.55 to w * 0.72)
    final ghX = w * 0.56;
    final ghY = h * 0.73;
    final ghW = w * 0.15;
    final ghH = h * 0.08;

    final ghBase = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final ghFrame = Paint()
      ..color = const Color(0xFF81C784)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final ghPath = Path()
      ..moveTo(ghX, ghY + ghH)
      ..lineTo(ghX, ghY + ghH * 0.4)
      ..quadraticBezierTo(ghX + ghW * 0.5, ghY, ghX + ghW, ghY + ghH * 0.4)
      ..lineTo(ghX + ghW, ghY + ghH)
      ..close();
    canvas.drawPath(ghPath, ghBase);
    canvas.drawPath(ghPath, ghFrame);

    // Greenhouse ribs
    for (int i = 1; i <= 3; i++) {
      final rx = ghX + (ghW * (i / 4.0));
      canvas.drawLine(Offset(rx, ghY + ghH * 0.25), Offset(rx, ghY + ghH), ghFrame);
    }

    // 5. Oval Fish Pond with water waves (Center-left, w * 0.38 to w * 0.65)
    final pondRect = Rect.fromLTWH(w * 0.34, h * 0.82, w * 0.32, h * 0.13);
    final pondWater = Paint()..color = const Color(0xFF29B6F6);
    canvas.drawOval(pondRect, pondWater);

    // Pond border/mesh
    final pondBorder = Paint()
      ..color = const Color(0xFF0288D1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawOval(pondRect, pondBorder);

    // Pond water highlight
    final pondLight = Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 0.6);
    canvas.drawOval(Rect.fromLTWH(w * 0.38, h * 0.85, w * 0.20, h * 0.06), pondLight);

    // 6. Wooden Barn / Cowshed (Far Right, w * 0.74 to w * 0.94)
    final bX = w * 0.74;
    final bY = h * 0.74;
    final bW = w * 0.18;
    final bH = h * 0.12;

    // Barn roof (Brown wood)
    final barnRoofPaint = Paint()..color = const Color(0xFF8D6E63);
    final roofPath = Path()
      ..moveTo(bX - 4, bY + bH * 0.3)
      ..lineTo(bX + bW * 0.5, bY)
      ..lineTo(bX + bW + 4, bY + bH * 0.3)
      ..close();
    canvas.drawPath(roofPath, barnRoofPaint);

    // Barn wall
    final barnWallPaint = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawRect(Rect.fromLTWH(bX, bY + bH * 0.3, bW, bH * 0.7), barnWallPaint);

    // Barn opening
    final barnDoor = Paint()..color = const Color(0xFF3E2723);
    canvas.drawRect(Rect.fromLTWH(bX + bW * 0.25, bY + bH * 0.5, bW * 0.5, bH * 0.5), barnDoor);

    // 7. Small Cows grazing in front of barn
    void drawMiniCow(double cx, double cy) {
      final cowBody = Paint()..color = Colors.white;
      final cowSpots = Paint()..color = const Color(0xFF212121);
      final cowLegs = Paint()
        ..color = const Color(0xFF212121)
        ..strokeWidth = 1.6;

      // Legs
      canvas.drawLine(Offset(cx - 5, cy + 4), Offset(cx - 5, cy + 10), cowLegs);
      canvas.drawLine(Offset(cx - 2, cy + 4), Offset(cx - 2, cy + 10), cowLegs);
      canvas.drawLine(Offset(cx + 2, cy + 4), Offset(cx + 2, cy + 10), cowLegs);
      canvas.drawLine(Offset(cx + 5, cy + 4), Offset(cx + 5, cy + 10), cowLegs);

      // Body
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - 7, cy - 2, 14, 8), const Radius.circular(3)),
        cowBody,
      );
      // Black patches
      canvas.drawCircle(Offset(cx - 2, cy + 1), 2.8, cowSpots);
      canvas.drawCircle(Offset(cx + 3, cy), 2.2, cowSpots);

      // Head
      canvas.drawCircle(Offset(cx + 7, cy - 2), 3.5, cowBody);
      canvas.drawCircle(Offset(cx + 7, cy - 2), 1.5, cowSpots);
    }

    drawMiniCow(w * 0.81, h * 0.87);
    drawMiniCow(w * 0.88, h * 0.86);

    // 8. Distant Trees & Greenery along hills
    final treePaint = Paint()..color = const Color(0xFF035427);
    for (double tx = 10; tx < w * 0.5; tx += 20) {
      canvas.drawCircle(Offset(tx, h * 0.77), 10, treePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
