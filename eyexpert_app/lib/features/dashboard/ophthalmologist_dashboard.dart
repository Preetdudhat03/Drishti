import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/pill_button.dart';
import '../../shared/widgets/diagnox_stat_card.dart';
import '../../data/models/screening_case_model.dart';
import '../review/review_queue_provider.dart';
import '../auth/auth_provider.dart';

class OphthalmologistDashboard extends ConsumerStatefulWidget {
  final VoidCallback onOpenReviewQueue;
  final VoidCallback onViewCases;
  final VoidCallback onViewSystemStatus;
  final ValueChanged<ScreeningCaseModel>? onSelectCase;
  final ValueChanged<ScreeningCaseModel>? onReviewCase;
  final ValueChanged<ScreeningCaseModel>? onViewReport;
  final ValueChanged<String>? onOpenQueueWithFilter;

  const OphthalmologistDashboard({
    super.key,
    required this.onOpenReviewQueue,
    required this.onViewCases,
    required this.onViewSystemStatus,
    this.onSelectCase,
    this.onReviewCase,
    this.onViewReport,
    this.onOpenQueueWithFilter,
  });

  @override
  ConsumerState<OphthalmologistDashboard> createState() => _OphthalmologistDashboardState();
}

class _OphthalmologistDashboardState extends ConsumerState<OphthalmologistDashboard> {
  String _activeFilter = 'ALL'; // 'ALL', 'PENDING', 'REFERABLE', 'COMPLETED'

  String _getGreeting(String Function(String) tr) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return tr('greeting_morning');
    } else if (hour >= 12 && hour < 17) {
      return tr('greeting_afternoon');
    } else {
      return tr('greeting_evening');
    }
  }

  void _handleCaseAction(ScreeningCaseModel c) {
    if (c.hasReviewed) {
      if (widget.onViewReport != null) {
        widget.onViewReport!(c);
      } else if (widget.onSelectCase != null) {
        widget.onSelectCase!(c);
      }
    } else {
      if (widget.onReviewCase != null) {
        widget.onReviewCase!(c);
      } else if (widget.onSelectCase != null) {
        widget.onSelectCase!(c);
      }
    }
  }

  void _handleReviewNextCase(List<ScreeningCaseModel> pendingCases) {
    if (pendingCases.isEmpty) {
      if (widget.onOpenQueueWithFilter != null) {
        widget.onOpenQueueWithFilter!('PENDING');
      } else {
        widget.onOpenReviewQueue();
      }
      return;
    }

    // Prioritize high-risk / referable case first, otherwise take the first pending
    final urgentCase = pendingCases.where((c) => c.isReferable).firstOrNull;
    final nextCase = urgentCase ?? pendingCases.first;

    if (widget.onReviewCase != null) {
      widget.onReviewCase!(nextCase);
    } else if (widget.onSelectCase != null) {
      widget.onSelectCase!(nextCase);
    } else {
      widget.onOpenReviewQueue();
    }
  }

  List<ScreeningCaseModel> _getFilteredCases(List<ScreeningCaseModel> allCases) {
    if (_activeFilter == 'REFERABLE') {
      return allCases.where((c) => c.isReferable).toList();
    } else if (_activeFilter == 'PENDING') {
      return allCases.where((c) => c.isPendingReview).toList();
    } else if (_activeFilter == 'COMPLETED') {
      return allCases.where((c) => c.hasReviewed).toList();
    }
    return allCases;
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewQueueProvider);
    final authState = ref.watch(authProvider);
    final tr = ref.watch(trProvider);
    final user = authState.user;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 650;
    final isTablet = screenWidth >= 650 && screenWidth < 1100;
    final isDesktop = screenWidth >= 1100;
    final isSmallMobile = screenWidth < 380;
    final useTableView = screenWidth >= 740;

    final allCases = reviewState.cases;
    final pendingCases = allCases.where((c) => c.isPendingReview).toList();
    final urgentCases = allCases.where((c) => c.isReferable).toList();
    final completedCases = allCases.where((c) => c.hasReviewed).toList();

    final displayedCases = _getFilteredCases(allCases);
    final String doctorName = user?.name.isNotEmpty == true ? user!.name : 'Dr. Smith';

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(reviewQueueProvider.notifier).loadPendingReviews();
      },
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          isMobile ? 12.0 : 20.0,
          ResponsiveLayout.topBarClearance(context),
          isMobile ? 12.0 : 20.0,
          ResponsiveLayout.bottomBarClearance(context),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1200 : (isTablet ? 960 : double.infinity),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),

                // 1. Header: Branding & Greeting + Doctor Profile
                _buildHeaderCard(context, user, doctorName, tr, isMobile, isSmallMobile),

                const SizedBox(height: 16),

                // 2. Primary Clinical Action Bar (Responsive)
                _buildActionButtons(context, pendingCases, screenWidth),

                const SizedBox(height: 20),

                // 3. Review Queue Priority Triage Stat Strip (Responsive Grid)
                _buildTriageStats(context, reviewState, pendingCases, urgentCases, completedCases, tr, screenWidth),

                const SizedBox(height: 24),

                // 4. Clinical Cases Section Header & Local Filter Tabs
                _buildCasesSectionHeader(context, allCases, pendingCases, urgentCases, completedCases, tr, isMobile),

                const SizedBox(height: 14),

                // 5. Clinical Cases Display (Responsive Table on Wide Screens, Cards on Mobile/Narrow Screens)
                if (displayedCases.isEmpty)
                  _buildEmptyState(tr)
                else if (useTableView)
                  _buildResponsiveTable(displayedCases, tr)
                else
                  _buildMobileCasesList(displayedCases, tr),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. Header Card (Fully Responsive for All Screen Sizes)
  // =========================================================================
  Widget _buildHeaderCard(
    BuildContext context,
    dynamic user,
    String doctorName,
    String Function(String) tr,
    bool isMobile,
    bool isSmallMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 14 : (isMobile ? 16 : 20)),
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
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildDoctorAvatar(size: isSmallMobile ? 44 : 50),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_getGreeting(tr)}, ',
                                style: TextStyle(
                                  fontSize: isSmallMobile ? 13 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  doctorName,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: isSmallMobile ? 15 : 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${user?.facilityId ?? "FAC-DISTRICT-EYE"} • ${user?.organization ?? "District Eye Hospital"}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isSmallMobile ? 11 : 11.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildStatusPill(
                      label: 'Ophthalmology Specialist',
                      color: AppColors.primary,
                      bg: AppColors.primaryLight,
                      icon: Icons.verified_user_rounded,
                    ),
                    _buildStatusPill(
                      label: 'Cloud Sync Live',
                      color: const Color(0xFF16A34A),
                      bg: const Color(0xFFDCFCE7),
                      icon: Icons.cloud_done_rounded,
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                _buildDoctorAvatar(size: 52),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${_getGreeting(tr)}, ',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              doctorName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _buildStatusPill(
                            label: 'Specialist On-Duty',
                            color: AppColors.primary,
                            bg: AppColors.primaryLight,
                            icon: Icons.verified_user_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.facilityId ?? "FAC-DISTRICT-EYE"} • ${user?.organization ?? "District Eye Hospital"}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusPill(
                  label: 'Supabase Cloud Synced',
                  color: const Color(0xFF16A34A),
                  bg: const Color(0xFFDCFCE7),
                  icon: Icons.cloud_done_rounded,
                ),
              ],
            ),
    );
  }

  Widget _buildDoctorAvatar({double size = 52}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE0F2FE),
        border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3), width: 2),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.54,
        color: const Color(0xFF0284C7),
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color color,
    required Color bg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. Primary Clinical Action Buttons (Responsive)
  // =========================================================================
  Widget _buildActionButtons(
    BuildContext context,
    List<ScreeningCaseModel> pendingCases,
    double screenWidth,
  ) {
    final tr = ref.watch(trProvider);
    final String nextCaseLabel = '${tr('review_next_case')} (${pendingCases.length} ${tr('stat_pending')})';

    if (screenWidth >= 920) {
      return Row(
        children: [
          Expanded(
            flex: 5,
            child: PillButton(
              label: nextCaseLabel,
              icon: Icons.assignment_turned_in_rounded,
              height: 50,
              onPressed: () => _handleReviewNextCase(pendingCases),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: PillButton(
              label: 'Review Queue (${pendingCases.length})',
              icon: Icons.checklist_rtl_rounded,
              variant: PillButtonVariant.secondaryOutlined,
              height: 50,
              onPressed: () {
                if (widget.onOpenQueueWithFilter != null) {
                  widget.onOpenQueueWithFilter!('PENDING');
                } else {
                  widget.onOpenReviewQueue();
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: PillButton(
              label: 'Reports Archive',
              icon: Icons.description_outlined,
              variant: PillButtonVariant.secondaryOutlined,
              height: 50,
              onPressed: () {
                if (widget.onOpenQueueWithFilter != null) {
                  widget.onOpenQueueWithFilter!('COMPLETED');
                } else {
                  widget.onViewCases();
                }
              },
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        PillButton(
          label: nextCaseLabel,
          icon: Icons.assignment_turned_in_rounded,
          width: double.infinity,
          height: 52,
          onPressed: () => _handleReviewNextCase(pendingCases),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Queue (${pendingCases.length})',
                icon: Icons.checklist_rtl_rounded,
                variant: PillButtonVariant.secondaryOutlined,
                height: 46,
                onPressed: () {
                  if (widget.onOpenQueueWithFilter != null) {
                    widget.onOpenQueueWithFilter!('PENDING');
                  } else {
                    widget.onOpenReviewQueue();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PillButton(
                label: 'Reports Archive',
                icon: Icons.description_outlined,
                variant: PillButtonVariant.secondaryOutlined,
                height: 46,
                onPressed: () {
                  if (widget.onOpenQueueWithFilter != null) {
                    widget.onOpenQueueWithFilter!('COMPLETED');
                  } else {
                    widget.onViewCases();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // 3. Triage Stat Cards (Interactive, Tap to Filter)
  // =========================================================================
  Widget _buildTriageStats(
    BuildContext context,
    ReviewQueueState reviewState,
    List<ScreeningCaseModel> pendingCases,
    List<ScreeningCaseModel> urgentCases,
    List<ScreeningCaseModel> completedCases,
    String Function(String) tr,
    double screenWidth,
  ) {
    final urgentCard = InkWell(
      onTap: () => setState(() => _activeFilter = 'REFERABLE'),
      borderRadius: BorderRadius.circular(20),
      child: DiagnoXStatCard(
        icon: Icons.warning_rounded,
        category: tr('urgent_referrals'),
        value: '${reviewState.pendingReferableCount}',
        subtitle: 'P(L>=2) >= 30% • Filter',
        iconColor: AppColors.statusCritical,
      ),
    );

    final pendingCard = InkWell(
      onTap: () => setState(() => _activeFilter = 'PENDING'),
      borderRadius: BorderRadius.circular(20),
      child: DiagnoXStatCard(
        icon: Icons.hourglass_top_rounded,
        category: 'Pending Sign-Off',
        value: '${reviewState.totalPendingCount}',
        subtitle: 'Awaiting doctor • Filter',
        iconColor: const Color(0xFFD97706),
      ),
    );

    final completedCard = InkWell(
      onTap: () => setState(() => _activeFilter = 'COMPLETED'),
      borderRadius: BorderRadius.circular(20),
      child: DiagnoXStatCard(
        icon: Icons.check_circle_outline_rounded,
        category: tr('stat_completed'),
        value: '${reviewState.completedCount}',
        subtitle: '${tr('specialist_validated')} • Filter',
        iconColor: AppColors.statusGood,
      ),
    );

    final totalCard = InkWell(
      onTap: () => setState(() => _activeFilter = 'ALL'),
      borderRadius: BorderRadius.circular(20),
      child: DiagnoXStatCard(
        icon: Icons.folder_shared_outlined,
        category: 'Total Screened',
        value: '${reviewState.totalScreenedCount}',
        subtitle: 'All cases • Filter',
        iconColor: AppColors.primary,
      ),
    );

    if (screenWidth >= 1040) {
      return Row(
        children: [
          Expanded(child: urgentCard),
          const SizedBox(width: 12),
          Expanded(child: pendingCard),
          const SizedBox(width: 12),
          Expanded(child: completedCard),
          const SizedBox(width: 12),
          Expanded(child: totalCard),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: urgentCard),
            const SizedBox(width: 10),
            Expanded(child: pendingCard),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: completedCard),
            const SizedBox(width: 10),
            Expanded(child: totalCard),
          ],
        ),
      ],
    );
  }

  // =========================================================================
  // 4. Cases Section Header & Filter Pills
  // =========================================================================
  Widget _buildCasesSectionHeader(
    BuildContext context,
    List<ScreeningCaseModel> allCases,
    List<ScreeningCaseModel> pendingCases,
    List<ScreeningCaseModel> urgentCases,
    List<ScreeningCaseModel> completedCases,
    String Function(String) tr,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('recent_cases'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tele-ophthalmology triage & patient screening records',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 11.5 : 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () {
                if (widget.onOpenQueueWithFilter != null) {
                  widget.onOpenQueueWithFilter!(_activeFilter);
                } else {
                  widget.onViewCases();
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tr('view_all'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Quick Filter Tabs Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _filterTabPill('All Cases (${allCases.length})', 'ALL'),
              const SizedBox(width: 8),
              _filterTabPill('Pending Queue (${pendingCases.length})', 'PENDING'),
              const SizedBox(width: 8),
              _filterTabPill('Urgent Referrals (${urgentCases.length})', 'REFERABLE'),
              const SizedBox(width: 8),
              _filterTabPill('Reports Archive (${completedCases.length})', 'COMPLETED'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filterTabPill(String label, String value) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 5. Desktop / Tablet Responsive Table View (Fills 100% Width Gracefully)
  // =========================================================================
  Widget _buildResponsiveTable(List<ScreeningCaseModel> cases, String Function(String) tr) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 720),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Table Header
                  Container(
                    color: const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 170,
                          child: Text(
                            'PATIENT',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'EYE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Text(
                            'AI DR GRADE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'CONFIDENCE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'RISK TRIAGE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            'STATUS',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            'ACTION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),

                  // Table Rows
                  for (int i = 0; i < cases.take(10).length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    _buildTableRow(cases[i], tr),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(ScreeningCaseModel c, String Function(String) tr) {
    final pred = c.prediction;
    final isHighRisk = c.isReferable || (pred != null && pred.drLevel >= 3);
    final isLowRisk = pred?.drLevel == 0 || pred?.drLevel == 1;

    final String patientDisplayName = c.patient.patientId.startsWith('PT-')
        ? c.patient.patientId
        : '${tr('patient_prefix')} #${c.patient.patientId}';
    final String eyeSide = AppFormatters.formatEye(c.patient.eye);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleCaseAction(c),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // 1. Patient
              SizedBox(
                width: 170,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        patientDisplayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patientDisplayName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${c.patient.age ?? 42}y • ${c.patient.gender ?? "Male"}',
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Eye
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      eyeSide,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ),
              ),

              // 3. AI DR Grade
              SizedBox(
                width: 180,
                child: Text(
                  pred != null ? tr('level_${pred.drLevel}') : tr('awaiting_ai_grading'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // 4. Confidence
              SizedBox(
                width: 100,
                child: Text(
                  pred != null ? '${(pred.modelProbability * 100).toStringAsFixed(0)}%' : '—',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              // 5. Risk Triage Badge
              SizedBox(
                width: 100,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildRiskBadge(isHighRisk, isLowRisk, tr),
                ),
              ),

              // 6. Status Badge
              SizedBox(
                width: 110,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.hasReviewed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: c.hasReviewed
                            ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      c.hasReviewed ? 'Validated' : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c.hasReviewed ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ),
              ),

              // 7. Dedicated Action Button
              SizedBox(
                width: 110,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: () => _handleCaseAction(c),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: c.isPendingReview ? AppColors.primary : const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.isPendingReview ? Icons.rate_review_rounded : Icons.description_outlined,
                            size: 13,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            c.isPendingReview ? 'Review' : 'Report',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 6. Mobile Responsive Cards List
  // =========================================================================
  Widget _buildMobileCasesList(List<ScreeningCaseModel> cases, String Function(String) tr) {
    return Column(
      children: [
        for (int index = 0; index < cases.take(8).length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _buildMobileCaseCard(cases[index], tr),
        ],
      ],
    );
  }

  Widget _buildMobileCaseCard(ScreeningCaseModel c, String Function(String) tr) {
    final pred = c.prediction;
    final isHighRisk = c.isReferable || (pred != null && pred.drLevel >= 3);
    final isLowRisk = pred?.drLevel == 0 || pred?.drLevel == 1;

    final String patientDisplayName = c.patient.patientId.startsWith('PT-')
        ? c.patient.patientId
        : '${tr('patient_prefix')} #${c.patient.patientId}';
    final String eyeSide = AppFormatters.formatEye(c.patient.eye);
    final String conditionLabel = pred != null
        ? '${tr('level_${pred.drLevel}')} ($eyeSide)'
        : tr('awaiting_ai_grading');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleCaseAction(c),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Patient Info + Risk Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              patientDisplayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patientDisplayName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${c.patient.age ?? 42}y • ${c.patient.gender ?? "Male"} • $eyeSide',
                                  style: const TextStyle(
                                    fontSize: 11,
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
                    _buildRiskBadge(isHighRisk, isLowRisk, tr),
                  ],
                ),
                const SizedBox(height: 10),

                // Diagnosis & Status Line
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          conditionLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (pred != null)
                        Text(
                          '${(pred.modelProbability * 100).toStringAsFixed(0)}% conf',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Dedicated Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.hasReviewed ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        c.hasReviewed ? '✓ Validated' : '⏱ Pending Review',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: c.hasReviewed ? const Color(0xFF16A34A) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _handleCaseAction(c),
                      icon: Icon(
                        c.isPendingReview ? Icons.rate_review_rounded : Icons.description_outlined,
                        size: 13,
                      ),
                      label: Text(
                        c.isPendingReview ? 'Review & Sign' : 'View Report',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.isPendingReview ? AppColors.primary : const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRiskBadge(bool isHighRisk, bool isLowRisk, String Function(String) tr) {
    final String riskBadgeText = isHighRisk
        ? tr('risk_badge_high')
        : isLowRisk
            ? tr('risk_badge_low')
            : tr('risk_badge_mod');

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
    );
  }

  // =========================================================================
  // 7. Empty State
  // =========================================================================
  Widget _buildEmptyState(String Function(String) tr) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.folder_open_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 10),
            Text(
              _activeFilter == 'ALL'
                  ? tr('no_pending_cases')
                  : 'No cases found matching filter "${_activeFilter.toLowerCase()}".',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: () => setState(() => _activeFilter = 'ALL'),
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Show All Cases', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
