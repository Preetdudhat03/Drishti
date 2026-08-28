import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/screening_case_model.dart';
import '../../data/models/patient_model.dart';
import '../../data/services/report_service.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
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
    final review = c.review;
    final isReferable = pred?.isReferable ?? false;
    final severity = pred != null ? DRSeverity.fromLevel(pred.drLevel) : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 20,
            vertical: isCompact ? 12 : 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. TOP ACTION BAR
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'Screening Summary Report',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCompact) ...[
                        IconButton(
                          onPressed: _isExporting ? null : _handlePrint,
                          icon: const Icon(Icons.print_outlined, size: 20),
                          tooltip: 'Print Report',
                        ),
                        IconButton(
                          onPressed: _isExporting ? null : _handleShare,
                          icon: const Icon(Icons.download_rounded, size: 20, color: AppColors.electricBlue),
                          tooltip: 'Export PDF',
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: _isExporting ? null : _handlePrint,
                          icon: const Icon(Icons.print_outlined, size: 16),
                          label: const Text('Print Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.borderDark),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _isExporting ? null : _handleShare,
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('Export PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.electricBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. FORMAL CLINICAL REPORT DOCUMENT
                  Container(
                    padding: EdgeInsets.all(isCompact ? 16 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.lightBorder),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Document Header (Responsive Wrap)
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppConstants.appName.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const Text(
                                  'AI Retinal Screening & Tele-Ophthalmology Network',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: isCompact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Text('REPORT #${c.screeningId}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
                                Text('Generated: ${AppFormatters.formatTimestamp(DateTime.now())}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 10),

                        // Patient Demographic Strip
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.obsidian,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Wrap(
                            spacing: 20,
                            runSpacing: 8,
                            children: [
                              _docMeta('PATIENT ID', c.patient.patientId, Colors.white),
                              _docMeta('EXAMINATION EYE', '${c.patient.eye} (${c.patient.eye == "OD" ? "Right Eye" : "Left Eye"})', AppColors.hudCyan),
                              _docMeta('AGE / GENDER', '${c.patient.age ?? "--"}Y / ${c.patient.gender ?? "--"}', Colors.white),
                              _docMeta('OPTICAL QUALITY', quality != null ? '${AppFormatters.formatPercent(quality.overallScore)} (${quality.status.label})' : 'GOOD', AppColors.statusGood),
                              _docMeta('FACILITY', c.patient.facilityId.isNotEmpty ? c.patient.facilityId : 'PHC-RAMGARH-01', AppColors.darkTextSecondary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dual Retinal & Grad-CAM Inspection Viewports (Stacked on mobile, row on desktop)
                        if (isCompact) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'OPTICAL RETINAL FUNDUS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 6),
                              FundusImageViewer(
                                originalImagePath: c.imagePath ?? '',
                                mode: FundusViewerMode.original,
                                height: 200,
                                eyeTag: c.patient.eye,
                                showReticle: false,
                                showControls: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GRAD-CAM FEATURE ATTRIBUTION',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                              ),
                              const SizedBox(height: 6),
                              FundusImageViewer(
                                originalImagePath: c.imagePath ?? '',
                                gradcamImagePath: pred?.heatmapPath,
                                mode: pred?.heatmapPath != null ? FundusViewerMode.overlay : FundusViewerMode.original,
                                height: 200,
                                eyeTag: '${c.patient.eye} Grad-CAM',
                                showReticle: false,
                                showControls: false,
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'OPTICAL RETINAL FUNDUS',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                                    ),
                                    const SizedBox(height: 6),
                                    FundusImageViewer(
                                      originalImagePath: c.imagePath ?? '',
                                      mode: FundusViewerMode.original,
                                      height: 220,
                                      eyeTag: c.patient.eye,
                                      showReticle: false,
                                      showControls: false,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'GRAD-CAM FEATURE ATTRIBUTION',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                                    ),
                                    const SizedBox(height: 6),
                                    FundusImageViewer(
                                      originalImagePath: c.imagePath ?? '',
                                      gradcamImagePath: pred?.heatmapPath,
                                      mode: pred?.heatmapPath != null ? FundusViewerMode.overlay : FundusViewerMode.original,
                                      height: 220,
                                      eyeTag: '${c.patient.eye} Grad-CAM',
                                      showReticle: false,
                                      showControls: false,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Diagnostic Findings & Clinical Triage Box (Responsive Wrap)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isReferable ? AppColors.referableAlertBg : AppColors.statusGoodBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isReferable ? AppColors.referableAlert : AppColors.statusGood),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'DIAGNOSTIC CLASSIFICATION: LEVEL ${pred?.drLevel ?? 0}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    isReferable ? 'URGENT REFERRAL REQUIRED' : 'ROUTINE ANNUAL FOLLOW-UP',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                severity?.fullName ?? 'No Diabetic Retinopathy Detected',
                                style: TextStyle(
                                  fontSize: isCompact ? 16 : 18,
                                  fontWeight: FontWeight.w800,
                                  color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isReferable
                                    ? 'Automated screening detected high-attention microvascular anomalies indicative of diabetic retinopathy. Confirmatory dilated biomicroscopy by an ophthalmologist is recommended within 2 to 4 weeks.'
                                    : 'Automated screening detected no sight-threatening microvascular anomalies. Patient should maintain regular glycemic control and return for annual retinal photography screening.',
                                style: const TextStyle(fontSize: 11.5, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Clinician Sign-off Block (Clean & Responsive Wrap)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  const Text(
                                    'CLINICIAN REVIEW & AUDIT LOG',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: review != null ? AppColors.statusGoodBg : AppColors.pendingBg,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: review != null ? AppColors.statusGood : AppColors.pending,
                                      ),
                                    ),
                                    child: Text(
                                      review != null ? 'STATUS: VALIDATED BY CLINICIAN' : 'STATUS: AI TRIAGE (AWAITING REVIEW)',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: review != null ? AppColors.statusGood : AppColors.pending,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reviewing Practitioner: ${review?.clinicianName ?? "Authorized Ophthalmologist (Tele-Review)"}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                              ),
                              if (review != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Clinical Notes: ${review.clinicalNotes}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const MedicalDisclaimerBanner(isCompact: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _docMeta(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.darkTextMuted, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: valueColor)),
      ],
    );
  }
}
