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
              const SizedBox(height: 14),

              if (isEvaluating || quality == null) ...[
                // Loading / Evaluation state
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(height: 16),
                        Text(
                          'Evaluating focus, illumination, and retinal field of view...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Running Laplacian sharpness filter & mask segmentation',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
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
                              ? AppColors.statusUngradableBg.withOpacity(0.5)
                              : quality.isBorderline
                                  ? AppColors.statusBorderlineBg.withOpacity(0.5)
                                  : AppColors.statusGoodBg.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: quality.isUngradable
                                ? AppColors.statusUngradable.withOpacity(0.4)
                                : quality.isBorderline
                                    ? AppColors.statusBorderline.withOpacity(0.4)
                                    : AppColors.statusGood.withOpacity(0.4),
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
}
