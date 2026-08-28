import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../../data/models/sync_queue_item.dart';
import 'sync_queue_provider.dart';

class SyncManagerScreen extends ConsumerWidget {
  const SyncManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncQueueProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'Rural Network Synchronization Manager',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manages localized fundus photographs captured during intermittent rural connectivity.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),

              // Network Status Banner & Simulator Toggle
              ClinicalCard(
                backgroundColor: syncState.isOnline
                    ? AppColors.statusGoodBg.withOpacity(0.4)
                    : AppColors.statusBorderlineBg.withOpacity(0.4),
                borderColor: syncState.isOnline
                    ? AppColors.statusGood.withOpacity(0.4)
                    : AppColors.statusBorderline.withOpacity(0.4),
                child: Row(
                  children: [
                    Icon(
                      syncState.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      color: syncState.isOnline ? AppColors.statusGood : AppColors.statusBorderline,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            syncState.isOnline
                                ? 'DEVICE ONLINE • SYNC ENGINE CONNECTED'
                                : 'DEVICE OFFLINE • RURAL FIELD MODE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: syncState.isOnline ? AppColors.statusGood : AppColors.statusBorderline,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            syncState.isOnline
                                ? 'Ready to synchronize pending records with central Drishti database & AI backend.'
                                : 'All captured retinal fundus cases are queued in local encrypted storage.',
                            style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: syncState.isOnline,
                      onChanged: (_) => ref.read(syncQueueProvider.notifier).toggleOnlineStatus(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Queue Summary & Actions
              Row(
                children: [
                  Expanded(
                    child: _statBox(
                      title: 'Pending Sync',
                      value: '${syncState.pendingCount}',
                      color: syncState.pendingCount > 0 ? AppColors.referableAlert : AppColors.statusGood,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statBox(
                      title: 'Synchronized',
                      value: '${syncState.syncedCount}',
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Synchronize All Pending Cases',
                      icon: Icons.sync_rounded,
                      isLoading: syncState.isSyncing,
                      onPressed: syncState.pendingCount > 0
                          ? () => ref.read(syncQueueProvider.notifier).syncNow()
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => ref.read(syncQueueProvider.notifier).clearCompleted(),
                    child: const Text('Clear Synced'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Queue Items List Card
              ClinicalCard(
                title: 'Local Sync Queue Items',
                child: syncState.queue.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.cloud_done_outlined, size: 36, color: AppColors.statusGood),
                              SizedBox(height: 8),
                              Text('Sync queue is clear. No pending offline cases.', style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: syncState.queue.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, index) {
                          final item = syncState.queue[index];
                          final isUploaded = item.status == SyncStatus.uploaded;
                          final isUploading = item.status == SyncStatus.uploading;
                          final isFailed = item.status == SyncStatus.syncFailed;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              isUploaded
                                  ? Icons.cloud_done_rounded
                                  : isUploading
                                      ? Icons.cloud_upload_rounded
                                      : isFailed
                                          ? Icons.error_outline_rounded
                                          : Icons.cloud_queue_rounded,
                              color: isUploaded
                                  ? AppColors.statusGood
                                  : isFailed
                                      ? AppColors.statusUngradable
                                      : AppColors.primary,
                            ),
                            title: Text(
                              'Patient: ${item.patientId} (${item.eye})',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              'Captured: ${AppFormatters.formatDateTime(item.capturedAt)} • Local ID: ${item.localId}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: StatusBadge(
                              label: item.status.label,
                              color: isUploaded
                                  ? AppColors.statusGood
                                  : isFailed
                                      ? AppColors.statusUngradable
                                      : AppColors.statusBorderline,
                              backgroundColor: isUploaded
                                  ? AppColors.statusGoodBg
                                  : isFailed
                                      ? AppColors.statusUngradableBg
                                      : AppColors.statusBorderlineBg,
                              icon: isUploaded ? Icons.check : Icons.hourglass_top,
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              const MedicalDisclaimerBanner(isCompact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statBox({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
