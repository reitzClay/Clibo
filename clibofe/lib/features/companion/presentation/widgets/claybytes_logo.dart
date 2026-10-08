import 'package:flutter/material.dart';

/// Renders the ClayBytes company emblem ("CB" monogram + square dot).
/// Attempts to load `assets/images/claybytes_logo.png` if available,
/// falling back to a crisp vector CustomPainter.
class ClayBytesEmblem extends StatelessWidget {
  final double size;
  final Color color;
  final bool showText;

  const ClayBytesEmblem({
    super.key,
    this.size = 64.0,
    this.color = Colors.cyanAccent,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    final emblemWidget = Image.asset(
      'assets/images/claybytes_logo.png',
      width: size,
      height: size,
      color: color == Colors.black ? null : color,
      errorBuilder: (context, error, stackTrace) {
        return CustomPaint(
          size: Size(size, size),
          painter: ClayBytesLogoPainter(color: color),
        );
      },
    );

    if (!showText) return emblemWidget;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblemWidget,
        const SizedBox(height: 12),
        Text(
          "ClayBytes",
          style: TextStyle(
            color: color == Colors.black ? Colors.black : Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class ClayBytesLogoPainter extends CustomPainter {
  final Color color;

  ClayBytesLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.11;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Scale canvas to 100x100 reference frame
    canvas.save();
    canvas.scale(w / 100.0, h / 100.0);

    // 1. Draw top-right square dot
    final dotSize = 10.0;
    final dotRect = Rect.fromLTWH(64, 12, dotSize, dotSize);
    canvas.drawRRect(RRect.fromRectAndRadius(dotRect, const Radius.circular(2)), fillPaint);

    // 2. Draw 'CB' Monogram Outline Path
    final path = Path();

    // Top-left C curve continuing into B
    path.moveTo(52, 32);
    path.cubicTo(68, 32, 70, 48, 54, 50); // upper loop
    path.cubicTo(72, 52, 70, 72, 52, 72); // lower loop
    path.cubicTo(32, 72, 22, 62, 22, 52); // bottom-left
    path.cubicTo(22, 42, 32, 32, 52, 32); // top-left
    path.moveTo(38, 50);
    path.lineTo(56, 50);

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ClayBytesLogoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
