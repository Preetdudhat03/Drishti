import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/diagnox_stat_card.dart';
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

    final pendingCases = reviewState.cases.where((c) => c.isPendingReview).toList();
    final completedCases = reviewState.cases.where((c) => c.hasReviewed).toList();

    final String doctorName = user?.name.isNotEmpty == true ? user!.name : 'Dr. Smith';

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reviewQueueProvider.notifier).loadPendingReviews();
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
                // 1. Header: Branding & Greeting + Doctor Avatar
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
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove_red_eye_rounded,
                                  size: 15,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'DiagnoX',
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
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.8,
                              height: 1.12,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$doctorName!',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.8,
                              height: 1.12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Doctor Profile Avatar
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
                          color: const Color(0xFFE0F2FE),
                          child: const Icon(
                            Icons.person,
                            size: 28,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 2. Primary Action Buttons
                PillButton(
                  label: '+ Review Next Priority Case (${pendingCases.length})',
                  width: double.infinity,
                  height: 54,
                  onPressed: () {
                    if (onSelectCase != null && pendingCases.isNotEmpty) {
                      onSelectCase!(pendingCases.first);
                    } else {
                      onOpenReviewQueue();
                    }
                  },
                ),
                const SizedBox(height: 12),
                PillButton(
                  label: 'Manage Patients & Cases',
                  icon: Icons.people_outline_rounded,
                  variant: PillButtonVariant.secondaryOutlined,
                  width: double.infinity,
                  height: 48,
                  onPressed: onViewCases,
                ),

                const SizedBox(height: 22),

                // 3. Stats Metric Row (Side-by-Side Cards)
                Row(
                  children: [
                    Expanded(
                      child: DiagnoXStatCard(
                        icon: Icons.show_chart_rounded,
                        category: 'Today',
                        value: (pendingCases.length + completedCases.length).toString(),
                        subtitle: 'Cases diagnosed',
                        iconColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DiagnoXStatCard(
                        icon: Icons.access_time_rounded,
                        category: 'Avg Time',
                        value: '49s',
                        subtitle: 'Per diagnosis',
                        iconColor: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // 4. "Recent Cases" Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Cases',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: onOpenReviewQueue,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Case Cards List
                if (pendingCases.isEmpty && completedCases.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text(
                        'No pending cases awaiting diagnosis.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  for (int index = 0; index < reviewState.cases.take(6).length; index++) ...[
                    if (index > 0) const SizedBox(height: 10),
                    _buildRecentCaseCard(
                      reviewState.cases[index],
                      onSelectCase: onSelectCase,
                      onOpenReviewQueue: onOpenReviewQueue,
                    ),
                  ],

                const SizedBox(height: 24),

                // Center Floating Diagnostic Launcher Button
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E293B),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: onOpenReviewQueue,
                      icon: const Icon(
                        Icons.dashboard_customize_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
