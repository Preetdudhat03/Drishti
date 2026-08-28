import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
import '../../shared/widgets/workflow_step_bar.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../screening/screening_session_provider.dart';

class ImageQualityScreen extends ConsumerStatefulWidget {
  final VoidCallback onProceedToProcessing;
  final VoidCallback onRetake;

  const ImageQualityScreen({
    super.key,
    required this.onProceedToProcessing,
    required this.onRetake,
  });

  @override
  ConsumerState<ImageQualityScreen> createState() => _ImageQualityScreenState();
}

class _ImageQualityScreenState extends ConsumerState<ImageQualityScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screeningSessionProvider.notifier).runQualityAssessment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(screeningSessionProvider);
    final quality = session.quality;
    final isEvaluating = session.isProcessing;
    final patient = session.patient;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. WORKFLOW STEP INDICATOR
              const WorkflowStepBar(currentStep: 3),
              const SizedBox(height: 16),

              // 2. HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Optical Quality Assessment',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Session: ${session.screeningId ?? "N/A"} • Eye: ${patient?.eye ?? "OD"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (quality != null)
                    _qualityPill(quality.status.name.toUpperCase()),
                ],
              ),
              const SizedBox(height: 14),

              // 3. RETINAL VIEWPORT (HERO CANVAS)
              if (session.imagePath != null)
                FundusImageViewer(
                  originalImagePath: session.imagePath!,
                  enhancedImagePath: session.imagePath,
                  mode: quality?.isBorderline == true ? FundusViewerMode.compare : FundusViewerMode.original,
                  height: 380,
                  eyeTag: patient?.eye,
                  imageId: session.screeningId,
                  qualityLabel: quality?.status.name.toUpperCase(),
                  showControls: quality?.isBorderline == true,
                ),
              const SizedBox(height: 14),

              // 4. LOADING / EVALUATING STATE
              if (isEvaluating)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.electricBlue, strokeWidth: 2.5),
                      SizedBox(height: 14),
                      Text(
                        'EVALUATING OPTICAL FOCUS & ANATOMICAL CHROMINANCE...',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),              // 5. UNGRADABLE SAFETY GATE ALERT (BLOCKS INFERENCE)
              if (quality != null && quality.isUngradable) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.statusUngradableDarkBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.statusUngradable, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.dangerous_rounded, color: AppColors.statusUngradable, size: 24),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'IMAGE NOT SUITABLE FOR AUTOMATED SCREENING',
                              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.statusUngradable,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('SAFETY GATE ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        quality.feedbackMessages.isNotEmpty
                            ? quality.feedbackMessages.first
                            : 'Severe optical blur, illumination clipping, or non-retinal subject detected.',
                        style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onRetake,
                          icon: const Icon(Icons.replay_rounded, size: 18),
                          label: const Text('RETAKE RETINAL IMAGE', style: TextStyle(letterSpacing: 0.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusUngradable,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // 6. QUALITY METRICS STRIP (NO REPETITIVE CARDS)
              if (quality != null && !quality.isUngradable) ...[
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'OPTICAL METRICS BREAKDOWN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
                          ),
                          Text(
                            'Composite Quality Score: ${AppFormatters.formatPercent(quality.overallScore)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: quality.isBorderline ? AppColors.statusBorderline : AppColors.statusGood,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _metricRow('Focus & Sharpness', quality.sharpness.score, quality.sharpness.status),
                      const SizedBox(height: 8),
                      _metricRow('Illumination & Exposure', quality.illumination.score, quality.illumination.status),
                      const SizedBox(height: 8),
                      _metricRow('Retinal Field of View', quality.fieldOfView.score, quality.fieldOfView.status),
                      if (quality.isBorderline) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.statusBorderlineBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.statusBorderline.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.statusBorderline, size: 16),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Borderline contrast detected: Green-channel CLAHE contrast normalization will be applied automatically prior to PyTorch inference.',
                                  style: TextStyle(color: Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 7. PROCEED TO AI INFERENCE CTA
                ElevatedButton.icon(
                  onPressed: widget.onProceedToProcessing,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('PROCEED TO AI SCREENING & GRAD-CAM', style: TextStyle(letterSpacing: 0.5)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              const MedicalDisclaimerBanner(isCompact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricRow(String title, double score, String status) {
    final isGood = score >= 0.70;
    final isBorderline = score >= 0.45 && score < 0.70;
    final statusColor = isGood ? AppColors.statusGood : isBorderline ? AppColors.statusBorderline : AppColors.statusUngradable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text('${(score * 100).toStringAsFixed(1)}% • $status', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: statusColor)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),
      ],
    );
  }

  Widget _qualityPill(String status) {
    Color color;
    Color bg;
    if (status.contains('GOOD')) {
      color = AppColors.statusGood;
      bg = AppColors.statusGoodBg;
    } else if (status.contains('BORDER')) {
      color = AppColors.statusBorderline;
      bg = AppColors.statusBorderlineBg;
    } else {
      color = AppColors.statusUngradable;
      bg = AppColors.statusUngradableBg;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
      ),
    );
  }
}
