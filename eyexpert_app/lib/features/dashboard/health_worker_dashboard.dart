import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
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
    final user = authState.user;

    final String workerName = user?.name.isNotEmpty == true ? user!.name : 'Health Worker';

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
                // 1. Header: Branding & Greeting + Worker Avatar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_enhance_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Drishti Intake',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Good Morning,',
                                  style: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -1.2,
                                    height: 1.08,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$workerName!',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: -1.2,
                                    height: 1.08,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Worker Profile Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              border: Border.all(color: AppColors.border, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Container(
                                color: AppColors.primaryLight,
                                child: const Icon(
                                  Icons.medical_services_outlined,
                                  size: 26,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 2. Primary Action Buttons (Hero Centerpiece)
                      PillButton(
                        label: '+ New Screening / Patient Intake',
                        icon: Icons.camera_alt_rounded,
                        width: double.infinity,
                        height: 52,
                        onPressed: onStartScreening,
                      ),
                      const SizedBox(height: 10),
                      PillButton(
                        label: 'View Screening Records',
                        icon: Icons.folder_open_rounded,
                        variant: PillButtonVariant.secondaryOutlined,
                        width: double.infinity,
                        height: 46,
                        onPressed: onViewCases,
                      ),

                      const SizedBox(height: 16),

                      // 3. Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: DiagnoXStatCard(
                              icon: Icons.task_alt_rounded,
                              category: 'Today',
                              value: '${reviewState.totalScreenedCount}',
                              subtitle: 'Patients screened',
                              iconColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DiagnoXStatCard(
                              icon: Icons.sync_rounded,
                              category: 'Sync Status',
                              value: syncState.isOnline ? 'Online' : 'Offline',
                              subtitle: '${syncState.pendingCount} pending upload',
                              iconColor: syncState.isOnline ? AppColors.statusGood : AppColors.badgeModerateText,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // 4. "Recent Screenings" Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Screenings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          InkWell(
                            onTap: onViewCases,
                            borderRadius: BorderRadius.circular(6),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Text(
                                'View All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
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
                          child: const Center(
                            child: Text(
                              'No recent screenings recorded yet today.',
                              style: TextStyle(
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

                      const SizedBox(height: 16),
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
        ? 'High'
        : isLowRisk
            ? 'Low'
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
