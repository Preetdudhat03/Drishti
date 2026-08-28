import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
import '../../shared/widgets/probability_bar.dart';
import '../../shared/widgets/workflow_step_bar.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../screening/screening_session_provider.dart';

class AiResultScreen extends ConsumerWidget {
  final VoidCallback onViewExplainability;
  final VoidCallback onViewReport;
  final VoidCallback onNewScreening;

  const AiResultScreen({
    super.key,
    required this.onViewExplainability,
    required this.onViewReport,
    required this.onNewScreening,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(screeningSessionProvider);
    final pred = session.prediction;
    final quality = session.quality;
    final patient = session.patient;

    if (pred == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.statusUngradable),
            const SizedBox(height: 12),
            const Text('No screening prediction available for this session.', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onNewScreening,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricBlue, foregroundColor: Colors.white),
              child: const Text('Start New Screening'),
            ),
          ],
        ),
      );
    }

    final severity = DRSeverity.fromLevel(pred.drLevel);
    final isReferable = pred.referable;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. WORKFLOW STEP INDICATOR
              const WorkflowStepBar(currentStep: 4),
              const SizedBox(height: 16),

              // 2. HEADER STRIP
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Retinal Diagnostic Screening',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Patient ${patient?.patientId ?? "N/A"} • ${patient?.eye ?? "OD"} • Session: ${session.screeningId ?? "Pending"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  _severityHeaderPill(severity, isReferable),
                ],
              ),
              const SizedBox(height: 14),

              // 3. RETINAL VIEWPORT (HERO CANVAS WITH GRAD-CAM & OVERLAY SWITCHER)
              if (session.imagePath != null)
                FundusImageViewer(
                  originalImagePath: session.imagePath!,
                  gradcamImagePath: pred.heatmapPath,
                  mode: pred.heatmapPath != null ? FundusViewerMode.overlay : FundusViewerMode.original,
                  height: 380,
                  eyeTag: patient?.eye,
                  imageId: session.screeningId,
                  qualityLabel: quality?.status.name.toUpperCase(),
                  showControls: true,
                ),
              const SizedBox(height: 14),

              // 4. DIAGNOSTIC CLASSIFICATION & TRIAGE BANNER
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isReferable ? AppColors.referableAlertBg : AppColors.statusGoodBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                    width: 1.5,
                  ),
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
                                'AI PREDICTION: LEVEL ${pred.drLevel}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                severity.fullName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isReferable
                                    ? 'CLINICAL ACTION: Refer to Ophthalmologist within 2-4 weeks for confirmatory examination.'
                                    : 'CLINICAL ACTION: Annual routine screening recommended. No urgent specialist referral required.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isReferable ? const Color(0xFF991B1B) : const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text('MODEL PROBABILITY', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                              Text(
                                AppFormatters.formatProbability(pred.modelProbability),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. PROBABILITY SPECTRUM (WORKSTATION VIEW)
              if (pred.probabilities.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DIABETIC RETINOPATHY PROBABILITY SPECTRUM',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 14),
                      ProbabilityDistributionWidget(
                        probabilities: pred.probabilities,
                        predictedLevel: pred.drLevel,
                        isDarkMode: false,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // 6. WORKFLOW ACTIONS
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onViewReport,
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('GENERATE CLINICAL REPORT', style: TextStyle(letterSpacing: 0.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: onNewScreening,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Next Screening'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.borderDark),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const MedicalDisclaimerBanner(isCompact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _severityHeaderPill(DRSeverity severity, bool isReferable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isReferable ? 'REFERABLE DR ALERT' : 'NON-REFERABLE',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }
}
