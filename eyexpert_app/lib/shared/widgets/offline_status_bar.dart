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
    final bgColor = isOffline ? AppColors.offlineBannerBg : AppColors.statusGoodBg;
    final fgColor = isOffline ? Colors.white : AppColors.statusGood;
    final borderColor = isOffline ? Colors.transparent : AppColors.statusGood.withValues(alpha: 0.3);

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(color: borderColor, width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOffline ? const Color(0xFFF87171) : AppColors.statusGood,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isOffline
                  ? (pendingCount > 0
                      ? 'Offline — $pendingCount ${pendingCount == 1 ? "case" : "cases"} waiting to sync'
                      : 'Offline — data will be synchronized when connectivity is restored')
                  : '✓ All cases synchronized',
              style: TextStyle(
                color: fgColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
            if (pendingCount > 0) ...[
              const SizedBox(width: 8),
              Text(
                'Tap to manage',
                style: TextStyle(
                  color: fgColor.withValues(alpha: 0.8),
                  fontSize: 11,
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
