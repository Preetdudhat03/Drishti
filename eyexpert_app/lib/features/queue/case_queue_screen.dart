import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/screening_case_model.dart';
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
        // Search & Filter Header matching DiagnoX Patients screen
        Container(
          padding: const EdgeInsets.fromLTRB(20, 96, 20, 8),
          color: Colors.transparent,
          child: Column(
            children: [
              // Pill Search Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (val) => ref.read(reviewQueueProvider.notifier).setSearchQuery(val),
                  decoration: const InputDecoration(
                    hintText: 'Type a symptom, patient ID, or name...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(ref, 'All (${queueState.totalScreenedCount})', 'ALL', queueState.filter),
                    const SizedBox(width: 8),
                    _filterChip(ref, 'Pending (${queueState.totalPendingCount})', 'PENDING', queueState.filter),
                    const SizedBox(width: 8),
                    _filterChip(ref, 'Referable Priority (${queueState.referableCount})', 'REFERABLE', queueState.filter),
                    const SizedBox(width: 8),
                    _filterChip(ref, 'Completed (${queueState.completedCount})', 'COMPLETED', queueState.filter),
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

        // Cases List
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
                              const Icon(Icons.folder_open_rounded, size: 54, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                queueState.searchQuery.isEmpty
                                    ? 'No cases currently in review queue.'
                                    : 'No cases found matching "${queueState.searchQuery}"',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Swipe down to refresh from Supabase database',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: cases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = cases[index];
                      final pred = c.prediction;
                      final isHighRisk = c.isReferable || (pred != null && pred.drLevel >= 3);
                      final String patientName = 'Patient #${c.patient.patientId}';
                      final String patientAge = c.patient.age != null && c.patient.age! > 0 ? '${c.patient.age}y' : '42y';
                      final String patientGender = c.patient.gender?.isNotEmpty == true ? c.patient.gender! : 'Male';
                      final String eyeSide = AppFormatters.formatEye(c.patient.eye);

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.025),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onSelectCase(c),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Tag pills
                                  Row(
                                    children: [
                                      _tagPill('Diabetes', const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
                                      const SizedBox(width: 6),
                                      _tagPill(eyeSide, const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
                                      const SizedBox(width: 6),
                                      if (isHighRisk)
                                        _tagPill('Urgent Triage', AppColors.badgeHighRiskBg, AppColors.badgeHighRiskText)
                                      else if (c.hasReviewed)
                                        _tagPill('Validated', const Color(0xFFF1F5F9), AppColors.textPrimary),
                                      const Spacer(),
                                      const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Clinical summary note
                                  Text(
                                    pred != null
                                        ? '${pred.severityLabel}. Confidence: ${(pred.modelProbability * 100).toStringAsFixed(0)}%. Screening ID: ${c.screeningId}'
                                        : 'Intake completed. Screening awaiting AI inference and specialist grading.',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),

                                  // Demographics + Patient Name Row
                                  Row(
                                    children: [
                                      Text(
                                        '$patientAge   $patientGender   $eyeSide',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Bottom Row: Avatar + Name + Action Icons
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primaryLight,
                                        child: Text(
                                          patientName.substring(0, 1).toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          patientName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                                    ],
                                  ),
                                ],
                              ),
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

  Widget _tagPill(String label, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, String label, String value, String currentFilter) {
    final isSelected = currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontSize: 11.5,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (_) => ref.read(reviewQueueProvider.notifier).setFilter(value),
    );
  }
}
