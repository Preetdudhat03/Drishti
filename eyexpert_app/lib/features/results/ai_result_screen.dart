import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/probability_bar.dart';
import '../../shared/widgets/model_provenance_card.dart';
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
            const Text('No screening prediction available for this session.'),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onNewScreening, child: const Text('Start New Screening')),
          ],
        ),
      );
    }

    final severity = DRSeverity.fromLevel(pred.drLevel);
    final isReferable = pred.referable;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Retinal Screening Result',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Patient: ${patient?.patientId ?? "N/A"} • ${AppFormatters.formatEye(patient?.eye)} • ID: ${session.screeningId ?? "N/A"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  isReferable
                      ? StatusBadge.referable(isLarge: true)
                      : StatusBadge.nonReferable(isLarge: true),
                ],
              ),
              const SizedBox(height: 14),

              // Core Clinical Prediction Card
              ClinicalCard(
                borderColor: severity.color.withOpacity(0.5),
                backgroundColor: severity.color.withOpacity(0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: severity.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isReferable ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                            color: severity.color,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DR CLASSIFICATION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Level ${pred.drLevel} — ${severity.fullName}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: severity.color,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                severity.description,
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricCol(
                          'REFERABLE DR',
                          isReferable ? 'YES (High Priority)' : 'NO (Routine)',
                          isReferable ? AppColors.referableAlert : AppColors.nonReferable,
                        ),
                        _metricCol(
                          'MODEL PROBABILITY',
                          AppFormatters.formatProbability(pred.modelProbability),
                          AppColors.primary,
                        ),
                        _metricCol(
                          'CALIBRATED CONFIDENCE',
                          pred.calibratedConfidence != null
                              ? AppFormatters.formatProbability(pred.calibratedConfidence)
                              : 'Pending Calibration',
                          Colors.black87,
                        ),
                        _metricCol(
                          'IMAGE QUALITY',
                          quality?.status.label ?? 'GOOD',
                          AppColors.statusGood,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Recommendation Card
              ClinicalCard(
                title: 'Clinical Decision Support Recommendation',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isReferable ? AppColors.referableAlertBg : AppColors.nonReferableBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isReferable
                          ? AppColors.referableAlert.withOpacity(0.3)
                          : AppColors.nonReferable.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isReferable ? Icons.assignment_late_outlined : Icons.calendar_today_outlined,
                        color: isReferable ? AppColors.referableAlert : AppColors.nonReferable,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pred.recommendation,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isReferable ? AppColors.referableAlert : AppColors.nonReferable,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Softmax Class Probability Distribution Card
              ClinicalCard(
                title: 'Class Probability Distribution (Softmax Output)',
                child: ProbabilityDistributionWidget(
                  classProbabilities: pred.classProbabilities,
                  predictedLevel: pred.drLevel,
                ),
              ),
              const SizedBox(height: 12),

              // Model Provenance Card
              ModelProvenanceCard(provenance: pred.provenance),
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
          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: valueColor),
        ),
      ],
    );
  }
}
