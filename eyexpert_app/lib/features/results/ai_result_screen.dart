import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
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
    final isDesktop = ResponsiveLayout.isDesktop(context);

        if (pred == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.statusUngradable),
                const SizedBox(height: 12),
                const Text('No screening prediction available for this session.', style: AppTypography.body),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: onNewScreening, child: const Text('Start New Screening')),
              ],
            ),
          );
        }

        final severity = DRSeverity.fromLevel(pred.drLevel);
        final isReferable = pred.referable;

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: ResponsiveLayout.pagePadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header with AI Badge & Context
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge.aiBadge(label: 'AI DIAGNOSTIC RESULT'),
                          const SizedBox(width: 8),
                          Text(
                            'ID: ${session.screeningId ?? "Pending"}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        'Patient: ${patient?.patientId ?? "N/A"} (${AppFormatters.formatEye(patient?.eye)})',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dominant Result Card (High-Tech Diagnostic Cockpit)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isReferable
                            ? AppColors.referableAlert.withValues(alpha: 0.4)
                            : AppColors.accent.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isReferable
                              ? AppColors.referableAlert.withValues(alpha: 0.08)
                              : AppColors.accent.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'NEURAL RETINOPATHY CLASSIFICATION',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isReferable ? AppColors.referableAlert : AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'LEVEL ${pred.drLevel}',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            color: isReferable ? AppColors.referableAlert : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          severity.fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isReferable ? AppColors.referableAlert : AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Semantic Status Alert
                        isReferable
                            ? StatusBadge.referable(isLarge: true)
                            : StatusBadge.nonReferable(isLarge: true),

                        const SizedBox(height: 20),
                        const Divider(height: 1),
                        const SizedBox(height: 20),

                        // Metrics Strip
                        Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          spacing: 28,
                          runSpacing: 14,
                          children: [
                            _metricCol(
                              'MODEL PROBABILITY',
                              AppFormatters.formatProbability(pred.modelProbability),
                              AppColors.accent,
                            ),
                            _metricCol(
                              'CALIBRATED CONFIDENCE',
                              pred.calibratedConfidence != null
                                  ? AppFormatters.formatProbability(pred.calibratedConfidence)
                                  : 'Auto-Calibrated',
                              AppColors.textPrimary,
                            ),
                            _metricCol(
                              'IMAGE QUALITY',
                              quality?.status.label ?? 'OPTIMAL',
                              AppColors.statusGood,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Responsive 2-Column Section on Desktop/Tablet
                  if (isDesktop) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Probabilities
                        Expanded(
                          flex: 5,
                          child: ClinicalCard(
                            title: 'SOFTMAX CLASS PROBABILITIES',
                            icon: const Icon(Icons.bar_chart_rounded, color: AppColors.accent, size: 18),
                            child: ProbabilityDistributionWidget(
                              classProbabilities: pred.classProbabilities,
                              predictedLevel: pred.drLevel,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Right Column: Decision Support & Image Quality
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              ClinicalCard(
                                title: 'AI CLINICAL TRIAGE RECOMMENDATION',
                                icon: const Icon(Icons.recommend_rounded, color: AppColors.accent, size: 18),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isReferable ? AppColors.referableAlertBg : AppColors.statusGoodBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isReferable
                                          ? AppColors.referableAlert.withValues(alpha: 0.3)
                                          : AppColors.statusGood.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isReferable ? Icons.assignment_late_outlined : Icons.verified_user_rounded,
                                        color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          pred.recommendation,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ModelProvenanceCard(provenance: pred.provenance),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Mobile stacked layout
                    ClinicalCard(
                      title: 'SOFTMAX CLASS PROBABILITIES',
                      icon: const Icon(Icons.bar_chart_rounded, color: AppColors.accent, size: 18),
                      child: ProbabilityDistributionWidget(
                        classProbabilities: pred.classProbabilities,
                        predictedLevel: pred.drLevel,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClinicalCard(
                      title: 'AI CLINICAL TRIAGE RECOMMENDATION',
                      icon: const Icon(Icons.recommend_rounded, color: AppColors.accent, size: 18),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isReferable ? AppColors.referableAlertBg : AppColors.statusGoodBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isReferable
                                ? AppColors.referableAlert.withValues(alpha: 0.3)
                                : AppColors.statusGood.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isReferable ? Icons.assignment_late_outlined : Icons.verified_user_rounded,
                              color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pred.recommendation,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ModelProvenanceCard(provenance: pred.provenance),
                  ],
                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: 'Inspect Grad-CAM Evidence',
                          icon: Icons.biotech_outlined,
                          useGradient: true,
                          onPressed: onViewExplainability,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onNewScreening,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Complete & Start Next Patient Scan'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 18),

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
          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.3),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: valueColor),
        ),
      ],
    );
  }
}
