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
                  height: 400,
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
                          quality?.status.label ?? 'GOOD',
                          AppColors.statusGood,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Responsive 2-Column Section on Desktop/Tablet
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Probabilities
                    Expanded(
                      flex: 5,
                      child: ClinicalCard(
                        title: 'CLASS PROBABILITY (SOFTMAX OUTPUT)',
                        child: ProbabilityDistributionWidget(
                          classProbabilities: pred.classProbabilities,
                          predictedLevel: pred.drLevel,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Right Column: Decision Support & Image Quality
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          ClinicalCard(
                            title: 'DECISION SUPPORT RECOMMENDATION',
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isReferable ? AppColors.referableAlertBg : AppColors.statusGoodBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isReferable
                                      ? AppColors.referableAlert.withOpacity(0.3)
                                      : AppColors.statusGood.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isReferable ? Icons.assignment_late_outlined : Icons.calendar_today_outlined,
                                    color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      pred.recommendation,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ModelProvenanceCard(provenance: pred.provenance),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Mobile stacked layout
                ClinicalCard(
                  title: 'CLASS PROBABILITY (SOFTMAX OUTPUT)',
                  child: ProbabilityDistributionWidget(
                    classProbabilities: pred.classProbabilities,
                    predictedLevel: pred.drLevel,
                  ),
                ),
                const SizedBox(height: 12),
                ClinicalCard(
                  title: 'DECISION SUPPORT RECOMMENDATION',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isReferable ? AppColors.referableAlertBg : AppColors.statusGoodBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isReferable
                            ? AppColors.referableAlert.withOpacity(0.3)
                            : AppColors.statusGood.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isReferable ? Icons.assignment_late_outlined : Icons.calendar_today_outlined,
                          color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pred.recommendation,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ModelProvenanceCard(provenance: pred.provenance),
              ],
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'View Grad-CAM & Evidence',
                      icon: Icons.biotech_outlined,
                      onPressed: onViewExplainability,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      text: 'View Screening Report',
                      icon: Icons.description_outlined,
                      isSecondary: true,
                      onPressed: onViewReport,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onNewScreening,
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('Complete & Start Next Patient Screening'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                ),
              ),
              const SizedBox(height: 16),

              const MedicalDisclaimerBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.2),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: valueColor),
        ),
      ],
    );
  }
}
