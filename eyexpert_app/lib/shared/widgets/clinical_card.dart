import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ClinicalCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleAction;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool isFeatured;

  const ClinicalCard({
    super.key,
    required this.child,
    this.title,
    this.titleAction,
    this.icon,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ??
              (isFeatured
                  ? AppColors.accent.withValues(alpha: 0.35)
                  : AppColors.border),
          width: isFeatured ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isFeatured
                ? AppColors.accent.withValues(alpha: 0.08)
                : const Color(0x060F172A),
            blurRadius: isFeatured ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    icon!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (titleAction != null) ...[
                    const SizedBox(width: 8),
                    titleAction!,
                  ],
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }
}
