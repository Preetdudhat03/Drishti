import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/screening_case_model.dart';
import '../../shared/widgets/status_badge.dart';
import '../../core/network/connection_provider.dart';
import '../review/review_queue_provider.dart';

class CaseQueueScreen extends ConsumerWidget {
  final ValueChanged<ScreeningCaseModel> onSelectCase;

  const CaseQueueScreen({super.key, required this.onSelectCase});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueState = ref.watch(reviewQueueProvider);
    final cases = queueState.filteredCases;

    return Column(
      children: [
        // Search & Filter Header
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                onChanged: (val) => ref.read(reviewQueueProvider.notifier).setSearchQuery(val),
                decoration: const InputDecoration(
                  hintText: 'Search by Patient ID or Screening ID...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(ref, 'All Cases', 'ALL', queueState.filter),
                    const SizedBox(width: 8),
                    _filterChip(ref, 'Referable (High Priority)', 'REFERABLE', queueState.filter),
                    const SizedBox(width: 8),
                    _filterChip(ref, 'Pending Review', 'PENDING', queueState.filter),
                    const SizedBox(width: 8),
                    _filterChip(ref, 'Validated by Clinician', 'VALIDATED', queueState.filter),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (queueState.errorMessage != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFFFBEB),
            child: Row(
              children: [
                const Icon(Icons.cloud_off_rounded, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'App is currently offline. Showing local cases. Tap retry to reconnect.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await ref.read(connectionProvider.notifier).checkConnection();
                    await ref.read(reviewQueueProvider.notifier).loadPendingReviews();
                  },
                  child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        const Divider(height: 1),

        // Cases List with Pull-to-Refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.wait([
                ref.read(connectionProvider.notifier).checkConnection(),
                ref.read(reviewQueueProvider.notifier).loadPendingReviews(),
              ]);
            },
            color: AppColors.primary,
            child: cases.isEmpty
                ? LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.folder_open_rounded, size: 54, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                queueState.searchQuery.isEmpty
                                    ? 'No cases currently in review queue.'
                                    : 'No cases found matching "${queueState.searchQuery}"',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Swipe down to refresh from Supabase cloud database',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: cases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                    final c = cases[index];
                    final pred = c.prediction;
                    final quality = c.quality;
                    final review = c.review;
                    final isReferable = pred?.referable ?? false;

                    return Card(
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: InkWell(
                        onTap: () => onSelectCase(c),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Status Icon + Patient ID + Status Badge
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: quality?.isUngradable ?? false
                                        ? AppColors.statusUngradableBg
                                        : isReferable
                                            ? AppColors.referableAlertBg
                                            : AppColors.statusGoodBg,
                                    child: Icon(
                                      quality?.isUngradable ?? false
                                          ? Icons.warning_amber_rounded
                                          : isReferable
                                              ? Icons.notification_important_rounded
                                              : Icons.check_circle_outline,
                                      color: quality?.isUngradable ?? false
                                          ? AppColors.statusUngradable
                                          : isReferable
                                              ? AppColors.referableAlert
                                              : AppColors.statusGood,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${c.patient.patientId} (${AppFormatters.formatEye(c.patient.eye)})',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                        Text(
                                          c.screeningId,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(
                                    label: review != null
                                        ? 'REVIEWED'
                                        : isReferable
                                            ? 'REFERABLE'
                                            : 'NON-REFERABLE',
                                    color: review != null
                                        ? AppColors.primary
                                        : isReferable
                                            ? AppColors.referableAlert
                                            : AppColors.statusGood,
                                    backgroundColor: review != null
                                        ? AppColors.primaryLight
                                        : isReferable
                                            ? AppColors.referableAlertBg
                                            : AppColors.statusGoodBg,
                                    icon: review != null ? Icons.verified : Icons.priority_high_rounded,
                                  ),
                                ],
                              ),
                              const Divider(height: 16),

                              // Bottom Row: Prediction/Status Info + Action Button
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          quality?.isUngradable ?? false
                                              ? 'Quality: UNGRADABLE • Recapture Required'
                                              : pred != null
                                                  ? 'AI: Level ${pred.drLevel} (${pred.severityLabel}) • Prob: ${AppFormatters.formatProbability(pred.modelProbability)}'
                                                  : c.status == ScreeningStatus.awaitingImage
                                                      ? 'Awaiting retinal image capture'
                                                      : 'Screening in progress',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Recorded: ${AppFormatters.formatDateTime(c.createdAt)}',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () => onSelectCase(c),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      minimumSize: Size.zero,
                                      backgroundColor: isReferable ? AppColors.referableAlert : AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: Text(
                                      review != null ? 'View Details' : 'Review Case',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(WidgetRef ref, String label, String value, String currentFilter) {
    final isSelected = currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => ref.read(reviewQueueProvider.notifier).setFilter(value),
    );
  }
}
