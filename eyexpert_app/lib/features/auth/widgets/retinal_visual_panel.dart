import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/user_model.dart';

class RetinalVisualPanel extends StatefulWidget {
  final UserRole activeRole;

  const RetinalVisualPanel({
    super.key,
    required this.activeRole,
  });

  @override
  State<RetinalVisualPanel> createState() => _RetinalVisualPanelState();
}

class _RetinalVisualPanelState extends State<RetinalVisualPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPHC = widget.activeRole == UserRole.healthWorker;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.obsidianCanvas,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.obsidianBorder,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Animated Retinal Scanner Canvas
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _RetinalWorkstationPainter(
                    progress: _animController.value,
                    isPHC: isPHC,
                  ),
                );
              },
            ),
          ),

          // Subtle Dark Gradient Overlay for readability
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.obsidianDeep.withValues(alpha: 0.35),
                    Colors.transparent,
                    AppColors.obsidianDeep.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
          ),

          // Content Layer
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header HUD Tag
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.obsidianSurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.electricBlue.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.statusNormal,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'CLINICAL INTELLIGENCE WORKSTATION',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.hudCyan,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.obsidianElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.obsidianBorder,
                          width: 0.8,
                        ),
                      ),
                      child: const Text(
                        'LATENCY < 1.2s',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSubtle,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Center Retinal Status Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.obsidianSurface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isPHC
                          ? AppColors.electricBlue.withValues(alpha: 0.3)
                          : AppColors.aiViolet.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPHC ? Icons.security : Icons.visibility_outlined,
                            size: 18,
                            color: isPHC ? AppColors.electricBlue : AppColors.aiViolet,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isPHC
                                  ? 'Edge Retinal Quality & Screening Gate'
                                  : 'Explainable AI Grad-CAM Visualizer',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textBright,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isPHC
                            ? 'Instant CLAHE contrast enhancement, illumination check, and sharpness gate ensuring fundus suitability before specialist dispatch.'
                            : 'Layer-4 gradient-weighted class activation mapping (Grad-CAM) localizing microaneurysms and hemorrhages for rapid clinical validation.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildMiniBadge(
                            label: 'MODEL',
                            value: 'ResNet-18',
                            accent: AppColors.electricBlue,
                          ),
                          _buildMiniBadge(
                            label: 'XAI',
                            value: 'Grad-CAM L4',
                            accent: AppColors.aiViolet,
                          ),
                          _buildMiniBadge(
                            label: 'SECURITY',
                            value: 'RLS Encrypted',
                            accent: AppColors.hudCyan,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Bottom Clinical Governance Notice
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.obsidianCanvas.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.obsidianBorder,
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 15,
                        color: AppColors.statusNormal,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Human-in-the-Loop Architecture: AI provides screening recommendations; final diagnosis remains strictly under qualified ophthalmologists.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textSubtle,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.obsidianCanvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accent.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSubtle,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetinalWorkstationPainter extends CustomPainter {
  final double progress;
  final bool isPHC;

  _RetinalWorkstationPainter({
    required this.progress,
    required this.isPHC,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.44);
    final maxRadius = math.min(size.width, size.height) * 0.46;

    final gridPaint = Paint()
      ..color = AppColors.obsidianBorder.withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final ringPaint = Paint()
      ..color = AppColors.hudCyan.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final ringGlowPaint = Paint()
      ..color = (isPHC ? AppColors.electricBlue : AppColors.aiViolet)
          .withValues(alpha: 0.18)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Draw background grid lines
    const gridSpacing = 40.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Concentric Retinal Inspection Rings
    for (int i = 1; i <= 4; i++) {
      final r = maxRadius * (i / 4.0);
      canvas.drawCircle(center, r, ringPaint);
    }

    // Animated Pulsing Retinal Scan Ring
    final pulseRadius = maxRadius * ((progress * 1.5) % 1.0);
    canvas.drawCircle(
      center,
      pulseRadius,
      Paint()
        ..color = (isPHC ? AppColors.electricBlue : AppColors.aiViolet)
            .withValues(alpha: (1.0 - (pulseRadius / maxRadius)).clamp(0.0, 0.4))
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // Crosshairs
    canvas.drawLine(
      Offset(center.dx - maxRadius * 1.1, center.dy),
      Offset(center.dx + maxRadius * 1.1, center.dy),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius * 1.1),
      Offset(center.dx, center.dy + maxRadius * 1.1),
      ringPaint,
    );

    // Retinal Vascular Branches (Stylized Arc Patterns)
    final vesselPaint = Paint()
      ..color = (isPHC ? AppColors.electricBlue : AppColors.aiViolet)
          .withValues(alpha: 0.35)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final vesselPath = Path();
    // Optic disc center
    final opticDisc = Offset(center.dx - maxRadius * 0.28, center.dy + maxRadius * 0.05);

    // Superior temporal arcade
    vesselPath.moveTo(opticDisc.dx, opticDisc.dy);
    vesselPath.cubicTo(
      opticDisc.dx + 20,
      opticDisc.dy - maxRadius * 0.45,
      opticDisc.dx + maxRadius * 0.55,
      opticDisc.dy - maxRadius * 0.5,
      opticDisc.dx + maxRadius * 0.8,
      opticDisc.dy - maxRadius * 0.15,
    );

    // Inferior temporal arcade
    vesselPath.moveTo(opticDisc.dx, opticDisc.dy);
    vesselPath.cubicTo(
      opticDisc.dx + 20,
      opticDisc.dy + maxRadius * 0.45,
      opticDisc.dx + maxRadius * 0.55,
      opticDisc.dy + maxRadius * 0.5,
      opticDisc.dx + maxRadius * 0.75,
      opticDisc.dy + maxRadius * 0.25,
    );

    // Nasal arcade
    vesselPath.moveTo(opticDisc.dx, opticDisc.dy);
    vesselPath.cubicTo(
      opticDisc.dx - maxRadius * 0.2,
      opticDisc.dy - maxRadius * 0.25,
      opticDisc.dx - maxRadius * 0.45,
      opticDisc.dy - maxRadius * 0.1,
      opticDisc.dx - maxRadius * 0.6,
      opticDisc.dy + maxRadius * 0.1,
    );

    canvas.drawPath(vesselPath, vesselPaint);

    // Draw Optic Disc Glow
    canvas.drawCircle(
      opticDisc,
      14,
      Paint()
        ..color = AppColors.statusWarning.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(
      opticDisc,
      8,
      Paint()..color = AppColors.statusWarning.withValues(alpha: 0.8),
    );

    // Macula / Fovea Center Glow
    final macula = Offset(center.dx + maxRadius * 0.15, center.dy);
    canvas.drawCircle(
      macula,
      18,
      Paint()
        ..color = (isPHC ? AppColors.electricBlue : AppColors.aiViolet)
            .withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    canvas.drawCircle(
      macula,
      3,
      Paint()..color = AppColors.hudCyan,
    );

    // Neural Network / Grad-CAM Attention Nodes
    final nodePoints = [
      Offset(opticDisc.dx + 40, opticDisc.dy - 35),
      Offset(opticDisc.dx + 80, opticDisc.dy - 65),
      Offset(macula.dx + 30, macula.dy - 25),
      Offset(macula.dx - 20, macula.dy + 40),
      Offset(macula.dx + 45, macula.dy + 30),
    ];

    for (int i = 0; i < nodePoints.length; i++) {
      final pt = nodePoints[i];
      final nodeGlow = Paint()
        ..color = (i % 2 == 0 ? AppColors.hudCyan : AppColors.aiViolet)
            .withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(pt, 5, nodeGlow);
      canvas.drawCircle(
        pt,
        2.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      // Connect nodes
      if (i > 0) {
        canvas.drawLine(
          nodePoints[i - 1],
          pt,
          Paint()
            ..color = AppColors.hudCyan.withValues(alpha: 0.2)
            ..strokeWidth = 0.9,
        );
      }
    }

    // Rotating Radar Scan Line
    final scanAngle = progress * 2 * math.pi;
    final scanEnd = Offset(
      center.dx + maxRadius * math.cos(scanAngle),
      center.dy + maxRadius * math.sin(scanAngle),
    );
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          (isPHC ? AppColors.electricBlue : AppColors.hudCyan).withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromPoints(center, scanEnd))
      ..strokeWidth = 1.8;
    canvas.drawLine(center, scanEnd, scanPaint);
  }

  @override
  bool shouldRepaint(covariant _RetinalWorkstationPainter oldDelegate) => true;
}
