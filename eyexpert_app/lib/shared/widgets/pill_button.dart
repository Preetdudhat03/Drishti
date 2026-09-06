import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum PillButtonVariant {
  primary,
  secondaryOutlined,
  danger,
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PillButtonVariant variant;
  final bool isLoading;
  final double? width;
  final double height;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = PillButtonVariant.primary,
    this.isLoading = false,
    this.width,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Border? border;
    List<BoxShadow>? shadows;

    switch (variant) {
      case PillButtonVariant.primary:
        bgColor = AppColors.primary;
        textColor = Colors.white;
        shadows = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ];
        break;
      case PillButtonVariant.secondaryOutlined:
        bgColor = Colors.white;
        textColor = AppColors.textPrimary;
        border = Border.all(color: AppColors.border, width: 1.2);
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ];
        break;
      case PillButtonVariant.danger:
        bgColor = AppColors.badgeHighRiskBg;
        textColor = AppColors.badgeHighRiskText;
        border = Border.all(color: AppColors.badgeHighRiskBorder, width: 1.2);
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(height / 2),
        border: border,
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(height / 2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: width == null ? MainAxisSize.min : MainAxisSize.max,
              children: [
                if (isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else if (icon != null) ...[
                  Icon(icon, size: 18, color: textColor),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.1,
                    ),
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
