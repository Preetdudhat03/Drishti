import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/clinical_card.dart';
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
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(screeningSessionProvider);
    final currentStep = session.processingStep;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Central Pulsing Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Analyzing Retinal Photograph',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                'Screening ID: ${session.screeningId ?? "Pending"} • Eye: ${session.patient?.eye ?? "OD"}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // 4-Stage Progressive Pipeline Steps
              ClinicalCard(
                child: Column(
                  children: [
                    _stepRow(
                      stepNum: 1,
                      title: 'Image Quality Assessment',
                      subtitle: 'Laplacian focus & exposure verified',
                      isDone: currentStep > 1,
                      isInProgress: currentStep == 1,
                    ),
                    const Divider(height: 18),
                    _stepRow(
                      stepNum: 2,
                      title: 'Retinal Preprocessing & Normalization',
                      subtitle: session.quality?.isBorderline ?? false
                          ? 'Adaptive CLAHE contrast enhancement active'
                          : 'Standardized 224x224 circular mask crop',
                      isDone: currentStep > 2,
                      isInProgress: currentStep == 2,
                    ),
                    const Divider(height: 18),
                    _stepRow(
                      stepNum: 3,
                      title: 'Deep AI Retinopathy Classification',
                      subtitle: 'ResNet-18 transfer learning backbone inference',
                      isDone: currentStep > 3,
                      isInProgress: currentStep == 3,
                    ),
                    const Divider(height: 18),
                    _stepRow(
                      stepNum: 4,
                      title: 'Grad-CAM Explainability Generation',
                      subtitle: 'Extracting layer4[1].conv2 activation heatmap',
                      isDone: currentStep > 4,
                      isInProgress: currentStep == 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                session.processingStepLabel ?? 'Initializing inference pipeline...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
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
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.statusGood
                : isInProgress
                    ? AppColors.primary
                    : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : isInProgress
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        '$stepNum',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                  fontWeight: isInProgress || isDone ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                  color: isDone || isInProgress ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
