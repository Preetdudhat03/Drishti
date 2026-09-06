import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class OfflineStatusBar extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final VoidCallback? onTap;

  const OfflineStatusBar({
    super.key,
    required this.isOnline,
    required this.pendingCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    final isOffline = !isOnline;
    final bgColor = isOffline ? AppColors.badgeModerateBg : AppColors.badgeLowRiskBg;
    final fgColor = isOffline ? AppColors.badgeModerateText : AppColors.statusGood;
    final borderColor = isOffline ? AppColors.badgeModerateBorder : AppColors.badgeLowRiskBorder;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOffline ? AppColors.badgeModerateText : AppColors.statusGood,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isOffline
                    ? (pendingCount > 0
                        ? 'Offline — $pendingCount ${pendingCount == 1 ? "case" : "cases"} waiting to sync'
                        : 'Offline — data will be synchronized when connectivity is restored')
                    : '✓ All cases synchronized',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            if (pendingCount > 0) ...[
              const SizedBox(width: 8),
              Text(
                'Tap to manage',
                style: TextStyle(
                  color: fgColor.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
