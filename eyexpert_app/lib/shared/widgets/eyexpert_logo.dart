import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class EyeXpertLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? color;
  final Color? textColor;

  const EyeXpertLogo({
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

    final logoIcon = CustomPaint(
      size: Size(size, size * 0.75),
      painter: _EyeXpertLogoPainter(color: iconColor),
    );

    if (!showText) return logoIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoIcon,
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Eye',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: size * 0.7,
                  fontWeight: FontWeight.w700,
                  color: textStyleColor,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Xpert',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: size * 0.7,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EyeXpertLogoPainter extends CustomPainter {
  final Color color;

  _EyeXpertLogoPainter({required this.color});

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

    // Eye outline path (Smooth geometric almond contour)
    final path = Path();
    path.moveTo(0, h * 0.5);
    path.quadraticBezierTo(w * 0.5, -h * 0.15, w, h * 0.5);
    path.quadraticBezierTo(w * 0.5, h * 1.15, 0, h * 0.5);
    path.close();
    canvas.drawPath(path, paint);

    // Central pupil / iris node
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.16, fillPaint);

    // AI Neural Connection Nodes on upper and lower perimeter
    final nodeRadius = w * 0.05;
    canvas.drawCircle(Offset(w * 0.28, h * 0.16), nodeRadius, fillPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.16), nodeRadius, fillPaint);
    canvas.drawCircle(Offset(w * 0.28, h * 0.84), nodeRadius, fillPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.84), nodeRadius, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
