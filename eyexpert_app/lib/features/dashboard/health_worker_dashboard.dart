import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
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

    final totalCases = reviewState.totalScreenedCount;
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
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.deepSpace,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderDark, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 12,
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
                                        'Welcome, ${authState.user?.name ?? "Health Worker"}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Field Screening Command Center • ${authState.user?.organization ?? "PHC-RAMGARH-01"}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.darkTextSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.obsidian,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.hudCyan.withValues(alpha: 0.5)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.memory_rounded, size: 13, color: AppColors.hudCyan),
                                      SizedBox(width: 5),
                                      Text(
                                        'ResNet-18 Engine',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.hudCyan,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Workstation System Status Strip
                            Wrap(
                              spacing: 14,
                              runSpacing: 8,
                              children: [
                                _statusIndicator(Icons.cloud_done_rounded, 'Cloud Sync Active', AppColors.statusGood),
                                _statusIndicator(Icons.security_rounded, 'PyTorch Inference Online', AppColors.electricBlue),
                                _statusIndicator(Icons.verified_user_outlined, 'ISO 13485 Verified', AppColors.hudCyan),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. PRIMARY SCREENING INITIATION ACTION (Hero CTA)
                      InkWell(
                        onTap: onStartScreening,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.40),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'START NEW SCREENING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Capture fundus image & begin AI-assisted optical screening',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. CLINICAL TRIAGE KPI STRIP
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.deepSpace,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TODAY\'S SCREENING SUMMARY',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkTextSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                InkWell(
                                  onTap: onViewCases,
                                  child: const Text(
                                    'View All Cases →',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.hudCyan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 400) {
                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          _triageMetric('SCREENED', '$totalCases', Colors.white),
                                          _triageDivider(),
                                          _triageMetric('REFERABLE', '$referableCases', AppColors.referableAlert),
                                        ],
                                      ),
                                      const Divider(height: 20, color: AppColors.borderDark),
                                      Row(
                                        children: [
                                          _triageMetric('PENDING REVIEW', '$pendingCases', AppColors.pending),
                                          _triageDivider(),
                                          _triageMetric('COMPLETED', '${reviewState.completedCount}', AppColors.statusGood),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    _triageMetric('TOTAL SCREENED', '$totalCases', Colors.white),
                                    _triageDivider(),
                                    _triageMetric('REFERABLE', '$referableCases', AppColors.referableAlert),
                                    _triageDivider(),
                                    _triageMetric('PENDING REVIEW', '$pendingCases', AppColors.pending),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. SCREENING ACTIVITY FEED
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SCREENING ACTIVITY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                          TextButton(
                            onPressed: onViewCases,
                            child: const Text('Open Review Queue', style: TextStyle(fontSize: 12, color: AppColors.electricBlue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.deepSpace,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderDark),
                        ),
                        child: reviewState.cases.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(28),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.visibility_outlined, size: 32, color: AppColors.darkTextMuted),
                                      SizedBox(height: 8),
                                      Text(
                                        'No recent screening sessions recorded yet.',
                                        style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: reviewState.cases.take(5).length,
                                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderDark),
                                itemBuilder: (context, index) {
                                  final c = reviewState.cases[index];
                                  final pred = c.prediction;
                                  final isReferable = c.isReferable;
                                  final isUngradable = c.quality?.isUngradable ?? false;

                                  final subtitleText = isUngradable
                                      ? 'Image Ungradable • Recapture Required'
                                      : pred != null
                                          ? 'Level ${pred.drLevel} (${pred.severityLabel}) • ${(pred.modelProbability * 100).toStringAsFixed(1)}%'
                                          : c.status == ScreeningStatus.awaitingImage
                                              ? 'Awaiting retinal image'
                                              : 'Screening registered';

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    leading: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isUngradable
                                            ? AppColors.statusUngradableDarkBg
                                            : isReferable
                                                ? AppColors.referableDarkBg
                                                : AppColors.statusGoodDarkBg,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isUngradable
                                              ? AppColors.statusUngradable.withValues(alpha: 0.5)
                                              : isReferable
                                                  ? AppColors.referableAlert.withValues(alpha: 0.5)
                                                  : AppColors.statusGood.withValues(alpha: 0.5),
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
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(
                                          c.patient.patientId,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${c.patient.eye})',
                                          style: const TextStyle(fontSize: 11.5, color: AppColors.darkTextSecondary, fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    subtitle: Text(
                                      subtitleText,
                                      style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted),
                                    ),
                                    trailing: isUngradable
                                        ? StatusBadge.ungradable()
                                        : isReferable
                                            ? StatusBadge.referable(label: 'REFER')
                                            : c.hasReviewed
                                                ? StatusBadge.good(label: 'VALIDATED')
                                                : StatusBadge.pending(label: 'NORMAL'),
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

  Widget _statusIndicator(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _triageMetric(String label, String count, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            count,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  Widget _triageDivider() {
    return Container(
      height: 32,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.lightBorder,
    );
  }
}
