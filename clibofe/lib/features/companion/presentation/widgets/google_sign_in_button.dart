import 'package:flutter/material.dart';

/// Official Google 'G' Logo custom vector painter adhering to Google Brand Guidelines
class GoogleLogoPainter extends CustomPainter {
  const GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Center point and radius
    final Offset center = Offset(w / 2, h / 2);
    final double outerRadius = w / 2;
    final double innerRadius = w * 0.28;

    final Paint paint = Paint()
      ..style = PaintingStyle.fill;

    // 1. Red Top Arc (120° to 240°)
    paint.color = const Color(0xFFEA4335);
    final Path redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        -3.14159 * 0.78, // -140 deg
        3.14159 * 0.58,  // ~105 deg
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(redPath, paint);

    // 2. Yellow Left Arc (240° to 310°)
    paint.color = const Color(0xFFFBBC05);
    final Path yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        -3.14159 * 1.35, // -243 deg
        3.14159 * 0.58,
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // 3. Green Bottom Arc
    paint.color = const Color(0xFF34A853);
    final Path greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        -3.14159 * 0.20, // -36 deg
        3.14159 * 0.58,
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(greenPath, paint);

    // 4. Blue Right Arc & Bar
    paint.color = const Color(0xFF4285F4);
    final Path bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        3.14159 * 0.38,
        3.14159 * 0.40,
        false,
      )
      ..lineTo(center.dx, center.dy)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Inner cutout to make it a ring
    paint.color = Colors.white;
    canvas.drawCircle(center, innerRadius, paint);

    // Blue horizontal bar for the 'G'
    paint.color = const Color(0xFF4285F4);
    final Rect blueBar = Rect.fromLTRB(
      center.dx - w * 0.05,
      center.dy - h * 0.12,
      center.dx + outerRadius,
      center.dy + h * 0.12,
    );
    canvas.drawRect(blueBar, paint);

    // Re-clip center right notch cutout to complete 'G'
    paint.color = Colors.white;
    final Path notchCutout = Path()
      ..moveTo(center.dx, center.dy - h * 0.12)
      ..lineTo(center.dx + outerRadius * 0.5, center.dy - h * 0.12)
      ..lineTo(center.dx + outerRadius * 0.5, center.dy - outerRadius * 0.8)
      ..lineTo(center.dx, center.dy - outerRadius * 0.8)
      ..close();
    canvas.drawPath(notchCutout, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Official Google Brand 'Sign in with Google' Button
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.text = "Continue with Google",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF747775), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F1F1F)),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else ...[
                  // Official Google Multi-Color 'G' Icon
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(
                      painter: GoogleLogoPainter(),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
