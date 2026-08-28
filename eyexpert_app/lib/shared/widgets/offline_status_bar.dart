import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class OfflineStatusBar extends StatelessWidget {
  final bool isOffline;
  final int pendingCount;
  final VoidCallback? onSyncPressed;

  const OfflineStatusBar({
    super.key,
    required this.isOffline,
    this.pendingCount = 0,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isOffline ? AppColors.offlineBannerBg : AppColors.secondary,
      child: Row(
        children: [
          Icon(
            isOffline ? Icons.cloud_off_rounded : Icons.sync_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isOffline
                  ? AppConstants.offlineNotice
                  : '$pendingCount captured screening(s) queued for synchronization.',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          if (!isOffline && pendingCount > 0 && onSyncPressed != null)
            TextButton(
              onPressed: onSyncPressed,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'SYNC NOW',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
