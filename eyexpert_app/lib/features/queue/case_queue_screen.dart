import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/screening_case_model.dart';
import '../../shared/widgets/status_badge.dart';
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
        const Divider(height: 1),

        // Cases List
        Expanded(
          child: cases.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No cases found matching "${queueState.searchQuery}"',
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
                )
              : ListView.separated(
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
                      child: InkWell(
                        onTap: () => onSelectCase(c),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Retinal / Status Indicator Icon
                              CircleAvatar(
                                radius: 22,
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
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Patient / Screening Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          c.patient.patientId,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${AppFormatters.formatEye(c.patient.eye)})',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          c.screeningId,
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      quality?.isUngradable ?? false
                                          ? 'Image Quality: UNGRADABLE • Recapture Required'
                                          : 'AI: Level ${pred?.drLevel} (${pred?.severityLabel}) • Prob: ${AppFormatters.formatProbability(pred?.modelProbability)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Recorded: ${AppFormatters.formatDateTime(c.createdAt)}',
                                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),

                              // Status Pill & Review Action
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  StatusBadge(
                                    label: review != null
                                        ? 'REVIEWED'
                                        : isReferable
                                            ? 'REFERABLE (URGENT)'
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
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    onPressed: () => onSelectCase(c),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minimumSize: Size.zero,
                                      backgroundColor: isReferable ? AppColors.referableAlert : AppColors.primary,
                                    ),
                                    child: Text(
                                      review != null ? 'View Details' : 'Review Case',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
