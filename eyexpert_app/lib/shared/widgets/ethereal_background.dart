import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class EtherealBackground extends StatelessWidget {
  final Widget child;

  const EtherealBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Clean neutral canvas
        Container(
          color: AppColors.background,
        ),
        
        // Top-Right Ambient Cyan Glow
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0x4467E8F9), // Subtle Cyan
                  const Color(0x2238BDF8),
                  AppColors.background.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Bottom-Left Ambient Warm Peach Glow
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0x35FDBA74), // Subtle Peach/Orange
                  const Color(0x18FDBA74),
                  AppColors.background.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),

        // Foreground Content
        child,
      ],
    );
  }
}
