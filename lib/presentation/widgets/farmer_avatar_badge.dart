import 'dart:math' as math;
import 'package:flutter/material.dart';

class FarmerAvatarBadge extends StatelessWidget {
  final String name;
  final double size;
  final bool hasGamcha;
  final bool hasBeard;
  final bool isElderly;

  const FarmerAvatarBadge({
    super.key,
    required this.name,
    this.size = 54,
    this.hasGamcha = false,
    this.hasBeard = false,
    this.isElderly = false,
  });

  factory FarmerAvatarBadge.fromName(String name, {double size = 54}) {
    if (name.contains('করিম') || name.contains('হানিফ')) {
      return FarmerAvatarBadge(name: name, size: size, isElderly: true, hasBeard: true);
    } else if (name.contains('জহিরুল') || name.contains('সেলিম')) {
      return FarmerAvatarBadge(name: name, size: size, hasGamcha: true, hasBeard: false);
    } else if (name.contains('কামাল')) {
      return FarmerAvatarBadge(name: name, size: size, hasBeard: true);
    } else {
      return FarmerAvatarBadge(name: name, size: size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size(size, size),
          painter: _FarmerAvatarPainter(
            hasGamcha: hasGamcha,
            hasBeard: hasBeard,
            isElderly: isElderly,
          ),
        ),
      ),
    );
  }
}

class _FarmerAvatarPainter extends CustomPainter {
  final bool hasGamcha;
  final bool hasBeard;
  final bool isElderly;

  _FarmerAvatarPainter({
    required this.hasGamcha,
    required this.hasBeard,
    required this.isElderly,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background outdoor field tint
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF81D4FA),
          const Color(0xFFA5D6A7),
          const Color(0xFF66BB6A),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawCircle(Offset(w / 2, h / 2), w / 2, bgPaint);

    // Shirt / Shoulders
    final shirtColor = isElderly
        ? const Color(0xFF455A64)
        : (hasGamcha ? const Color(0xFF1E88E5) : const Color(0xFF5E35B1));
    final shirtPaint = Paint()..color = shirtColor;

    final shirtPath = Path()
      ..moveTo(w * 0.12, h)
      ..quadraticBezierTo(w * 0.18, h * 0.70, w * 0.35, h * 0.68)
      ..lineTo(w * 0.65, h * 0.68)
      ..quadraticBezierTo(w * 0.82, h * 0.70, w * 0.88, h)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Neck
    final skinColor = isElderly ? const Color(0xFFD7CCC8) : const Color(0xFFFFB74D);
    final skinPaint = Paint()..color = skinColor;
    canvas.drawRect(Rect.fromLTWH(w * 0.42, h * 0.58, w * 0.16, h * 0.14), skinPaint);

    // Face
    canvas.drawOval(Rect.fromLTWH(w * 0.30, h * 0.30, w * 0.40, h * 0.34), skinPaint);

    // Hair or Gamcha
    if (hasGamcha) {
      // Gamcha turban cloth wrapped around head (Red-orange checkered)
      final gamchaBase = Paint()..color = const Color(0xFFE53935);
      final gamchaPath = Path()
        ..moveTo(w * 0.22, h * 0.38)
        ..quadraticBezierTo(w * 0.24, h * 0.16, w * 0.50, h * 0.14)
        ..quadraticBezierTo(w * 0.76, h * 0.16, w * 0.78, h * 0.38)
        ..quadraticBezierTo(w * 0.50, h * 0.32, w * 0.22, h * 0.38)
        ..close();
      canvas.drawPath(gamchaPath, gamchaBase);

      // Stripes on gamcha
      final stripePaint = Paint()
        ..color = const Color(0xFFFFCC80)
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(w * 0.26, h * 0.34), Offset(w * 0.74, h * 0.30), stripePaint);
      canvas.drawLine(Offset(w * 0.32, h * 0.24), Offset(w * 0.68, h * 0.20), stripePaint);
    } else {
      // Hair
      final hairColor = isElderly ? const Color(0xFFE0E0E0) : const Color(0xFF212121);
      final hairPaint = Paint()..color = hairColor;
      canvas.drawArc(
        Rect.fromLTWH(w * 0.28, h * 0.26, w * 0.44, h * 0.22),
        math.pi,
        math.pi,
        true,
        hairPaint,
      );
    }

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF212121);
    canvas.drawCircle(Offset(w * 0.42, h * 0.44), 2.2, eyePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.44), 2.2, eyePaint);

    // Moustache or Beard
    if (hasBeard) {
      final beardColor = isElderly ? const Color(0xFFEEEEEE) : const Color(0xFF3E2723);
      final beardPaint = Paint()..color = beardColor;
      // Beard covering lower jaw
      final beardPath = Path()
        ..moveTo(w * 0.32, h * 0.48)
        ..quadraticBezierTo(w * 0.30, h * 0.64, w * 0.50, h * 0.68)
        ..quadraticBezierTo(w * 0.70, h * 0.64, w * 0.68, h * 0.48)
        ..quadraticBezierTo(w * 0.50, h * 0.56, w * 0.32, h * 0.48)
        ..close();
      canvas.drawPath(beardPath, beardPaint);
    } else {
      // Gentle smile
      final mouthPaint = Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      final smile = Path()
        ..moveTo(w * 0.45, h * 0.53)
        ..quadraticBezierTo(w * 0.50, h * 0.56, w * 0.55, h * 0.53);
      canvas.drawPath(smile, mouthPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
