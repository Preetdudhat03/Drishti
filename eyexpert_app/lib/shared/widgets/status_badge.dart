import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;
  final IconData icon;
  final bool isLarge;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.icon,
    this.isLarge = false,
  });

  factory StatusBadge.good({String label = 'GOOD', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusGood,
      backgroundColor: AppColors.statusGoodBg,
      icon: Icons.check_circle_outline,
      isLarge: isLarge,
    );
  }

  factory StatusBadge.borderline({String label = 'BORDERLINE', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusBorderline,
      backgroundColor: AppColors.statusBorderlineBg,
      icon: Icons.warning_amber_rounded,
      isLarge: isLarge,
    );
  }

  factory StatusBadge.ungradable({String label = 'UNGRADABLE', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.statusUngradable,
      backgroundColor: AppColors.statusUngradableBg,
      icon: Icons.highlight_off_rounded,
      isLarge: isLarge,
    );
  }

  factory StatusBadge.referable({String label = 'REFERABLE DR — YES', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.referableAlert,
      backgroundColor: AppColors.referableAlertBg,
      icon: Icons.notification_important_rounded,
      isLarge: isLarge,
    );
  }

  factory StatusBadge.nonReferable({String label = 'NON-REFERABLE', bool isLarge = false}) {
    return StatusBadge(
      label: label,
      color: AppColors.nonReferable,
      backgroundColor: AppColors.nonReferableBg,
      icon: Icons.verified_user_outlined,
      isLarge: isLarge,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 3,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: isLarge ? 18 : 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: isLarge ? 13 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
