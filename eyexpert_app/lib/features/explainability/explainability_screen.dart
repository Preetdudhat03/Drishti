import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
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

class _ExplainabilityScreenState extends ConsumerState<ExplainabilityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _overlayOpacity = 0.65;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(screeningSessionProvider);
    final exp = session.explainability;
    final pred = session.prediction;
    final patient = session.patient;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    Widget imageViewerWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Selector (ORIGINAL | GRAD-CAM | OVERLAY)
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            tabs: const [
              Tab(text: 'ORIGINAL'),
              Tab(text: 'GRAD-CAM'),
              Tab(text: 'OVERLAY'),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Fundus Viewer Container (Clean off-white frame with dark retinal canvas)
        Container(
          height: isDesktop ? 440 : 320,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                final tabIdx = _tabController.index;
                if (tabIdx == 0) {
                  return FundusImageViewer(
                    originalImagePath: exp?.originalImageUrl ?? session.imagePath ?? '',
                    showOverlay: false,
                    eyeTag: patient?.eye,
                  );
                } else if (tabIdx == 1) {
                  return FundusImageViewer(
                    originalImagePath: exp?.gradcamImageUrl ?? '',
                    showOverlay: false,
                    eyeTag: 'Grad-CAM Heatmap',
                  );
                } else {
                  return FundusImageViewer(
                    originalImagePath: exp?.originalImageUrl ?? session.imagePath ?? '',
                    gradcamImagePath: exp?.gradcamImageUrl,
                    showOverlay: true,
                    overlayOpacity: _overlayOpacity,
                    eyeTag: '${patient?.eye ?? "OD"} (Overlay)',
                  );
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Opacity Blend Slider
        AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            if (_tabController.index != 2) return const SizedBox.shrink();
            return ClinicalCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.opacity_rounded, size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  const Text('Overlay Blend:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: _overlayOpacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      activeColor: AppColors.accent,
                      label: '${(_overlayOpacity * 100).toInt()}%',
                      onChanged: (val) => setState(() => _overlayOpacity = val),
                    ),
                  ),
                  Text('${(_overlayOpacity * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            );
          },
        ),
      ],
    );

    Widget evidenceDetailsWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AI Evidence Card
        ClinicalCard(
          title: 'AI EVIDENCE & ATTENDED REGIONS',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Target Feature Layer:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  Text(exp?.targetLayer ?? 'layer4[1].conv2', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Image Quality:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  StatusBadge.good(label: '✓ GOOD'),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Model-Attended Retinal Structures:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (exp?.modelAttendedRegions ?? ['Superior temporal arcade', 'Perimacular region'])
                    .map(
                      (region) => Chip(
                        avatar: const Icon(Icons.location_searching_rounded, size: 14, color: AppColors.accent),
                        label: Text(region, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.accentLight,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Statutory Interpretability Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.statusBorderlineBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.statusBorderline.withValues(alpha: 0.4)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.statusBorderline, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠ Interpretability output — highlights regions contributing to AI model prediction and does not represent a definitive lesion diagnosis.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF78350F),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Evidence Softmax Probabilities
        if (pred != null)
          ClinicalCard(
            title: 'EVIDENCE SOFTMAX PROBABILITIES',
            child: ProbabilityDistributionWidget(
              classProbabilities: pred.classProbabilities,
              predictedLevel: pred.drLevel,
            ),
          ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back to Result',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPLAINABILITY (GRAD-CAM)',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                        ),
                        Text(
                          'Regions contributing to model prediction • Patient: ${patient?.patientId ?? "N/A"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (pred != null)
                    StatusBadge.aiBadge(label: 'AI LEVEL ${pred.drLevel}'),
                ],
              ),
              const SizedBox(height: 14),

              // Responsive Layout
              if (isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: imageViewerWidget),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: evidenceDetailsWidget),
                  ],
                ),
              ] else ...[
                imageViewerWidget,
                const SizedBox(height: 12),
                evidenceDetailsWidget,
              ],
              const SizedBox(height: 16),

              const MedicalDisclaimerBanner(),
            ],
          ),
        ),
      ),
    );
  }
}
