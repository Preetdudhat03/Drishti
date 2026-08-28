import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ClinicalCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? titleAction;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;

  const ClinicalCard({
    super.key,
    required this.child,
    this.title,
    this.titleAction,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget content = Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.border,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  if (titleAction != null) ...[
                    const SizedBox(width: 8),
                    titleAction!,
                  ],
                ],
              ),
              const SizedBox(height: 12),
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
