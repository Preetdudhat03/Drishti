import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
import '../../shared/widgets/probability_bar.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../screening/screening_session_provider.dart';

class ExplainabilityScreen extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const ExplainabilityScreen({super.key, required this.onBack});

  @override
  ConsumerState<ExplainabilityScreen> createState() => _ExplainabilityScreenState();
}

class _ExplainabilityScreenState extends ConsumerState<ExplainabilityScreen> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(screeningSessionProvider);
    final exp = session.explainability;
    final pred = session.prediction;
    final patient = session.patient;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final severity = pred != null ? DRSeverity.fromLevel(pred.drLevel) : null;
    final isReferable = pred?.referable ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP BAR WITH BACK ACTION & CONTEXT
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        tooltip: 'Back to AI Results',
                      ),
                      const SizedBox(width: 6),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Visual Explainability Workstation (Grad-CAM)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3),
                          ),
                          Text(
                            'Patient: ${patient?.patientId ?? "N/A"} • ${patient?.eye ?? "OD"} • Session: ${session.screeningId ?? "Pending"}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (severity != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Level ${pred!.drLevel}: ${severity.shortName}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. MAIN WORKSTATION CANVAS (Desktop: 2-Column, Mobile: Stacked)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Retinal Hero Viewer (65% width)
                    Expanded(
                      flex: 65,
                      child: _buildViewer(exp, session, patient),
                    ),
                    const SizedBox(width: 16),

                    // Right Column: Diagnostic & Feature Attribution Panel (35% width)
                    Expanded(
                      flex: 35,
                      child: _buildSidePanel(pred, severity, isReferable),
                    ),
                  ],
                )
              else ...[
                _buildViewer(exp, session, patient),
                const SizedBox(height: 14),
                _buildSidePanel(pred, severity, isReferable),
              ],
              const SizedBox(height: 20),

              const MedicalDisclaimerBanner(isCompact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewer(dynamic exp, dynamic session, dynamic patient) {
    return FundusImageViewer(
      originalImagePath: exp?.originalImageUrl ?? session.imagePath ?? '',
      gradcamImagePath: exp?.gradcamImageUrl ?? session.prediction?.heatmapPath,
      mode: FundusViewerMode.overlay,
      height: 480,
      eyeTag: patient?.eye,
      imageId: session.screeningId,
      showControls: true,
    );
  }

  Widget _buildSidePanel(dynamic pred, DRSeverity? severity, bool isReferable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. NEURAL ATTRIBUTION EXPLANATION
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GRADIENT-WEIGHTED ATTRIBUTION',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              const Text(
                'Heatmap highlights vascular zones where the ResNet-18 convolutional feature maps detected diabetic microvascular lesions:',
                style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              _lesionBullet('Red/Orange Hotspots', 'High-attention regions (Microaneurysms, Hard Exudates, Hemorrhages).'),
              const SizedBox(height: 6),
              _lesionBullet('Cyan/Blue Cool Zones', 'Background non-pathological retinal parenchyma.'),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. DIAGNOSTIC PREDICTION & PROBABILITY
        if (pred != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MODEL PROBABILITIES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                ),
                const SizedBox(height: 12),
                if (pred.probabilities != null && pred.probabilities!.isNotEmpty)
                  ProbabilityDistributionWidget(
                    probabilities: pred.probabilities!,
                    predictedLevel: pred.drLevel,
                    isDarkMode: false,
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Model Probability', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        AppFormatters.formatProbability(pred.modelProbability),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.electricBlue),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),

        // 3. CLINICAL ACTION CARD
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isReferable ? AppColors.referableAlertBg : AppColors.statusGoodBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isReferable ? AppColors.referableAlert : AppColors.statusGood),
          ),
          child: Row(
            children: [
              Icon(
                isReferable ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                color: isReferable ? AppColors.referableAlert : AppColors.statusGood,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isReferable
                      ? 'Referable diabetic retinopathy detected. Specialist review advised.'
                      : 'Non-referable findings. Routine annual follow-up recommended.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isReferable ? const Color(0xFF991B1B) : const Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _lesionBullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: AppColors.electricBlue, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
              children: [
                TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
