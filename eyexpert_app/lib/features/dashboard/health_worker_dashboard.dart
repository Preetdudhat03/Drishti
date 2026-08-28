import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/offline_status_bar.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../../data/models/screening_case_model.dart';
import '../review/review_queue_provider.dart';
import '../offline/sync_queue_provider.dart';
import '../auth/auth_provider.dart';

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
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final totalCases = reviewState.allCases.length;
    final referableCases = reviewState.referableCount;
    final pendingCases = reviewState.totalPendingCount;

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
            color: AppColors.electricBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. HERO WORKSTATION HEADER
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: AppColors.deepSpace,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderDark, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Good morning, ${authState.user?.name ?? "Health Worker"}',
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'AI Retinal Screening Workstation • ${authState.user?.facilityId ?? "PHC-RAMGARH-01"}',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.darkTextSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
