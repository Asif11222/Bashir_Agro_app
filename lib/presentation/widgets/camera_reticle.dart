import 'package:flutter/material.dart';

class CameraReticlePainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double strokeWidth;
  final double borderRadius;

  CameraReticlePainter({
    this.color = Colors.white,
    this.cornerLength = 32.0,
    this.strokeWidth = 3.5,
    this.borderRadius = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-Left corner
    final tlPath = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, borderRadius)
      ..quadraticBezierTo(0, 0, borderRadius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(tlPath, paint);

    // Top-Right corner
    final trPath = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - borderRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, borderRadius)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(trPath, paint);

    // Bottom-Left corner
    final blPath = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - borderRadius)
      ..quadraticBezierTo(0, size.height, borderRadius, size.height)
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(blPath, paint);

    // Bottom-Right corner
    final brPath = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - borderRadius, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - borderRadius)
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(brPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
