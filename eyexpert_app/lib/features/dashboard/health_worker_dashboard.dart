import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/offline_status_bar.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../review/review_queue_provider.dart';
import '../offline/sync_queue_provider.dart';
import '../screening/screening_session_provider.dart';
import '../screening/patient_intake_screen.dart';
import '../queue/case_queue_screen.dart';

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
    final isTabletOrDesktop = !ResponsiveLayout.isMobile(context);

    return Column(
      children: [
        OfflineStatusBar(
          isOffline: !syncState.isOnline,
          pendingCount: syncState.pendingCount,
          onSyncPressed: () => ref.read(syncQueueProvider.notifier).syncNow(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome / Shift Banner
                ClinicalCard(
                  backgroundColor: AppColors.primary.withOpacity(0.04),
                  borderColor: AppColors.primary.withOpacity(0.2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Field Screening Active • PHC Ramgarh',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Portable Handheld Fundus Camera v2 Connected',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: onStartScreening,
                        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                        label: const Text('NEW SCREENING'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Metrics Grid (2x2 on phone, 4x1 on tablet/desktop)
                GridView.count(
                  crossAxisCount: isTabletOrDesktop ? 4 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isTabletOrDesktop ? 1.25 : 1.2,
                  children: [
                    _metricCard(
                      title: "Today's Screenings",
                      value: '28',
                      subtitle: 'Active screening shift',
                      icon: Icons.assignment_turned_in_outlined,
                      color: AppColors.primary,
                    ),
                    _metricCard(
                      title: 'Pending Review',
                      value: '${reviewState.totalPendingCount}',
                      subtitle: 'Awaiting clinician',
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.secondary,
                    ),
                    _metricCard(
                      title: 'Recapture Required',
                      value: '3',
                      subtitle: 'Ungradable / blur',
                      icon: Icons.replay_circle_filled_rounded,
                      color: AppColors.statusUngradable,
                    ),
                    _metricCard(
                      title: 'Referable Cases',
                      value: '${reviewState.pendingReferableCount}',
                      subtitle: 'Level >= 2 (Urgent)',
                      icon: Icons.notification_important_rounded,
                      color: AppColors.referableAlert,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        text: 'Start New Screening',
                        icon: Icons.camera_alt_outlined,
                        onPressed: onStartScreening,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        text: 'View Pending Cases',
                        icon: Icons.folder_open_rounded,
                        isSecondary: true,
                        onPressed: onViewCases,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Recent Cases Card
                ClinicalCard(
                  title: 'Recent Screening Sessions',
                  titleAction: TextButton(
                    onPressed: onViewCases,
                    child: const Text('View All Cases'),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reviewState.cases.take(4).length,
                    separatorBuilder: (_, __) => const Divider(height: 12),
                    itemBuilder: (context, index) {
                      final c = reviewState.cases[index];
                      final pred = c.prediction;
                      final isReferable = pred?.referable ?? false;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: c.quality?.isUngradable ?? false
                              ? AppColors.statusUngradableBg
                              : isReferable
                                  ? AppColors.referableAlertBg
                                  : AppColors.statusGoodBg,
                          child: Icon(
                            c.quality?.isUngradable ?? false
                                ? Icons.warning_amber_rounded
                                : isReferable
                                    ? Icons.notification_important_rounded
                                    : Icons.check_circle_outline,
                            color: c.quality?.isUngradable ?? false
                                ? AppColors.statusUngradable
                                : isReferable
                                    ? AppColors.referableAlert
                                    : AppColors.statusGood,
                            size: 20,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              c.patient.patientId,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${c.patient.eye})',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          c.quality?.isUngradable ?? false
                              ? 'Quality: UNGRADABLE • Recapture Required'
                              : 'AI: Level ${pred?.drLevel} (${pred?.severityLabel}) • Prob: ${(pred?.modelProbability ?? 0) * 100}%',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: StatusBadge(
                          label: c.quality?.isUngradable ?? false
                              ? 'UNGRADABLE'
                              : isReferable
                                  ? 'REFERABLE'
                                  : 'NON-REFERABLE',
                          color: c.quality?.isUngradable ?? false
                              ? AppColors.statusUngradable
                              : isReferable
                                  ? AppColors.referableAlert
                                  : AppColors.statusGood,
                          backgroundColor: c.quality?.isUngradable ?? false
                              ? AppColors.statusUngradableBg
                              : isReferable
                                  ? AppColors.referableAlertBg
                                  : AppColors.statusGoodBg,
                          icon: isReferable ? Icons.priority_high_rounded : Icons.check,
                        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 16, color: color),
            ],
          ),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
