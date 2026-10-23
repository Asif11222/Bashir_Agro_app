import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Sprout icon inside a circular white badge (Screen 1 & general branding)
class SproutLogoBadge extends StatelessWidget {
  final double size;

  const SproutLogoBadge({super.key, this.size = 110});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.eco_rounded,
          color: AppColors.primaryGreen,
          size: size * 0.6,
        ),
      ),
    );
  }
}

/// Farmer Avatar with straw hat matching Design 2
class FarmerAvatar extends StatelessWidget {
  final double size;

  const FarmerAvatar({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFC8E6C9),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFA5D6A7), width: 1.5),
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _FarmerAvatarPainter(),
        ),
      ),
    );
  }
}

class _FarmerAvatarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background circle tint
    final bgPaint = Paint()..color = const Color(0xFFD7ECD9);
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // Green shirt / shoulders
    final shirtPaint = Paint()..color = const Color(0xFF2E7D32);
    final shirtPath = Path()
      ..moveTo(w * 0.15, h)
      ..quadraticBezierTo(w * 0.20, h * 0.70, w * 0.35, h * 0.68)
      ..lineTo(w * 0.65, h * 0.68)
      ..quadraticBezierTo(w * 0.80, h * 0.70, w * 0.85, h)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Overall straps
    final strapPaint = Paint()
      ..color = const Color(0xFF1B5E20)
      ..strokeWidth = w * 0.06
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.30, h * 0.70), Offset(w * 0.26, h), strapPaint);
    canvas.drawLine(Offset(w * 0.70, h * 0.70), Offset(w * 0.74, h), strapPaint);

    // Neck
    final skinPaint = Paint()..color = const Color(0xFFFFCC80);
    canvas.drawRect(Rect.fromLTWH(w * 0.42, h * 0.58, w * 0.16, h * 0.14), skinPaint);

    // Head / Face
    canvas.drawOval(Rect.fromLTWH(w * 0.32, h * 0.32, w * 0.36, h * 0.32), skinPaint);

    // Dark hair peek
    final hairPaint = Paint()..color = const Color(0xFF3E2723);
    canvas.drawArc(
      Rect.fromLTWH(w * 0.32, h * 0.30, w * 0.36, h * 0.16),
      math.pi,
      math.pi,
      true,
      hairPaint,
    );

    // Straw Hat (Yellow/Tan)
    final hatCrownPaint = Paint()..color = const Color(0xFFFBC02D);
    canvas.drawOval(Rect.fromLTWH(w * 0.28, h * 0.18, w * 0.44, h * 0.22), hatCrownPaint);

    // Green Hat Ribbon
    final ribbonPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRect(Rect.fromLTWH(w * 0.30, h * 0.30, w * 0.40, h * 0.05), ribbonPaint);

    // Hat Brim
    final brimPaint = Paint()
      ..color = const Color(0xFFFDD835)
      ..strokeWidth = w * 0.07
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final brimPath = Path()
      ..moveTo(w * 0.14, h * 0.36)
      ..quadraticBezierTo(w * 0.50, h * 0.32, w * 0.86, h * 0.36);
    canvas.drawPath(brimPath, brimPaint);

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(Offset(w * 0.43, h * 0.46), w * 0.025, eyePaint);
    canvas.drawCircle(Offset(w * 0.57, h * 0.46), w * 0.025, eyePaint);

    // Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(w * 0.45, h * 0.54)
      ..quadraticBezierTo(w * 0.50, h * 0.58, w * 0.55, h * 0.54);
    canvas.drawPath(smilePath, smilePaint);

    // Sprout emblem on bottom right
    final sproutBg = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.82, h * 0.82), w * 0.14, sproutBg);

    final sproutPaint = Paint()..color = const Color(0xFF2E7D32);
    final leaf1 = Path()
      ..moveTo(w * 0.82, h * 0.86)
      ..quadraticBezierTo(w * 0.72, h * 0.80, w * 0.76, h * 0.74)
      ..quadraticBezierTo(w * 0.82, h * 0.76, w * 0.82, h * 0.86);
    canvas.drawPath(leaf1, sproutPaint);

    final leaf2 = Path()
      ..moveTo(w * 0.82, h * 0.86)
      ..quadraticBezierTo(w * 0.92, h * 0.80, w * 0.88, h * 0.74)
      ..quadraticBezierTo(w * 0.82, h * 0.76, w * 0.82, h * 0.86);
    canvas.drawPath(leaf2, sproutPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom illustration thumbnail for Task items (Vegetable, Fish, Cow)
class TaskThumbnailWidget extends StatelessWidget {
  final String type;
  final double size;
  final double borderRadius;

  const TaskThumbnailWidget({
    super.key,
    required this.type,
    this.size = 72,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    CustomPainter painter;

    switch (type) {
      case 'fish':
        bgColor = const Color(0xFFE2F1FD);
        painter = _FishSwimmingPainter();
        break;
      case 'cow':
        bgColor = const Color(0xFFFDF4E7);
        painter = _CowPainter();
        break;
      case 'fertilizer':
        bgColor = const Color(0xFFFFF8E1);
        painter = _FertilizerBagPainter();
        break;
      case 'vegetable':
      default:
        bgColor = const Color(0xFFE8F6EB);
        painter = _PlantSeedlingPainter();
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CustomPaint(
          size: Size(size, size),
          painter: painter,
        ),
      ),
    );
  }
}

/// 1. Fish Swimming Painter matching Design 2
class _FishSwimmingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Water waves at bottom (y = 0.68 to 1.0)
    final deepWaterPaint = Paint()..color = const Color(0xFF29B6F6);
    final wave1 = Path()
      ..moveTo(0, h * 0.74)
      ..quadraticBezierTo(w * 0.20, h * 0.68, w * 0.40, h * 0.74)
      ..quadraticBezierTo(w * 0.60, h * 0.80, w * 0.80, h * 0.74)
      ..quadraticBezierTo(w * 0.90, h * 0.71, w, h * 0.74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(wave1, deepWaterPaint);

    final lightWavePaint = Paint()..color = const Color(0xFF81D4FA);
    final wave2 = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.25, h * 0.76, w * 0.50, h * 0.82)
      ..quadraticBezierTo(w * 0.75, h * 0.88, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(wave2, lightWavePaint);

    // White crest line
    final crestPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final crestPath = Path()
      ..moveTo(0, h * 0.74)
      ..quadraticBezierTo(w * 0.20, h * 0.68, w * 0.40, h * 0.74)
      ..quadraticBezierTo(w * 0.60, h * 0.80, w * 0.80, h * 0.74)
      ..quadraticBezierTo(w * 0.90, h * 0.71, w, h * 0.74);
    canvas.drawPath(crestPath, crestPaint);

    // 2. Fish Body (Blue fish swimming towards the left)
    canvas.save();
    // Slight counter-clockwise tilt to look like swimming/jumping
    canvas.translate(w * 0.48, h * 0.44);
    canvas.rotate(-0.10);
    canvas.translate(-w * 0.48, -h * 0.44);

    // Tail Fin (Dark Blue)
    final tailPaint = Paint()..color = const Color(0xFF1565C0);
    final tailPath = Path()
      ..moveTo(w * 0.66, h * 0.44)
      ..lineTo(w * 0.84, h * 0.32)
      ..quadraticBezierTo(w * 0.78, h * 0.44, w * 0.84, h * 0.56)
      ..close();
    canvas.drawPath(tailPath, tailPaint);

    // Dorsal Fin (Top)
    final dorsalPaint = Paint()..color = const Color(0xFF1976D2);
    final dorsalPath = Path()
      ..moveTo(w * 0.42, h * 0.33)
      ..quadraticBezierTo(w * 0.52, h * 0.22, w * 0.60, h * 0.36)
      ..close();
    canvas.drawPath(dorsalPath, dorsalPaint);

    // Main Fish Body (Vibrant Ocean Blue)
    final bodyPaint = Paint()..color = const Color(0xFF1E88E5);
    final bodyPath = Path()
      ..moveTo(w * 0.20, h * 0.44) // Nose tip
      ..cubicTo(w * 0.28, h * 0.28, w * 0.55, h * 0.28, w * 0.68, h * 0.44) // Top curve
      ..cubicTo(w * 0.55, h * 0.60, w * 0.28, h * 0.60, w * 0.20, h * 0.44) // Bottom curve
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Underbelly (Lighter cyan/blue)
    final bellyPaint = Paint()..color = const Color(0xFFBBDEFB);
    final bellyPath = Path()
      ..moveTo(w * 0.22, h * 0.45)
      ..cubicTo(w * 0.30, h * 0.58, w * 0.52, h * 0.58, w * 0.66, h * 0.45)
      ..cubicTo(w * 0.52, h * 0.50, w * 0.30, h * 0.50, w * 0.22, h * 0.45)
      ..close();
    canvas.drawPath(bellyPath, bellyPaint);

    // Pectoral Fin (Side fin)
    final finPaint = Paint()..color = const Color(0xFF1565C0);
    final finPath = Path()
      ..moveTo(w * 0.38, h * 0.46)
      ..quadraticBezierTo(w * 0.46, h * 0.48, w * 0.48, h * 0.55)
      ..quadraticBezierTo(w * 0.42, h * 0.54, w * 0.38, h * 0.46);
    canvas.drawPath(finPath, finPaint);

    // Fish Eye
    final eyeBg = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.30, h * 0.40), w * 0.045, eyeBg);

    final eyePupil = Paint()..color = const Color(0xFF0D47A1);
    canvas.drawCircle(Offset(w * 0.29, h * 0.40), w * 0.026, eyePupil);

    final eyeShine = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.28, h * 0.39), w * 0.010, eyeShine);

    canvas.restore();

    // Water Splash Droplets
    final dropPaint = Paint()..color = const Color(0xFF4FC3F7);
    canvas.drawCircle(Offset(w * 0.20, h * 0.34), 2.2, dropPaint);
    canvas.drawCircle(Offset(w * 0.16, h * 0.48), 1.8, dropPaint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.62), 2.0, dropPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. Cow Painter matching Design 2 (Brown cow standing on grass)
class _CowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grass at bottom
    final grassPaint = Paint()..color = const Color(0xFF4CAF50);
    final darkGrass = Paint()..color = const Color(0xFF388E3C);

    // Grass patch
    canvas.drawOval(Rect.fromLTWH(w * 0.08, h * 0.78, w * 0.84, h * 0.18), grassPaint);

    // Grass blades tufts
    void drawGrassBlade(double x, double y, double height, Paint p) {
      final path = Path()
        ..moveTo(x - 2, y)
        ..quadraticBezierTo(x, y - height, x + 2, y - height * 0.8)
        ..lineTo(x + 2, y)
        ..close();
      canvas.drawPath(path, p);
    }

    drawGrassBlade(w * 0.65, h * 0.84, 12, darkGrass);
    drawGrassBlade(w * 0.70, h * 0.84, 16, grassPaint);
    drawGrassBlade(w * 0.75, h * 0.84, 11, darkGrass);
    drawGrassBlade(w * 0.20, h * 0.84, 10, darkGrass);
    drawGrassBlade(w * 0.24, h * 0.84, 14, grassPaint);

    // Cow colors
    final bodyBrown = Paint()..color = const Color(0xFF9E5C32); // Warm rich cow brown
    final darkBrown = Paint()..color = const Color(0xFF7B4220); // Back legs shadow
    final hoofPaint = Paint()..color = const Color(0xFF3E2723); // Hooves
    final snoutPaint = Paint()..color = const Color(0xFFF5C5B0); // Pinkish muzzle
    final hornPaint = Paint()..color = const Color(0xFFEFEBE9); // Ivory horns

    // Back legs (in shadow)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.20, h * 0.52, w * 0.08, h * 0.30), const Radius.circular(3)),
      darkBrown,
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.20, h * 0.79, w * 0.08, h * 0.04), hoofPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.44, h * 0.52, w * 0.08, h * 0.30), const Radius.circular(3)),
      darkBrown,
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.44, h * 0.79, w * 0.08, h * 0.04), hoofPaint);

    // Tail
    final tailPath = Path()
      ..moveTo(w * 0.16, h * 0.42)
      ..quadraticBezierTo(w * 0.10, h * 0.52, w * 0.12, h * 0.64);
    final tailLine = Paint()
      ..color = const Color(0xFF9E5C32)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(tailPath, tailLine);
    // Tail brush
    canvas.drawOval(Rect.fromLTWH(w * 0.09, h * 0.62, w * 0.05, h * 0.07), hoofPaint);

    // Torso / Body
    final bodyPath = Path()
      ..moveTo(w * 0.16, h * 0.40)
      ..quadraticBezierTo(w * 0.15, h * 0.36, w * 0.20, h * 0.36)
      ..lineTo(w * 0.52, h * 0.36)
      ..quadraticBezierTo(w * 0.56, h * 0.38, w * 0.56, h * 0.50)
      ..lineTo(w * 0.55, h * 0.62)
      ..quadraticBezierTo(w * 0.35, h * 0.64, w * 0.18, h * 0.62)
      ..close();
    canvas.drawPath(bodyPath, bodyBrown);

    // Front legs (closer, in light)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.26, h * 0.54, w * 0.085, h * 0.28), const Radius.circular(3)),
      bodyBrown,
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.26, h * 0.79, w * 0.085, h * 0.04), hoofPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.50, h * 0.54, w * 0.085, h * 0.28), const Radius.circular(3)),
      bodyBrown,
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.50, h * 0.79, w * 0.085, h * 0.04), hoofPaint);

    // Cow Head & Neck
    // Neck connection
    final neckPath = Path()
      ..moveTo(w * 0.48, h * 0.38)
      ..lineTo(w * 0.58, h * 0.30)
      ..lineTo(w * 0.66, h * 0.44)
      ..lineTo(w * 0.54, h * 0.50)
      ..close();
    canvas.drawPath(neckPath, bodyBrown);

    // Horns (behind ears)
    final horn1 = Path()
      ..moveTo(w * 0.59, h * 0.25)
      ..quadraticBezierTo(w * 0.56, h * 0.18, w * 0.54, h * 0.18)
      ..quadraticBezierTo(w * 0.58, h * 0.22, w * 0.61, h * 0.26)
      ..close();
    canvas.drawPath(horn1, hornPaint);

    final horn2 = Path()
      ..moveTo(w * 0.68, h * 0.25)
      ..quadraticBezierTo(w * 0.72, h * 0.18, w * 0.74, h * 0.18)
      ..quadraticBezierTo(w * 0.70, h * 0.22, w * 0.66, h * 0.26)
      ..close();
    canvas.drawPath(horn2, hornPaint);

    // Ears (floppy sideways)
    final ear1 = Path()
      ..moveTo(w * 0.57, h * 0.28)
      ..quadraticBezierTo(w * 0.47, h * 0.28, w * 0.48, h * 0.33)
      ..quadraticBezierTo(w * 0.53, h * 0.35, w * 0.58, h * 0.32)
      ..close();
    canvas.drawPath(ear1, bodyBrown);
    canvas.drawOval(Rect.fromLTWH(w * 0.50, h * 0.29, w * 0.06, h * 0.03), snoutPaint);

    final ear2 = Path()
      ..moveTo(w * 0.70, h * 0.28)
      ..quadraticBezierTo(w * 0.80, h * 0.28, w * 0.79, h * 0.33)
      ..quadraticBezierTo(w * 0.74, h * 0.35, w * 0.69, h * 0.32)
      ..close();
    canvas.drawPath(ear2, bodyBrown);
    canvas.drawOval(Rect.fromLTWH(w * 0.71, h * 0.29, w * 0.06, h * 0.03), snoutPaint);

    // Head Base (Rounded)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.56, h * 0.23, w * 0.16, h * 0.22), const Radius.circular(8)),
      bodyBrown,
    );

    // Muzzle / Snout (Tan / Pinkish bottom oval)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.58, h * 0.36, w * 0.16, h * 0.12), const Radius.circular(6)),
      snoutPaint,
    );

    // Nostrils
    final nostrilPaint = Paint()..color = const Color(0xFF6D3B1C);
    canvas.drawCircle(Offset(w * 0.62, h * 0.41), 1.6, nostrilPaint);
    canvas.drawCircle(Offset(w * 0.69, h * 0.41), 1.6, nostrilPaint);

    // Eyes (Big gentle cow eyes)
    final eyePaint = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(Offset(w * 0.61, h * 0.31), 2.4, eyePaint);
    canvas.drawCircle(Offset(w * 0.68, h * 0.31), 2.4, eyePaint);

    final eyeShine = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.605, h * 0.305), 0.9, eyeShine);
    canvas.drawCircle(Offset(w * 0.675, h * 0.305), 0.9, eyeShine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. Plant Seedling on Soil Painter matching Design 2
class _PlantSeedlingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soil mounds at bottom
    final soilDark = Paint()..color = const Color(0xFF5D4037);
    final soilLight = Paint()..color = const Color(0xFF795548);

    final soilPath = Path()
      ..moveTo(0, h * 0.78)
      ..quadraticBezierTo(w * 0.20, h * 0.70, w * 0.35, h * 0.73)
      ..quadraticBezierTo(w * 0.50, h * 0.67, w * 0.65, h * 0.72)
      ..quadraticBezierTo(w * 0.85, h * 0.69, w, h * 0.76)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(soilPath, soilDark);

    // Soil bumps
    canvas.drawCircle(Offset(w * 0.25, h * 0.76), w * 0.08, soilLight);
    canvas.drawCircle(Offset(w * 0.50, h * 0.74), w * 0.10, soilLight);
    canvas.drawCircle(Offset(w * 0.75, h * 0.77), w * 0.09, soilLight);

    // Green Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF388E3C)
      ..strokeWidth = 3.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stemPath = Path()
      ..moveTo(w * 0.50, h * 0.72)
      ..quadraticBezierTo(w * 0.49, h * 0.54, w * 0.50, h * 0.38);
    canvas.drawPath(stemPath, stemPaint);

    // Left Leaf (Bright Green)
    final leafLeftPaint = Paint()..color = const Color(0xFF4CAF50);
    final leafLeft = Path()
      ..moveTo(w * 0.50, h * 0.46)
      ..cubicTo(w * 0.36, h * 0.42, w * 0.20, h * 0.30, w * 0.24, h * 0.24)
      ..cubicTo(w * 0.36, h * 0.20, w * 0.48, h * 0.32, w * 0.50, h * 0.46)
      ..close();
    canvas.drawPath(leafLeft, leafLeftPaint);

    // Right Leaf (Lush Leaf Green)
    final leafRightPaint = Paint()..color = const Color(0xFF43A047);
    final leafRight = Path()
      ..moveTo(w * 0.50, h * 0.42)
      ..cubicTo(w * 0.64, h * 0.38, w * 0.80, h * 0.26, w * 0.76, h * 0.20)
      ..cubicTo(w * 0.64, h * 0.16, w * 0.52, h * 0.28, w * 0.50, h * 0.42)
      ..close();
    canvas.drawPath(leafRight, leafRightPaint);

    // Leaf center veins
    final veinPaint = Paint()
      ..color = const Color(0xFF81C784)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.50, h * 0.44), Offset(w * 0.28, h * 0.26), veinPaint);
    canvas.drawLine(Offset(w * 0.50, h * 0.40), Offset(w * 0.72, h * 0.22), veinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Realistic Vegetable Field Image Simulator for Screen 3, 4, 5
class FarmBannerSimulator extends StatelessWidget {
  final double height;
  final BorderRadius? borderRadius;
  final String type; // 'vegetable', 'fish', 'cow'

  const FarmBannerSimulator({
    super.key,
    this.height = 190,
    this.borderRadius,
    this.type = 'vegetable',
  });

  String get _assetPath {
    switch (type) {
      case 'fish':
        return 'assets/images/fish_pond.jpg';
      case 'cow':
        return 'assets/images/cow_shed.jpg';
      case 'vegetable':
      default:
        return 'assets/images/vegetable_field.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Image.asset(
          _assetPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Sky & Landscape gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF81D4FA), // Sky blue
                        Color(0xFFB2EBF2),
                        Color(0xFF66BB6A), // Crop green
                        Color(0xFF2E7D32), // Deep farm green
                      ],
                      stops: [0.0, 0.35, 0.45, 1.0],
                    ),
                  ),
                ),
                // Custom Painter to draw trellis, bamboo sticks & lush foliage
                CustomPaint(
                  painter: _FarmCropPainter(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FarmCropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stickPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final wirePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final leafPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.fill;

    final darkLeafPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    final flowerPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.fill;

    // Draw horizontal trellis wires
    final double wireY1 = size.height * 0.45;
    final double wireY2 = size.height * 0.65;
    canvas.drawLine(Offset(0, wireY1), Offset(size.width, wireY1), wirePaint);
    canvas.drawLine(Offset(0, wireY2), Offset(size.width, wireY2), wirePaint);

    // Draw vertical bamboo sticks
    final double spacing = size.width / 7;
    for (int i = 0; i <= 7; i++) {
      final double x = spacing * i + (i % 2 == 0 ? 5 : -5);
      canvas.drawLine(Offset(x, size.height * 0.25), Offset(x, size.height), stickPaint);
    }

    // Draw dense foliage clusters
    for (double x = 10; x < size.width; x += 22) {
      canvas.drawCircle(Offset(x, size.height * 0.55), 18, darkLeafPaint);
      canvas.drawCircle(Offset(x + 10, size.height * 0.65), 22, leafPaint);
      canvas.drawCircle(Offset(x - 8, size.height * 0.78), 24, darkLeafPaint);
      canvas.drawCircle(Offset(x + 6, size.height * 0.88), 26, leafPaint);

      // Yellow gourd flowers occasionally
      if (x % 44 < 20) {
        canvas.drawCircle(Offset(x + 5, size.height * 0.62), 4, flowerPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Village Natural Scenario Painter for the Dashboard Header
class VillageHeaderBackground extends StatelessWidget {
  final double height;
  final Widget child;

  const VillageHeaderBackground({
    super.key,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
            // Base Gradient Atmosphere
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF004924), // Rich deep emerald forest
                    Color(0xFF006837),
                    Color(0xFF087A42),
                  ],
                ),
              ),
            ),

            // Village Natural Scenery Canvas
            CustomPaint(
              painter: _VillageHeaderPainter(),
            ),

            // Subtle top shadow overlay for crystal-clear text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // Child Content (Titles, Date, Notification Bell)
            child,
          ],
        ),
      ),
    );
  }
}

class _VillageHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Soft Rising Morning Sun Glow in background
    final sunGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD54F).withValues(alpha: 0.35),
          const Color(0xFF81C784).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.72, h * 0.48), radius: w * 0.32));
    canvas.drawCircle(Offset(w * 0.72, h * 0.48), w * 0.32, sunGlow);

    // 2. Distant Soft Blue-Green Mountain / Hill Silhouette
    final distantHill = Paint()..color = const Color(0xFF00542B).withValues(alpha: 0.65);
    final hillPath1 = Path()
      ..moveTo(0, h * 0.58)
      ..quadraticBezierTo(w * 0.25, h * 0.48, w * 0.50, h * 0.55)
      ..quadraticBezierTo(w * 0.75, h * 0.62, w, h * 0.50)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillPath1, distantHill);

    // 3. Middle Village Tree Line & Palm Trees
    final treeLinePaint = Paint()..color = const Color(0xFF056434).withValues(alpha: 0.85);
    final treePath = Path()
      ..moveTo(0, h * 0.66)
      ..quadraticBezierTo(w * 0.15, h * 0.60, w * 0.30, h * 0.64)
      ..quadraticBezierTo(w * 0.45, h * 0.58, w * 0.60, h * 0.62)
      ..quadraticBezierTo(w * 0.80, h * 0.56, w, h * 0.60)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(treePath, treeLinePaint);

    // Coconut / Palm Trees on the right (Village signature)
    void drawPalmTree(double x, double y, double scale) {
      final trunkPaint = Paint()
        ..color = const Color(0xFF2E4625).withValues(alpha: 0.90)
        ..strokeWidth = 2.4 * scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Curved Trunk
      final trunk = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x - 5 * scale, y - 24 * scale, x - 3 * scale, y - 48 * scale);
      canvas.drawPath(trunk, trunkPaint);

      // Palm Fronds spreading out
      final leafPaint = Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.95)
        ..strokeWidth = 2.0 * scale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final topX = x - 3 * scale;
      final topY = y - 48 * scale;

      canvas.drawLine(Offset(topX, topY), Offset(topX - 16 * scale, topY - 8 * scale), leafPaint);
      canvas.drawLine(Offset(topX, topY), Offset(topX + 16 * scale, topY - 7 * scale), leafPaint);
      canvas.drawLine(Offset(topX, topY), Offset(topX - 12 * scale, topY + 7 * scale), leafPaint);
      canvas.drawLine(Offset(topX, topY), Offset(topX + 13 * scale, topY + 8 * scale), leafPaint);
      canvas.drawLine(Offset(topX, topY), Offset(topX - 6 * scale, topY - 14 * scale), leafPaint);
      canvas.drawLine(Offset(topX, topY), Offset(topX + 7 * scale, topY - 14 * scale), leafPaint);
    }

    drawPalmTree(w * 0.82, h * 0.70, 0.95);
    drawPalmTree(w * 0.88, h * 0.72, 0.80);
    drawPalmTree(w * 0.42, h * 0.70, 0.65);

    // 4. Village Thatched Hut (কুঁড়েঘর) nestled in the trees
    final hutX = w * 0.70;
    final hutY = h * 0.68;

    // Roof (Triangular thatched roof)
    final roofPaint = Paint()..color = const Color(0xFFD4A373).withValues(alpha: 0.92);
    final roofPath = Path()
      ..moveTo(hutX, hutY - 14)
      ..lineTo(hutX - 16, hutY)
      ..lineTo(hutX + 16, hutY)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Hut wall
    final wallPaint = Paint()..color = const Color(0xFFFAEDCD).withValues(alpha: 0.95);
    canvas.drawRect(Rect.fromLTWH(hutX - 12, hutY, 24, 11), wallPaint);

    // Hut Door
    final doorPaint = Paint()..color = const Color(0xFF6B4D2F);
    canvas.drawRect(Rect.fromLTWH(hutX - 3, hutY + 3, 6, 8), doorPaint);

    // 5. Winding Village Canal / Stream (নদী / নালা)
    final canalPaint = Paint()
      ..color = const Color(0xFF80DEEA).withValues(alpha: 0.35)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final canal = Path()
      ..moveTo(w * 0.58, h * 0.70)
      ..quadraticBezierTo(w * 0.52, h * 0.78, w * 0.56, h * 0.88)
      ..quadraticBezierTo(w * 0.60, h * 0.96, w * 0.54, h);
    canvas.drawPath(canal, canalPaint);

    // 6. Layered Rolling Agricultural Fields / Terraces (ফসলের মাঠ)
    final fieldLayer1 = Paint()..color = const Color(0xFF0F7A43);
    final fieldPath1 = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.30, h * 0.66, w * 0.65, h * 0.74)
      ..quadraticBezierTo(w * 0.85, h * 0.78, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(fieldPath1, fieldLayer1);

    // Foreground lush terrace
    final fieldLayer2 = Paint()..color = const Color(0xFF13884B);
    final fieldPath2 = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.35, h * 0.76, w * 0.70, h * 0.84)
      ..quadraticBezierTo(w * 0.88, h * 0.88, w, h * 0.80)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(fieldPath2, fieldLayer2);

    // Final bottom vibrant green wave
    final fieldLayer3 = Paint()..color = const Color(0xFF199A55);
    final fieldPath3 = Path()
      ..moveTo(0, h * 0.91)
      ..quadraticBezierTo(w * 0.40, h * 0.85, w * 0.75, h * 0.93)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(fieldPath3, fieldLayer3);

    // 7. Rhythmic Crop Rows across the fields
    final cropRowPaint = Paint()
      ..color = const Color(0xFF4ADE80).withValues(alpha: 0.40)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final startY = h * (0.83 + i * 0.03);
      final rowPath = Path()
        ..moveTo(0, startY)
        ..quadraticBezierTo(w * 0.35, startY - 6, w * 0.70, startY + 2)
        ..quadraticBezierTo(w * 0.88, startY + 6, w, startY);
      canvas.drawPath(rowPath, cropRowPaint);
    }

    // 8. Foreground Sprout / Leaves in bottom-center
    final sproutPaint = Paint()..color = const Color(0xFF86EFAC).withValues(alpha: 0.85);
    final leaf1 = Path()
      ..moveTo(w * 0.50, h * 0.96)
      ..quadraticBezierTo(w * 0.44, h * 0.88, w * 0.42, h * 0.86)
      ..quadraticBezierTo(w * 0.48, h * 0.88, w * 0.50, h * 0.96);
    canvas.drawPath(leaf1, sproutPaint);

    final leaf2 = Path()
      ..moveTo(w * 0.50, h * 0.96)
      ..quadraticBezierTo(w * 0.56, h * 0.88, w * 0.58, h * 0.86)
      ..quadraticBezierTo(w * 0.52, h * 0.88, w * 0.50, h * 0.96);
    canvas.drawPath(leaf2, sproutPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Standalone Sprout Leaf Illustration (without background container) for Task Details (Screen 3)
class SproutIllustration extends StatelessWidget {
  final double size;

  const SproutIllustration({super.key, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SproutLeafPainter(),
    );
  }
}

class _SproutLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final stem = Path()
      ..moveTo(w * 0.50, h * 0.90)
      ..quadraticBezierTo(w * 0.49, h * 0.65, w * 0.50, h * 0.45);
    canvas.drawPath(stem, stemPaint);

    // Left Leaf (vibrant leaf green)
    final leafPaint1 = Paint()..color = const Color(0xFF43A047);
    final leftLeaf = Path()
      ..moveTo(w * 0.50, h * 0.65)
      ..cubicTo(w * 0.28, h * 0.60, w * 0.08, h * 0.45, w * 0.12, h * 0.35)
      ..cubicTo(w * 0.28, h * 0.30, w * 0.46, h * 0.45, w * 0.50, h * 0.65)
      ..close();
    canvas.drawPath(leftLeaf, leafPaint1);

    // Right Leaf (lighter fresh green)
    final leafPaint2 = Paint()..color = const Color(0xFF4CAF50);
    final rightLeaf = Path()
      ..moveTo(w * 0.50, h * 0.58)
      ..cubicTo(w * 0.72, h * 0.53, w * 0.92, h * 0.38, w * 0.88, h * 0.28)
      ..cubicTo(w * 0.72, h * 0.23, w * 0.54, h * 0.38, w * 0.50, h * 0.58)
      ..close();
    canvas.drawPath(rightLeaf, leafPaint2);

    // Top Center Leaf
    final leafPaint3 = Paint()..color = const Color(0xFF2E7D32);
    final centerLeaf = Path()
      ..moveTo(w * 0.50, h * 0.50)
      ..cubicTo(w * 0.38, h * 0.35, w * 0.42, h * 0.12, w * 0.50, h * 0.08)
      ..cubicTo(w * 0.58, h * 0.12, w * 0.62, h * 0.35, w * 0.50, h * 0.50)
      ..close();
    canvas.drawPath(centerLeaf, leafPaint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. Fertilizer Sack/Bag Painter matching Card 4 in Design
class _FertilizerBagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Soil mound underneath
    final soilPaint = Paint()..color = const Color(0xFF6D4C41);
    final soilPath = Path()
      ..moveTo(w * 0.10, h * 0.90)
      ..quadraticBezierTo(w * 0.50, h * 0.78, w * 0.90, h * 0.90)
      ..lineTo(w * 0.92, h)
      ..lineTo(w * 0.08, h)
      ..close();
    canvas.drawPath(soilPath, soilPaint);

    // Sack Body (Beige / burlap texture)
    final sackPaint = Paint()..color = const Color(0xFFD7CCC8);
    final sackPath = Path()
      ..moveTo(w * 0.32, h * 0.32)
      ..cubicTo(w * 0.18, h * 0.45, w * 0.16, h * 0.85, w * 0.28, h * 0.88)
      ..lineTo(w * 0.72, h * 0.88)
      ..cubicTo(w * 0.84, h * 0.85, w * 0.82, h * 0.45, w * 0.68, h * 0.32)
      ..close();
    canvas.drawPath(sackPath, sackPaint);

    // Sack Fold / Shadow
    final shadowPaint = Paint()..color = const Color(0xFFBCAAA4);
    final shadowPath = Path()
      ..moveTo(w * 0.28, h * 0.88)
      ..cubicTo(w * 0.40, h * 0.85, w * 0.60, h * 0.85, w * 0.72, h * 0.88)
      ..cubicTo(w * 0.55, h * 0.91, w * 0.35, h * 0.91, w * 0.28, h * 0.88)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Sack Tied Neck
    final neckPaint = Paint()..color = const Color(0xFFA1887F);
    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.50, h * 0.30), width: w * 0.36, height: h * 0.08),
      const Radius.circular(4),
    );
    canvas.drawRRect(neckRect, neckPaint);

    // Sack Tied Top Frill
    final topPaint = Paint()..color = const Color(0xFFBCAAA4);
    final topPath = Path()
      ..moveTo(w * 0.36, h * 0.26)
      ..lineTo(w * 0.30, h * 0.16)
      ..lineTo(w * 0.44, h * 0.22)
      ..lineTo(w * 0.50, h * 0.14)
      ..lineTo(w * 0.56, h * 0.22)
      ..lineTo(w * 0.70, h * 0.16)
      ..lineTo(w * 0.64, h * 0.26)
      ..close();
    canvas.drawPath(topPath, topPaint);

    // Green circular badge on sack
    final badgePaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawCircle(Offset(w * 0.50, h * 0.58), w * 0.16, badgePaint);

    // Small white sprout / leaf icon inside badge
    final leafPaint = Paint()..color = Colors.white;
    final leafPath = Path()
      ..moveTo(w * 0.50, h * 0.66)
      ..cubicTo(w * 0.42, h * 0.60, w * 0.42, h * 0.50, w * 0.50, h * 0.48)
      ..cubicTo(w * 0.58, h * 0.50, w * 0.58, h * 0.60, w * 0.50, h * 0.66)
      ..close();
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


