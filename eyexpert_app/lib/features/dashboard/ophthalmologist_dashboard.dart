import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../../data/models/screening_case_model.dart';
import '../review/review_queue_provider.dart';
import '../auth/auth_provider.dart';

class OphthalmologistDashboard extends ConsumerWidget {
  final VoidCallback onOpenReviewQueue;
  final VoidCallback onViewCases;
  final VoidCallback onViewSystemStatus;
  final Function(ScreeningCaseModel)? onSelectCase;

  const OphthalmologistDashboard({
    super.key,
    required this.onOpenReviewQueue,
    required this.onViewCases,
    required this.onViewSystemStatus,
    this.onSelectCase,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(reviewQueueProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isTabletOrDesktop = !ResponsiveLayout.isMobile(context);

    final pendingCases = reviewState.cases.where((c) => c.isPendingReview).toList();
    final urgentCases = reviewState.cases.where((c) => c.prediction?.drLevel == 4 && c.isPendingReview).toList();
    final referableCases = reviewState.cases.where((c) => c.isReferable && c.isPendingReview).toList();
    final completedCases = reviewState.cases.where((c) => c.hasReviewed).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reviewQueueProvider.notifier).loadPendingReviews();
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Specialist Header Banner
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.medical_services_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name.isNotEmpty == true ? user!.name : 'Specialist Ophthalmologist',
                              style: AppTypography.titleLarge.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'OPHTHALMOLOGIST · ${user?.organization ?? "DISTRICT EYE CENTRE"}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isTabletOrDesktop) ...[
                        ElevatedButton.icon(
                          onPressed: onOpenReviewQueue,
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: Text('Open Review Queue (${pendingCases.length})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Metrics Grid
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _metricCard(
                      context,
                      title: 'Pending Reviews',
                      value: pendingCases.length.toString(),
                      subtitle: 'Awaiting clinical validation',
                      icon: Icons.pending_actions_rounded,
                      color: AppColors.primary,
                      isAlert: pendingCases.isNotEmpty,
                    ),
                    _metricCard(
                      context,
                      title: 'Urgent / PDR Cases',
                      value: urgentCases.length.toString(),
                      subtitle: 'Level 4 Proliferative DR',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.statusCritical,
                      isAlert: urgentCases.isNotEmpty,
                    ),
                    _metricCard(
                      context,
                      title: 'Referable DR Cases',
                      value: referableCases.length.toString(),
                      subtitle: 'Moderate / Severe / PDR',
                      icon: Icons.health_and_safety_outlined,
                      color: AppColors.statusBorderline,
                      isAlert: false,
                    ),
                    _metricCard(
                      context,
                      title: 'Completed Reviews',
                      value: completedCases.length.toString(),
                      subtitle: 'Human-validated reports',
                      icon: Icons.check_circle_outline,
                      color: AppColors.statusGood,
                      isAlert: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Action Shortcuts (Mobile Viewport)
                if (!isTabletOrDesktop) ...[
                  PrimaryButton(
                    text: 'Open Priority Review Queue (${pendingCases.length})',
                    icon: Icons.rate_review_outlined,
                    onPressed: onOpenReviewQueue,
                  ),
                  const SizedBox(height: 16),
                ],

                // Urgent Priority Queue Preview
                ClinicalCard(
                  title: 'Cases Requiring Immediate Specialist Review',
                  actionText: 'View All (${reviewState.cases.length})',
                  onActionTap: onOpenReviewQueue,
                  child: pendingCases.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: const Column(
                            children: [
                              Icon(Icons.task_alt_rounded, size: 36, color: AppColors.statusGood),
                              SizedBox(height: 8),
                              Text(
                                'All pending screening cases have been reviewed!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pendingCases.take(4).length,
                          separatorBuilder: (_, __) => const Divider(height: 16),
                          itemBuilder: (context, index) {
                            final c = pendingCases[index];
                            final pred = c.prediction;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: c.isReferable
                                    ? AppColors.statusCritical.withValues(alpha: 0.1)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: c.isReferable ? AppColors.statusCritical : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    c.patient.patientId,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                  ),
                                  const SizedBox(width: 8),
                                  StatusBadge(
                                    label: AppFormatters.formatEye(c.patient.eye),
                                    type: StatusBadgeType.neutral,
                                  ),
                                  const Spacer(),
                                  if (pred != null) ...[
                                    StatusBadge(
                                      label: 'AI: Level ${pred.drLevel}',
                                      type: c.isReferable ? StatusBadgeType.critical : StatusBadgeType.good,
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                '${c.screeningId} • Registered ${AppFormatters.formatTimeAgo(c.createdAt)}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                              trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                              onTap: () {
                                if (onSelectCase != null) {
                                  onSelectCase!(c);
                                } else {
                                  onOpenReviewQueue();
                                }
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 18),

                // Clinical Telemetry & Microservices Health Link
                ClinicalCard(
                  title: 'Drishti AI Inference & Cloud Infrastructure',
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_done_outlined, color: AppColors.statusGood, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PyTorch 2.2+ ResNet-18 & Layer-4 Grad-CAM Active',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Supabase PostgreSQL Profiles & RLS Security Online',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: onViewSystemStatus,
                        child: const Text('Status'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const MedicalDisclaimerBanner(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isAlert,
  }) {
    final width = ResponsiveLayout.isMobile(context)
        ? (MediaQuery.of(context).size.width - 44) / 2
        : 240.0;

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAlert ? color.withValues(alpha: 0.6) : AppColors.border,
          width: isAlert ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: isAlert ? color : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
