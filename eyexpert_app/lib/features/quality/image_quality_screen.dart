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
                ),

              // 5. UNGRADABLE SAFETY GATE ALERT (BLOCKS INFERENCE)
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
                                      : 'STATUS: OPTIMAL FOR SCREENING',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: quality.isUngradable
                                    ? AppColors.statusUngradable
                                    : quality.isBorderline
                                        ? AppColors.statusBorderline
                                        : AppColors.statusGood,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Breakdown Metrics Gauges Card
                ClinicalCard(
                  title: 'Quality Assessment Breakdown',
                  child: Column(
                    children: [
                      _metricRow(
                        label: 'Focus & Sharpness',
                        score: quality.sharpness.score,
                        status: quality.sharpness.status,
                        icon: Icons.filter_center_focus_rounded,
                        isFailed: quality.sharpness.score < 0.45,
                      ),
                      const Divider(height: 16),
                      _metricRow(
                        label: 'Illumination & Exposure',
                        score: quality.illumination.score,
                        status: quality.illumination.status,
                        icon: Icons.wb_sunny_outlined,
                        isFailed: quality.illumination.score < 0.40,
                      ),
                      const Divider(height: 16),
                      _metricRow(
                        label: 'Retinal Field of View',
                        score: quality.fieldOfView.score,
                        status: quality.fieldOfView.status,
                        icon: Icons.crop_free_rounded,
                        isFailed: quality.fieldOfView.score < 0.35,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Specific Clinical Feedback Messages Banner
                if (quality.feedbackMessages.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: quality.isUngradable
                          ? AppColors.statusUngradableBg
                          : quality.isBorderline
                              ? AppColors.statusBorderlineBg
                              : AppColors.statusGoodBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: quality.isUngradable
                            ? AppColors.statusUngradable.withOpacity(0.3)
                            : quality.isBorderline
                                ? AppColors.statusBorderline.withOpacity(0.3)
                                : AppColors.statusGood.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              quality.isUngradable
                                  ? Icons.error_outline_rounded
                                  : quality.isBorderline
                                      ? Icons.info_outline_rounded
                                      : Icons.check_circle_outline_rounded,
                              size: 16,
                              color: quality.isUngradable
                                  ? AppColors.statusUngradable
                                  : quality.isBorderline
                                      ? AppColors.statusBorderline
                                      : AppColors.statusGood,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              quality.isUngradable
                                  ? 'CLINICAL RECAPTURE REQUIRED'
                                  : quality.isBorderline
                                      ? 'ADAPTIVE PREPROCESSING ACTION'
                                      : 'IMAGE QUALITY VERIFIED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: quality.isUngradable
                                    ? AppColors.statusUngradable
                                    : quality.isBorderline
                                        ? AppColors.statusBorderline
                                        : AppColors.statusGood,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        for (final msg in quality.feedbackMessages)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text(
                              '• $msg',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),

                // Strict Safety-Gated Action Buttons
                if (quality.isUngradable) ...[
                  PrimaryButton(
                    text: 'Recapture Retinal Image',
                    icon: Icons.replay_rounded,
                    isDestructive: true,
                    onPressed: widget.onRetake,
                  ),
                  const SizedBox(height: 8),
                  const Center(
                    child: Text(
                      'Automated DR prediction is blocked for ungradable images to maintain clinical safety.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.statusUngradable, fontWeight: FontWeight.w600),
                    ),
                  ),
                ] else if (quality.isBorderline) ...[
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          text: 'Apply CLAHE Enhancement & Screen',
                          icon: Icons.auto_fix_high_rounded,
                          onPressed: widget.onProceedToProcessing,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: widget.onRetake,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retake Optional'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  PrimaryButton(
                    text: 'Continue to AI Screening',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: widget.onProceedToProcessing,
                  ),
                ],
              ],
              const SizedBox(height: 16),

              const MedicalDisclaimerBanner(isCompact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricRow({
    required String label,
    required double score,
    required String status,
    required IconData icon,
    required bool isFailed,
  }) {
    final color = isFailed ? AppColors.statusUngradable : AppColors.statusGood;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: score,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(AppFormatters.formatPercentage(score), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
            Text(status, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  Widget _pipelineStep({
    required String stepNumber,
    required String title,
    required String description,
    bool isDone = false,
    bool isActive = false,
  }) {
    final Color indicatorColor = isDone
        ? AppColors.statusGood
        : isActive
            ? AppColors.primary
            : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: indicatorColor.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: indicatorColor, width: 1.5),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 13, color: AppColors.statusGood)
                : isActive
                    ? const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : Text(
                        stepNumber,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: indicatorColor),
                      ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDone || isActive ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                description,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (isDone)
          const Text(
            'DONE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.statusGood),
          ),
      ],
    );
  }
}

