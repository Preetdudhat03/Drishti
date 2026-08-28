import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AI Visual Explainability (Grad-CAM)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Layer: ${exp?.targetLayer ?? "layer4[1].conv2"} • Patient: ${patient?.patientId ?? "N/A"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (pred != null)
                    StatusBadge.good(label: 'AI Level ${pred.drLevel}'),
                ],
              ),
              const SizedBox(height: 14),

              // Visual Tab Bar (Original / Grad-CAM / Overlay)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.black87,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  tabs: const [
                    Tab(text: 'Original Retina'),
                    Tab(text: 'Grad-CAM Heatmap'),
                    Tab(text: 'Overlay Blend'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Interactive Image Viewer Container
              Container(
                height: 340,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
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
              const SizedBox(height: 10),

              // Opacity Slider for Overlay Tab
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  if (_tabController.index != 2) return const SizedBox.shrink();
                  return ClinicalCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.opacity_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        const Text('Overlay Blend Opacity:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Expanded(
                          child: Slider(
                            value: _overlayOpacity,
                            min: 0.1,
                            max: 1.0,
                            divisions: 9,
                            label: '${(_overlayOpacity * 100).toInt()}%',
                            onChanged: (val) => setState(() => _overlayOpacity = val),
                          ),
                        ),
                        Text('${(_overlayOpacity * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),

              // Explicit Interpretability Tag
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppConstants.xaiDisclaimer,
                        style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Attended Anatomical Regions Card
              ClinicalCard(
                title: 'Model-Attended Anatomical Regions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The neural network focused on the following retinal structures during classification:',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: (exp?.modelAttendedRegions ?? ['Superior temporal arcade', 'Perimacular region'])
                          .map(
                            (region) => Chip(
                              avatar: const Icon(Icons.location_searching_rounded, size: 14, color: AppColors.primary),
                              label: Text(region, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                              backgroundColor: AppColors.primaryLight,
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Softmax Evidence
              if (pred != null)
                ClinicalCard(
                  title: 'Evidence Softmax Probabilities',
                  child: ProbabilityDistributionWidget(
                    classProbabilities: pred.classProbabilities,
                    predictedLevel: pred.drLevel,
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
}
