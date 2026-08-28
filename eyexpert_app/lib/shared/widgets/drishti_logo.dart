import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class DrishtiLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;
  final Color? textColor;

  const DrishtiLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.accent;
    final textStyleColor = textColor ?? AppColors.primary;

    final logoIcon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => CustomPaint(
            size: Size(size, size * 0.75),
            painter: _DrishtiLogoPainter(color: iconColor),
          ),
        ),
      ),
    );

    if (!showText) return logoIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoIcon,
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Drishti',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: size * 0.72,
                    fontWeight: FontWeight.w800,
                    color: textStyleColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'दृष्टि',
                    style: TextStyle(
                      fontSize: size * 0.38,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _DrishtiLogoPainter extends CustomPainter {
  final Color color;

  _DrishtiLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Smooth geometric eye contour
    final path = Path();
    path.moveTo(0, h * 0.5);
    path.quadraticBezierTo(w * 0.5, -h * 0.15, w, h * 0.5);
    path.quadraticBezierTo(w * 0.5, h * 1.15, 0, h * 0.5);
    path.close();
    canvas.drawPath(path, paint);

    // Central pupil / iris node
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.16, fillPaint);

    // Neural connectivity nodes
    final nodeRadius = w * 0.05;
    canvas.drawCircle(Offset(w * 0.28, h * 0.16), nodeRadius, fillPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.16), nodeRadius, fillPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.84), nodeRadius, fillPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.84), nodeRadius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
