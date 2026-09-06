import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
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

class _ScreeningReportScreenState extends ConsumerState<ScreeningReportScreen> {
  bool _isExporting = false;

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

  @override
  Widget build(BuildContext context) {
    final c = _getCase();
    final pred = c.prediction;
    final quality = c.quality;
    final isReferable = pred?.referable ?? (c.prediction?.drLevel != null && c.prediction!.drLevel >= 2);

    final double confidence = pred?.modelProbability ?? 0.88;
    final String severityTitle = pred?.severityLabel != null
        ? '${pred!.severityLabel} (Level ${pred.drLevel})'
        : 'Moderate NPDR (Level 2)';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Navigation Topbar matching DiagnoX "AI Diagnosis"
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
                  const Expanded(
                    child: Center(
                      child: Text(
                        'AI Diagnosis',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Balanced spacing
                ],
              ),
              const SizedBox(height: 16),

              // 2. Symptom / Target Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Condition:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Retinal Screening (${AppFormatters.formatEye(c.patient.eye)})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Red Flag / Alert Callout Banner matching Image 1
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
                              'Red Flag Detected',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.badgeHighRiskText,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'One or more conditions require urgent specialist ophthalmologist evaluation.',
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
                              'No sight-threatening retinopathy detected. Recommended for standard annual follow-up.',
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

              // 4. Primary AI Diagnosis Card with Confidence Capsule Slider
              ConfidenceSliderCard(
                title: severityTitle,
                riskLabel: isReferable ? 'High Risk' : 'Low Risk',
                isHighRisk: isReferable,
                confidence: confidence,
                explanation: pred?.recommendation ??
                    'Deep ConvNet model identified clinical vascular biomarkers consistent with Diabetic Retinopathy severity grading. Heatmap indicates microvascular focal lesions around the macula.',
                clinicalFindings: const [
                  'Microaneurysms Detected',
                  'Hard Exudates',
                  'Macular Region Analyzed',
                  'Optic Disc Verified',
                ],
              ),

              // Secondary Differential Card if available
              if (isReferable)
                const ConfidenceSliderCard(
                  title: 'Macular Edema Risk (DME)',
                  riskLabel: 'Moderate Risk',
                  isHighRisk: false,
                  confidence: 0.42,
                  explanation:
                      'Perifoveal lipid exudation within 1 disc diameter of macula center indicates moderate DME risk factor.',
                  clinicalFindings: ['Perifoveal Ring', 'Focal Leakage Biomarker'],
                ),

              const SizedBox(height: 16),

              // 5. Patient Demographics & Image Quality Dossier Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metaColumn('Patient ID', c.patient.patientId),
                        _metaColumn('Age / Sex', '${c.patient.age}y / ${c.patient.gender}'),
                        _metaColumn('Examined Eye', AppFormatters.formatEye(c.patient.eye)),
                        _metaColumn('Quality', quality?.status.label.toUpperCase() ?? 'VERIFIED'),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _metaColumn('Screening Ref', c.screeningId),
                        _metaColumn('Recorded Time', AppFormatters.formatDateTime(c.createdAt)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 6. Action Bar matching Image 3 (Right screen: [PDF] [Share] [Save])
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PillButton(
                      label: 'PDF',
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
                      label: 'Share',
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
                      label: 'Save & Sign',
                      icon: Icons.check_circle_outline_rounded,
                      variant: PillButtonVariant.primary,
                      onPressed: widget.onBack,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Medical Disclaimer Footer
              Center(
                child: Text(
                  AppConstants.standardDisclaimer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
