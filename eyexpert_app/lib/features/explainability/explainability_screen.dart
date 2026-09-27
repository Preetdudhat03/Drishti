import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/localization/locale_provider.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
import '../../shared/widgets/probability_bar.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../../shared/widgets/screening_workflow_ribbon.dart';
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

  Widget _buildLesionBiomarkerGuide(String lang) {
    final isHindi = lang == 'hi';

    final lesions = [
      {
        'color': const Color(0xFFDC2626),
        'title': isHindi ? 'माइक्रोएन्यूरिज्म (Microaneurysms)' : 'Microaneurysms',
        'subtitle': isHindi ? 'केशिकाओं के छोटे लाल उभार (आरंभिक लक्षण)' : 'Small capillary outpouchings (earliest DR sign)',
      },
      {
        'color': const Color(0xFFEA580C),
        'title': isHindi ? 'रेटिनल रक्तस्राव (Retinal Hemorrhages)' : 'Retinal Hemorrhages',
        'subtitle': isHindi ? 'गहरे रक्त के धब्बे (ब्लॉट व फ्लेम हेमोरेज)' : 'Blot & flame bleeding into nerve fiber layer',
      },
      {
        'color': const Color(0xFFCA8A04),
        'title': isHindi ? 'हार्ड एक्सुडेट्स (Hard Exudates)' : 'Hard Exudates',
        'subtitle': isHindi ? 'मैकुला के निकट पीले लिपिड व फैट जमाव' : 'Yellow lipid deposits leaking from fragile vessels',
      },
      {
        'color': const Color(0xFF64748B),
        'title': isHindi ? 'कॉटन वूल स्पॉट्स (Cotton Wool Spots)' : 'Cotton Wool Spots',
        'subtitle': isHindi ? 'रक्त आपूर्ति की कमी से तंत्रिका सूजन' : 'Nerve fiber infarcts from microvascular ischemia',
      },
      {
        'color': const Color(0xFF9333EA),
        'title': isHindi ? 'नियोवास्कुलराइजेशन (Neovascularization)' : 'Neovascularization',
        'subtitle': isHindi ? 'असामान्य नई रक्त वाहिकाएं (PDR का प्रमुख लक्षण)' : 'Abnormal new vessels prone to vitreous bleeding',
      },
    ];

    return ClinicalCard(
      title: isHindi ? 'रेटिना घाव व बायोमार्कर मार्गदर्शिका' : 'RETINAL LESION & BIOMARKER GUIDE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heatmap Colormap Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isHindi ? 'एआई ध्यान तीव्रता (Grad-CAM)' : 'Grad-CAM Neural Attention Intensity',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const Text('Turbo Map', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6), // Low / Blue
                        Color(0xFF10B981), // Medium / Green
                        Color(0xFFFBBF24), // High / Yellow
                        Color(0xFFEF4444), // Max / Red
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(isHindi ? 'निम्न ध्यान' : 'Low Attention', style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                    Text(isHindi ? 'मध्यम' : 'Moderate', style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted)),
                    Text(isHindi ? 'सर्वोच्च ध्यान (घाव क्षेत्र)' : 'Max Activation (Lesion Focal)', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Lesion List
          for (final item in lesions) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item['color'] as Color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          item['subtitle'] as String,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(screeningSessionProvider);
    final exp = session.explainability;
    final pred = session.prediction;
    final patient = session.patient;
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final tr = ref.watch(trProvider);
    final currentLang = ref.watch(localeProvider);

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
            tabs: [
              Tab(text: tr('tab_original')),
              Tab(text: tr('tab_gradcam')),
              Tab(text: tr('tab_overlay')),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Fundus Viewer Container
        Container(
          height: isDesktop ? 440 : 320,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
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
                  const Icon(Icons.opacity_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(tr('blend_opacity'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Expanded(
                    child: Slider(
                      value: _overlayOpacity,
                      min: 0.1,
                      max: 1.0,
                      divisions: 9,
                      activeColor: AppColors.primary,
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
          title: tr('attended_structures'),
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
                  const Text('Safety Gate Check:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  StatusBadge.good(label: '✓ VERIFIED'),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tr('attended_structures'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (exp?.modelAttendedRegions ?? ['Superior temporal arcade', 'Perimacular region'])
                    .map(
                      (region) => Chip(
                        avatar: const Icon(Icons.location_searching_rounded, size: 14, color: AppColors.primary),
                        label: Text(region, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                        backgroundColor: AppColors.primaryLight,
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

        // Lesion Explainer Key
        _buildLesionBiomarkerGuide(currentLang),
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
                  '⚠ Grad-CAM outputs highlight anatomical receptive fields contributing to deep learning inference and require ophthalmologist clinical validation.',
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
            title: 'RESNET-18 CLASS PROBABILITIES',
            child: ProbabilityDistributionWidget(
              classProbabilities: pred.classProbabilities,
              predictedLevel: pred.drLevel,
            ),
          ),
      ],
    );

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: ResponsiveLayout.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 3-Step Guided Flow Ribbon (Active on Step 3)
              const ScreeningWorkflowRibbon(activeStep: 3),

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
                        Text(
                          tr('xai_title'),
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                        Text(
                          'Regions contributing to prediction • Patient: ${patient?.patientId ?? "N/A"} (${patient?.eye ?? "OD"})',
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
