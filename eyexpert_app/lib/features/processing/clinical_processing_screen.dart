import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../screening/screening_session_provider.dart';

class ClinicalProcessingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const ClinicalProcessingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<ClinicalProcessingScreen> createState() => _ClinicalProcessingScreenState();
}

class _ClinicalProcessingScreenState extends ConsumerState<ClinicalProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(screeningSessionProvider.notifier).runDeepInference();
      if (mounted && ref.read(screeningSessionProvider).errorMessage == null) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(screeningSessionProvider);
    final currentStep = session.processingStep;

    if (session.errorMessage != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ClinicalCard(
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Classification Error',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'The deep neural model encountered an issue during inference.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                          'ERROR DETAILS & REASON:',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7F1D1D), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await ref.read(screeningSessionProvider.notifier).runDeepInference();
                            if (mounted && ref.read(screeningSessionProvider).errorMessage == null) {
                              widget.onComplete();
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Retry Inference'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AI Badge Header
              Center(child: StatusBadge.aiBadge(label: 'AI PROCESSING PIPELINE')),
              const SizedBox(height: 16),
              
              // Pulsing Teal Icon
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1.5),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Analyzing Retinal Photograph',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Screening ID: ${session.screeningId ?? "Pending"} • Eye: ${session.patient?.eye ?? "OD"}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Trustworthy Clinical Step Sequence
              ClinicalCard(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  children: [
                    _stepRow(
                      stepNum: 1,
                      title: 'Image received & verified',
                      subtitle: 'Laplacian focus & exposure threshold passed',
                      isDone: currentStep > 1,
                      isInProgress: currentStep == 1,
                    ),
                    const Divider(height: 20),
                    _stepRow(
                      stepNum: 2,
                      title: 'Image quality assessed',
                      subtitle: session.quality?.isBorderline ?? false
                          ? 'Adaptive CLAHE contrast enhancement active'
                          : 'Retinal field of view & illumination verified',
                      isDone: currentStep > 2,
                      isInProgress: currentStep == 2,
                    ),
                    const Divider(height: 20),
                    _stepRow(
                      stepNum: 3,
                      title: 'Analyzing retinal image...',
                      subtitle: 'ResNet-18 diabetic retinopathy inference',
                      isDone: currentStep > 3,
                      isInProgress: currentStep == 3,
                    ),
                    const Divider(height: 20),
                    _stepRow(
                      stepNum: 4,
                      title: 'Generating explainability',
                      subtitle: 'Layer-4 Grad-CAM activation heatmap',
                      isDone: currentStep > 4,
                      isInProgress: currentStep == 4,
                    ),
                    const Divider(height: 20),
                    _stepRow(
                      stepNum: 5,
                      title: 'Preparing clinical summary',
                      subtitle: 'Ready for clinician validation',
                      isDone: currentStep > 4,
                      isInProgress: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                session.processingStepLabel ?? 'Executing medical AI inference...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepRow({
    required int stepNum,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isInProgress,
  }) {
    Color iconBg = isDone
        ? AppColors.statusGoodBg
        : isInProgress
            ? AppColors.accentLight
            : AppColors.background;
    Color iconFg = isDone
        ? AppColors.statusGood
        : isInProgress
            ? AppColors.accent
            : AppColors.textMuted;
    BorderSide border = BorderSide(
      color: isDone
          ? AppColors.statusGood
          : isInProgress
              ? AppColors.accent
              : AppColors.border,
      width: 1,
    );

    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
            border: Border.fromBorderSide(border),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 15, color: AppColors.statusGood)
                : isInProgress
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      )
                    : Text(
                        '$stepNum',
                        style: TextStyle(
                          color: iconFg,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isInProgress || isDone ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 13,
                  color: isDone
                      ? AppColors.textPrimary
                      : isInProgress
                          ? AppColors.accent
                          : AppColors.textSecondary,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
