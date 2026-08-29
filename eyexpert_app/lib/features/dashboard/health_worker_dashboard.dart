import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/offline_status_bar.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../../data/models/screening_case_model.dart';
import '../review/review_queue_provider.dart';
import '../offline/sync_queue_provider.dart';
import '../auth/auth_provider.dart';
import '../../core/network/connection_provider.dart';

class HealthWorkerDashboard extends ConsumerWidget {
  final VoidCallback onStartScreening;
  final VoidCallback onViewCases;

  const HealthWorkerDashboard({
    super.key,
    required this.onStartScreening,
    required this.onViewCases,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewState = ref.watch(reviewQueueProvider);
    final syncState = ref.watch(syncQueueProvider);
    final authState = ref.watch(authProvider);
    final isTabletOrDesktop = !ResponsiveLayout.isMobile(context);

    return Column(
      children: [
        OfflineStatusBar(
          isOnline: syncState.isOnline,
          pendingCount: syncState.pendingCount,
          onTap: () => ref.read(syncQueueProvider.notifier).syncNow(),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(reviewQueueProvider.notifier).loadPendingReviews(),
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
                      // Greeting & Workstation Header
                      ClinicalCard(
                        backgroundColor: Colors.white,
                        borderColor: AppColors.border,
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.accentLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.remove_red_eye_rounded, color: AppColors.accent, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Good morning, ${authState.user?.name ?? "Health Worker"}',
                                    style: AppTypography.pageHeading,
                                  ),
                                  const SizedBox(height: 3),
                                  const Text(
                                    'AI-assisted retinal screening • Primary Health Centre Ramgarh',
                                    style: AppTypography.bodySecondary,
                                  ),
                                ],
                              ),
                            ),
                            if (isTabletOrDesktop)
                              PrimaryButton(
                                text: '+ START NEW SCREENING',
                                icon: Icons.add_a_photo_rounded,
                                onPressed: onStartScreening,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Metrics Grid (2x2 on mobile, 4x1 on tablet/desktop)
                      GridView.count(
                        crossAxisCount: isTabletOrDesktop ? 4 : 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: isTabletOrDesktop ? 1.4 : 1.25,
                        children: [
                          _metricCard(
                            title: "Today's Screened",
                            value: '${reviewState.totalScreenedCount}',
                            subtitle: 'Active session',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.primary,
                          ),
                          _metricCard(
                            title: 'Pending Review',
                            value: '${reviewState.totalPendingCount}',
                            subtitle: 'Awaiting clinician',
                            icon: Icons.hourglass_empty_rounded,
                            color: AppColors.pending,
                          ),
                          _metricCard(
                            title: 'Referable Cases',
                            value: '${reviewState.referableCount}',
                            subtitle: 'Level >= 2 (Urgent)',
                            icon: Icons.warning_amber_rounded,
                            color: AppColors.referableAlert,
                          ),
                          _metricCard(
                            title: 'Recapture Needed',
                            value: '${reviewState.recaptureNeededCount}',
                            subtitle: 'Ungradable / blur',
                            icon: Icons.replay_rounded,
                            color: AppColors.statusUngradable,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Large Start Screening Button on Mobile
                      if (!isTabletOrDesktop) ...[
                        PrimaryButton(
                          text: '+ START NEW SCREENING',
                          icon: Icons.camera_alt_outlined,
                          height: 52,
                          onPressed: onStartScreening,
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Recent Screening Activity Table
                      ClinicalCard(
                        title: 'Recent Screening Sessions',
                        titleAction: TextButton(
                          onPressed: onViewCases,
                          child: const Text('View All Cases', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.accent)),
                        ),
                        child: reviewState.cases.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inbox_outlined, size: 36, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No active screening sessions yet',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tap "+ START NEW SCREENING" to begin',
                                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviewState.cases.take(4).length,
                                separatorBuilder: (_, __) => const Divider(height: 12),
                                itemBuilder: (context, index) {
                                  final c = reviewState.cases[index];
                                  final pred = c.prediction;
                                  final isUngradable = c.quality?.isUngradable ?? false;
                                  final isReferable = pred?.referable ?? false;

                                  final subtitleText = isUngradable
                                      ? 'Quality: UNGRADABLE • Recapture Required'
                                      : pred != null
                                          ? 'AI: Level ${pred.drLevel} (${pred.severityLabel}) • Prob: ${AppFormatters.formatProbability(pred.modelProbability)}'
                                          : c.status == ScreeningStatus.awaitingImage
                                              ? 'Awaiting retinal image capture'
                                              : c.status == ScreeningStatus.qualityAssessment
                                                  ? 'Quality assessment in progress'
                                                  : 'Screening registered';

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isUngradable
                                            ? AppColors.statusUngradableBg
                                            : isReferable
                                                ? AppColors.referableAlertBg
                                                : AppColors.statusGoodBg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isUngradable
                                              ? AppColors.statusUngradable.withValues(alpha: 0.3)
                                              : isReferable
                                                  ? AppColors.referableAlert.withValues(alpha: 0.3)
                                                  : AppColors.statusGood.withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          isUngradable
                                              ? Icons.cancel_outlined
                                              : isReferable
                                                  ? Icons.warning_amber_rounded
                                                  : Icons.check_circle_outline_rounded,
                                          color: isUngradable
                                              ? AppColors.statusUngradable
                                              : isReferable
                                                  ? AppColors.referableAlert
                                                  : AppColors.statusGood,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          c.patient.patientId,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${c.patient.eye})',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      subtitleText,
                                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                    ),
                                    trailing: isUngradable
                                        ? StatusBadge.ungradable()
                                        : isReferable
                                            ? StatusBadge.referable(label: 'REFERABLE')
                                            : c.hasReviewed
                                                ? StatusBadge.good(label: 'VALIDATED')
                                                : StatusBadge.pending(label: 'PENDING'),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 14),

                      const MedicalDisclaimerBanner(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
