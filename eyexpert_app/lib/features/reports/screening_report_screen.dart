import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/localization/locale_provider.dart';
import '../../data/models/screening_case_model.dart';
import '../../data/models/patient_model.dart';
import '../../data/services/report_service.dart';
import '../../shared/widgets/confidence_slider_card.dart';
import '../../shared/widgets/pill_button.dart';
import '../screening/screening_session_provider.dart';

class ScreeningReportScreen extends ConsumerStatefulWidget {
  final ScreeningCaseModel? screeningCase;
  final VoidCallback onBack;

  const ScreeningReportScreen({
    super.key,
    this.screeningCase,
    required this.onBack,
  });

  @override
  ConsumerState<ScreeningReportScreen> createState() => _ScreeningReportScreenState();
}

class _ScreeningReportScreenState extends ConsumerState<ScreeningReportScreen> with SingleTickerProviderStateMixin {
  bool _isExporting = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ScreeningCaseModel _getCase() {
    if (widget.screeningCase != null) {
      return widget.screeningCase!;
    }
    final sessionCase = ref.read(screeningSessionProvider).toScreeningCase();
    if (sessionCase != null) return sessionCase;

    return ScreeningCaseModel(
      screeningId: 'EX-2026-000124',
      patient: PatientModel(
        patientId: 'PT-2026-8819',
        age: 54,
        gender: 'FEMALE',
        diabetesDurationYears: 8,
        eye: 'OD',
        facilityId: 'PHC-RAMGARH-01',
        createdAt: DateTime.now(),
      ),
      status: ScreeningStatus.readyForReview,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handlePrint() async {
    setState(() => _isExporting = true);
    try {
      final c = _getCase();
      await ReportService.printReport(c);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isExporting = true);
    try {
      final c = _getCase();
      await ReportService.shareReport(c);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildPatientReferralCard(ScreeningCaseModel c, bool isReferable, String Function(String) tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Slip Official Header
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.remove_red_eye_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('slip_title'),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tr('slip_subtitle'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: Color(0xFF334155), height: 1),
              const SizedBox(height: 12),

              // Patient Meta Row
              Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _slipMetaItem('Patient ID', c.patient.patientId, Colors.white),
                  _slipMetaItem('Age / Sex', '${c.patient.age}y / ${c.patient.gender}', Colors.white),
                  _slipMetaItem('Eye', AppFormatters.formatEye(c.patient.eye), Colors.white),
                  _slipMetaItem('Center', c.patient.facilityId.isNotEmpty ? c.patient.facilityId : 'PHC-RAMGARH-01', const Color(0xFF38BDF8)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Clinical Urgency Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isReferable ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isReferable ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isReferable ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isReferable ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isReferable ? tr('slip_urgency_urgent') : tr('slip_urgency_routine'),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isReferable ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isReferable
                              ? 'Level ${c.prediction?.drLevel ?? 2} Diabetic Retinopathy'
                              : 'Level 0 Normal Retinal Fundus',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isReferable ? const Color(0xFFB91C1C) : const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                ),
                child: Text(
                  isReferable ? tr('slip_advice_urgent') : tr('slip_advice_routine'),
                  style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Essential Lifestyle & Care Guidelines
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.health_and_safety_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    tr('slip_tips_title'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _adviceBullet(
                Icons.bloodtype_outlined,
                tr('slip_tip1_title'),
                tr('slip_tip1_desc'),
              ),
              _adviceBullet(
                Icons.speed_rounded,
                tr('slip_tip2_title'),
                tr('slip_tip2_desc'),
              ),
              _adviceBullet(
                Icons.restaurant_rounded,
                tr('slip_tip3_title'),
                tr('slip_tip3_desc'),
              ),
              _adviceBullet(
                Icons.visibility_outlined,
                tr('slip_tip4_title'),
                tr('slip_tip4_desc'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Tele-Ophthalmology Verification & QR Code Dossier
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              // Simulated QR Code Frame
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    size: 58,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('slip_verified_title'),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Token: ${c.screeningId}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tr('slip_footer_doc'),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    Text(
                      tr('slip_footer_notice'),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slipMetaItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: valueColor),
        ),
      ],
    );
  }

  Widget _adviceBullet(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _getCase();
    final pred = c.prediction;
    final quality = c.quality;
    final isReferable = pred?.referable ?? (c.prediction?.drLevel != null && c.prediction!.drLevel >= 2);
    final tr = ref.watch(trProvider);

    final double confidence = pred?.modelProbability ?? 0.88;
    final String severityTitle = pred?.severityLabel != null
        ? '${pred!.severityLabel} (Level ${pred.drLevel})'
        : 'Moderate NPDR (Level 2)';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Navigation Topbar
                  Row(
                    children: [
                      InkWell(
                        onTap: widget.onBack,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          tr('view_report'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 2. Tab selector: Patient Referral Slip vs Clinical Tele-Report
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: AppColors.textSecondary,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      tabs: [
                        Tab(text: tr('patient_slip_btn')),
                        const Tab(text: 'Clinical Tele-Dossier'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, _) {
                      if (_tabController.index == 0) {
                        return _buildPatientReferralCard(c, isReferable, tr);
                      }

                      // Tab 1: Detailed Clinical Tele-Report
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Red Flag / Alert Callout Banner
                          if (isReferable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.badgeHighRiskBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.badgeHighRiskBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColors.badgeHighRiskText,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Red Flag Detected — Referable Retinopathy',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.badgeHighRiskText,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Urgent specialist evaluation recommended to prevent permanent vision loss.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.badgeHighRiskText,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.badgeLowRiskBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.badgeLowRiskBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: AppColors.badgeLowRiskText,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Low Risk / Non-Referable',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.badgeLowRiskText,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'No sight-threatening retinopathy detected. Standard annual screening advised.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: AppColors.badgeLowRiskText,
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 14),

                          // Primary AI Diagnosis Card
                          ConfidenceSliderCard(
                            title: severityTitle,
                            riskLabel: isReferable ? 'High Risk' : 'Low Risk',
                            isHighRisk: isReferable,
                            confidence: confidence,
                            explanation: pred?.recommendation ??
                                'Deep ConvNet model identified vascular biomarkers consistent with Diabetic Retinopathy severity grading.',
                            clinicalFindings: const [
                              'Microaneurysms Detected',
                              'Hard Exudates Evaluated',
                              'Macular Region Analyzed',
                              'Optic Disc Verified',
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Patient Demographics & Quality Telemetry Card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PATIENT & OPTICAL TELEMETRY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: _metaColumn('Patient ID', c.patient.patientId)),
                                        Expanded(child: _metaColumn('Age / Sex', '${c.patient.age}y / ${c.patient.gender}')),
                                        Expanded(child: _metaColumn('Examined Eye', AppFormatters.formatEye(c.patient.eye))),
                                        Expanded(child: _metaColumn('Quality', quality?.status.label.toUpperCase() ?? 'VERIFIED')),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: _metaColumn('Screening Ref', c.screeningId)),
                                        Expanded(child: _metaColumn('Recorded Time', AppFormatters.formatDateTime(c.createdAt))),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons: PDF, Share WhatsApp, Done
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: PillButton(
                          label: tr('slip_print_btn'),
                          icon: Icons.download_rounded,
                          variant: PillButtonVariant.secondaryOutlined,
                          isLoading: _isExporting,
                          onPressed: _handlePrint,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: PillButton(
                          label: tr('slip_share_btn'),
                          icon: Icons.share_outlined,
                          variant: PillButtonVariant.secondaryOutlined,
                          isLoading: _isExporting,
                          onPressed: _handleShare,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: PillButton(
                          label: 'Done',
                          icon: Icons.check_circle_outline_rounded,
                          variant: PillButtonVariant.primary,
                          onPressed: widget.onBack,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      AppConstants.standardDisclaimer,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metaColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
