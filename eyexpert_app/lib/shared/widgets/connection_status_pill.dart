import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/connection_provider.dart';
import '../../core/theme/app_colors.dart';

class ConnectionStatusPill extends ConsumerWidget {
  final bool isCompact;

  const ConnectionStatusPill({
    super.key,
    this.isCompact = false,
  });

  void _showConnectionDetails(BuildContext context, WidgetRef ref, ConnectionStateModel conn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AI Telemetry & Cloud Sync',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: conn.isOnline ? AppColors.accentLight : const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: conn.isOnline ? AppColors.accent.withValues(alpha: 0.3) : AppColors.statusCritical.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      conn.isOnline ? 'CLOUD SYNC ACTIVE' : 'OFFLINE MODE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: conn.isOnline ? AppColors.accent : AppColors.statusCritical,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _buildStatusRow(
                'Supabase Cloud Data Layer',
                conn.supabaseConnected ? 'SYNCHRONIZED' : 'STANDALONE LOCAL',
                conn.supabaseConnected,
              ),
              const SizedBox(height: 8),
              _buildStatusRow(
                'Drishti PyTorch AI Engine',
                conn.backendConnected ? 'ONLINE (CUDA/CPU)' : 'ASYNC BATCH QUEUE',
                conn.backendConnected,
              ),
              if (conn.isOffline) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.statusBorderlineBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.statusBorderline.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: AppColors.statusBorderline, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Offline edge mode enabled. Retinal screenings and patient intakes remain encrypted on-device and will auto-sync once connectivity is restored.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(connectionProvider.notifier).checkConnection();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Re-verify AI Cloud Links'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusRow(String service, String status, bool isOk) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isOk ? AppColors.accent : AppColors.statusCritical,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: isOk ? AppColors.accent : AppColors.statusCritical,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);

    Color bg;
    Color text;
    Color dot;
    String label;

    if (conn.isChecking) {
      bg = const Color(0xFF1E293B);
      text = const Color(0xFF94A3B8);
      dot = const Color(0xFF94A3B8);
      label = isCompact ? '...' : 'Syncing...';
    } else if (conn.isOnline) {
      bg = const Color(0xFF1E1B4B);
      text = const Color(0xFFC7D2FE);
      dot = const Color(0xFF818CF8);
      label = isCompact ? 'Online' : 'Cloud Sync Active';
    } else {
      bg = const Color(0xFF4C0519);
      text = const Color(0xFFFECDD3);
      dot = const Color(0xFFF43F5E);
      label = isCompact ? 'Offline' : 'Offline Edge';
    }

    return InkWell(
      onTap: () => _showConnectionDetails(context, ref, conn),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: dot.withValues(alpha: 0.5), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (conn.isChecking)
              SizedBox(
                width: 8,
                height: 8,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: text),
              )
            else
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dot,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: dot.withValues(alpha: 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
