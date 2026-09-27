import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/diagnox_stat_card.dart';
import '../../shared/widgets/offline_status_bar.dart';
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
    final tr = ref.watch(trProvider);
    final user = authState.user;

    final String workerName = user?.name.isNotEmpty == true ? user!.name : 'Sunita Sharma';

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          ref.read(connectionProvider.notifier).checkConnection(),
          ref.read(reviewQueueProvider.notifier).loadPendingReviews(),
        ]);
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: ResponsiveLayout.pagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OfflineStatusBar(
                  isOnline: syncState.isOnline,
                  pendingCount: syncState.pendingCount,
                  onTap: () => ref.read(syncQueueProvider.notifier).syncNow(),
                ),
                const SizedBox(height: 10),

                // 1. Header: Branding & Greeting + Worker Avatar
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryLight,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          size: 26,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Greetings & Role
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${AppFormatters.getGreeting()}, ',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    workerName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${user?.facilityId ?? "PHC-RAMGARH-01"} • ${user?.organization ?? "Tele-Screening Unit"}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Primary Action Buttons (Hero Centerpiece)
                PillButton(
                  label: tr('start_screening'),
                  icon: Icons.camera_alt_rounded,
                  width: double.infinity,
                  height: 50,
                  onPressed: onStartScreening,
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: tr('view_records'),
                  icon: Icons.folder_open_rounded,
                  variant: PillButtonVariant.secondaryOutlined,
                  width: double.infinity,
                  height: 46,
                  onPressed: onViewCases,
                ),

                const SizedBox(height: 16),

                // 3. Stats Rows (Four PHC Metrics)
                Row(
                  children: [
                    Expanded(
                      child: DiagnoXStatCard(
                        icon: Icons.people_alt_rounded,
                        category: tr('stat_screened'),
                        value: '${reviewState.totalScreenedCount}',
                        subtitle: tr('stat_screened_sub'),
                        iconColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DiagnoXStatCard(
                        icon: Icons.warning_amber_rounded,
                        category: tr('stat_referable'),
                        value: '${reviewState.referableCount}',
                        subtitle: tr('stat_referable_sub'),
                        iconColor: AppColors.statusCritical,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DiagnoXStatCard(
                        icon: Icons.pending_actions_rounded,
                        category: tr('stat_pending'),
                        value: '${reviewState.totalPendingCount}',
                        subtitle: tr('stat_pending_sub'),
                        iconColor: AppColors.statusBorderline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DiagnoXStatCard(
                        icon: Icons.verified_rounded,
                        category: tr('stat_completed'),
                        value: '${reviewState.completedCount}',
                        subtitle: tr('stat_completed_sub'),
                        iconColor: AppColors.statusGood,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 4. "Recent Screenings" Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('recent_screenings'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: onViewCases,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Text(
                          tr('view_all'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (reviewState.cases.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        tr('no_screenings_today') != 'no_screenings_today'
                            ? tr('no_screenings_today')
                            : 'No recent screenings recorded yet today.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else ...[
                  for (int index = 0; index < reviewState.cases.take(5).length; index++) ...[
                    if (index > 0) const SizedBox(height: 8),
                    _buildRecentScreeningCard(reviewState.cases[index]),
                  ],
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentScreeningCard(dynamic c) {
    final pred = c.prediction;
    final isHighRisk = c.isReferable || pred?.drLevel == 4 || pred?.drLevel == 3;
    final isLowRisk = pred?.drLevel == 0 || pred?.drLevel == 1;

    final String patientDisplayName = c.patient.patientId.startsWith('PT-')
        ? c.patient.patientId
        : 'Patient #${c.patient.patientId}';

    final String conditionLabel = pred != null
        ? '${pred.severityLabel} • ${AppFormatters.formatEye(c.patient.eye)}'
        : 'Grading in progress';

    final String riskBadgeText = isHighRisk
        ? 'High Risk'
        : isLowRisk
            ? 'Low Risk'
            : 'Moderate';

    final Color riskBg = isHighRisk
        ? AppColors.badgeHighRiskBg
        : isLowRisk
            ? AppColors.badgeLowRiskBg
            : AppColors.badgeModerateBg;

    final Color riskTextColor = isHighRisk
        ? AppColors.badgeHighRiskText
        : isLowRisk
            ? AppColors.badgeLowRiskText
            : AppColors.badgeModerateText;

    final Color riskBorderColor = isHighRisk
        ? AppColors.badgeHighRiskBorder
        : isLowRisk
            ? AppColors.badgeLowRiskBorder
            : AppColors.badgeModerateBorder;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientDisplayName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conditionLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: riskBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: riskBorderColor, width: 1),
              ),
              child: Text(
                riskBadgeText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: riskTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
