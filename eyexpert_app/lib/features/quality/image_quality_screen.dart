import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Image Quality Assessment',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Screening ID: ${session.screeningId ?? "N/A"} • Eye: ${session.patient?.eye ?? "OD"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (quality != null)
                    quality.isUngradable
                        ? StatusBadge.ungradable(isLarge: true)
                        : quality.isBorderline
                            ? StatusBadge.borderline(isLarge: true)
                            : StatusBadge.good(isLarge: true),
                ],
              ),
              if (session.errorMessage != null) ...[
                // Explicit Actionable Error Card
                ClinicalCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.error_outline_rounded, color: AppColors.statusUngradable, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quality Assessment Error',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'An issue occurred while evaluating the retinal fundus image.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ERROR DETAILS & DIAGNOSTICS:',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              session.errorMessage!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), fontWeight: FontWeight.w500),
                            ),
                            if (session.imagePath != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'File: ${session.imagePath}',
                                style: const TextStyle(fontSize: 10, color: Color(0xFF991B1B)),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              text: 'Retry Assessment',
                              icon: Icons.refresh_rounded,
                              onPressed: () {
                                ref.read(screeningSessionProvider.notifier).runQualityAssessment();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: widget.onRetake,
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Recapture Image'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else if (isEvaluating || quality == null) ...[
                // Loading / Multi-Step Pipeline Evaluation State
                ClinicalCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      // Thumbnail of the image being evaluated
                      if (session.imagePath != null)
                        SizedBox(
                          height: 160,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: FundusImageViewer(
                              originalImagePath: session.imagePath!,
                              eyeTag: session.patient?.eye,
                              imageId: 'IMG-${session.screeningId?.replaceAll("EX-", "")}',
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      const LinearProgressIndicator(
                        backgroundColor: Color(0xFFE2E8F0),
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Automated Optical Quality & Pre-Screening Pipeline',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Evaluating mathematical metrics before running deep neural inference...',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),

                      // Step-by-step Pipeline Stepper Items
                      _pipelineStep(
                        stepNumber: '1',
                        title: 'Retinal Mask & Field of View (FOV)',
                        description: 'Segmenting circular boundary and optic disc centering...',
                        isDone: true,
                      ),
                      const SizedBox(height: 8),
                      _pipelineStep(
                        stepNumber: '2',
                        title: 'Laplacian Focus & Sharpness Filter',
                        description: 'Computing second-derivative high-frequency edge variance...',
                        isDone: true,
                      ),
                      const SizedBox(height: 8),
                      _pipelineStep(
                        stepNumber: '3',
                        title: 'Illumination & Exposure Distribution',
                        description: 'Analyzing histogram saturation, underexposure, and glare...',
                        isDone: false,
                        isActive: true,
                      ),
                      const SizedBox(height: 8),
                      _pipelineStep(
                        stepNumber: '4',
                        title: 'Adaptive CLAHE Preprocessing',
                        description: 'Local contrast enhancement on green vascular channels...',
                        isDone: false,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Two-Column Layout (Image preview & Quality score breakdown)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail Fundus Image
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 220,
                        child: FundusImageViewer(
                          originalImagePath: session.imagePath ?? '',
                          eyeTag: session.patient?.eye,
                          imageId: 'IMG-${session.screeningId?.replaceAll("EX-", "")}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Overall Score Card
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: quality.isUngradable
                              ? AppColors.statusUngradableBg.withValues(alpha: 0.5)
                              : quality.isBorderline
                                  ? AppColors.statusBorderlineBg.withValues(alpha: 0.5)
                                  : AppColors.statusGoodBg.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: quality.isUngradable
                                ? AppColors.statusUngradable.withValues(alpha: 0.4)
                                : quality.isBorderline
                                    ? AppColors.statusBorderline.withValues(alpha: 0.4)
                                    : AppColors.statusGood.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OVERALL QUALITY SCORE',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppFormatters.formatPercentage(quality.overallScore),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: quality.isUngradable
                                    ? AppColors.statusUngradable
                                    : quality.isBorderline
                                        ? AppColors.statusBorderline
                                        : AppColors.statusGood,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              quality.isUngradable
                                  ? 'STATUS: UNGRADABLE'
                                  : quality.isBorderline
                                      ? 'STATUS: BORDERLINE (Enhancement Applied)'
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
                            ? AppColors.statusUngradable.withValues(alpha: 0.3)
                            : quality.isBorderline
                                ? AppColors.statusBorderline.withValues(alpha: 0.3)
                                : AppColors.statusGood.withValues(alpha: 0.3),
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
            color: indicatorColor.withValues(alpha: 0.15),
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

