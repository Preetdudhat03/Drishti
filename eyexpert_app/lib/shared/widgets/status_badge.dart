import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData? icon;
  final bool isLarge;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    this.icon,
    this.isLarge = false,
  });

  factory StatusBadge.good({String label = '✓ GOOD', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusGood,
      backgroundColor: AppColors.statusGoodBg,
      isLarge: isLarge,
    );
  }

  factory StatusBadge.borderline({String label = '⚠ BORDERLINE', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusBorderline,
      backgroundColor: AppColors.statusBorderlineBg,
      isLarge: isLarge,
    );
  }

  factory StatusBadge.ungradable({String label = '✕ UNGRADABLE', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusUngradable,
      backgroundColor: AppColors.statusUngradableBg,
      isLarge: isLarge,
    );
  }

  factory StatusBadge.referable({String label = '⚠ REFERABLE DR — OPHTHALMOLOGIST REVIEW', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.referableAlert,
      backgroundColor: AppColors.referableAlertBg,
      isLarge: isLarge,
    );
  }

  factory StatusBadge.pending({String label = '⏳ PENDING REVIEW', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.pending,
      backgroundColor: const Color(0xFFEFF6FF),
      isLarge: isLarge,
    );
  }

  factory StatusBadge.nonReferable({String label = '✓ NON-REFERABLE', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusGood,
      backgroundColor: AppColors.statusGoodBg,
      isLarge: isLarge,
    );
  }

  // AI vs Clinician Distinction Pills
  factory StatusBadge.aiBadge({String label = 'AI SCREENING RESULT'}) {
    return StatusBadge(
      label: label,
      color: AppColors.accent,
      backgroundColor: AppColors.accentLight,
      icon: Icons.psychology_rounded,
    );
  }

  factory StatusBadge.clinicianBadge({String label = 'CLINICIAN FINAL DECISION'}) {
    return StatusBadge(
      label: label,
      color: AppColors.primary,
      backgroundColor: AppColors.primaryLight,
      icon: Icons.verified_user_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: isLarge ? 16 : 13),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: isLarge ? 12 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
