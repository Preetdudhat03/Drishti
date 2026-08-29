import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/connection_provider.dart';

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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Network & Cloud Sync Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: conn.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conn.isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: conn.isOnline ? const Color(0xFF166534) : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusRow(
                'Supabase Cloud Database',
                conn.supabaseConnected ? 'CONNECTED' : 'UNREACHABLE',
                conn.supabaseConnected,
              ),
              const SizedBox(height: 8),
              _buildStatusRow(
                'Drishti PyTorch AI Engine',
                conn.backendConnected ? 'ACTIVE' : 'OFFLINE / ASYNC',
                conn.backendConnected,
              ),
              if (conn.isOffline) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No connection between the app and backend. Automated AI inference requires an active connection. Patient records remain securely queued on device.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
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
                  label: const Text('Re-test Connection Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(service, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: isOk ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isOk ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
      label = isCompact ? '...' : 'Checking...';
    } else if (conn.isOnline) {
      bg = const Color(0xFF064E3B);
      text = const Color(0xFF34D399);
      dot = const Color(0xFF10B981);
      label = isCompact ? 'Online' : 'Cloud Sync Connected';
    } else {
      bg = const Color(0xFF7F1D1D);
      text = const Color(0xFFFCA5A5);
      dot = const Color(0xFFEF4444);
      label = isCompact ? 'Offline' : 'Offline (No Connection)';
    }

    return InkWell(
      onTap: () => _showConnectionDetails(context, ref, conn),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dot.withValues(alpha: 0.4), width: 1),
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
                      color: dot.withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: text,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
