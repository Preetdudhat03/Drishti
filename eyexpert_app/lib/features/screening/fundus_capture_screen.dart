import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/services/audio_guidance_service.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
import '../../shared/widgets/screening_workflow_ribbon.dart';
import 'screening_session_provider.dart';

class ClinicalSampleItem {
  final String label;
  final String subtitle;
  final String assetPath;
  final int level;
  final String severity;
  final Color badgeColor;

  const ClinicalSampleItem({
    required this.label,
    required this.subtitle,
    required this.assetPath,
    required this.level,
    required this.severity,
    required this.badgeColor,
  });
}

class FundusCaptureScreen extends ConsumerStatefulWidget {
  final VoidCallback onProceedToQuality;
  final VoidCallback onCancel;

  const FundusCaptureScreen({
    super.key,
    required this.onProceedToQuality,
    required this.onCancel,
  });

  @override
  ConsumerState<FundusCaptureScreen> createState() => _FundusCaptureScreenState();
}

class _FundusCaptureScreenState extends ConsumerState<FundusCaptureScreen> {
  String? _selectedImagePath;
  bool _isCaptured = false;
  String? _selectedSampleLabel;
  final ImagePicker _picker = ImagePicker();

  static const List<ClinicalSampleItem> _samples = [
    ClinicalSampleItem(
      label: 'Normal (Level 0)',
      subtitle: 'Healthy Retina',
      assetPath: 'assets/sample_fundus/sample_good_normal.png',
      level: 0,
      severity: 'NORMAL',
      badgeColor: AppColors.statusGood,
    ),
    ClinicalSampleItem(
      label: 'Mild NPDR (Level 1)',
      subtitle: 'Microaneurysms',
      assetPath: 'assets/sample_fundus/sample_good_npdr_mild.png',
      level: 1,
      severity: 'MILD',
      badgeColor: Color(0xFFF59E0B),
    ),
    ClinicalSampleItem(
      label: 'Moderate NPDR (Level 2)',
      subtitle: 'Exudates & Hemorrhages',
      assetPath: 'assets/sample_fundus/sample_good_npdr_moderate.png',
      level: 2,
      severity: 'MODERATE',
      badgeColor: Color(0xFFEA580C),
    ),
    ClinicalSampleItem(
      label: 'Severe NPDR (Level 3)',
      subtitle: 'Venous Beading / Cotton Wool',
      assetPath: 'assets/sample_fundus/real_aptos_gradcam_level_3_405b4f78658f.png',
      level: 3,
      severity: 'SEVERE',
      badgeColor: Color(0xFFDC2626),
    ),
    ClinicalSampleItem(
      label: 'PDR (Level 4)',
      subtitle: 'Neovascularization',
      assetPath: 'assets/sample_fundus/sample_good_pdr_severe.png',
      level: 4,
      severity: 'URGENT PDR',
      badgeColor: Color(0xFF991B1B),
    ),
    ClinicalSampleItem(
      label: 'Borderline Test',
      subtitle: 'Low Contrast (CLAHE)',
      assetPath: 'assets/sample_fundus/sample_borderline_illum.png',
      level: 2,
      severity: 'CLAHE ENHANCED',
      badgeColor: Color(0xFF3B82F6),
    ),
    ClinicalSampleItem(
      label: 'Ungradable Blur',
      subtitle: 'Motion Blur Safety Rejection',
      assetPath: 'assets/sample_fundus/sample_ungradable_blur.png',
      level: 2,
      severity: 'SAFETY GATE HALT',
      badgeColor: Color(0xFF64748B),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedImagePath = null;
    _isCaptured = false;
    _selectedSampleLabel = null;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lang = ref.read(localeProvider);
      AudioGuidanceService.promptReticleFraming(ref, lang);
    });
  }

  void _speakGuidance() {
    final lang = ref.read(localeProvider);
    AudioGuidanceService.promptReticleFraming(ref, lang);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      if (photo != null) {
        setState(() {
          _selectedImagePath = photo.path;
          _isCaptured = true;
          _selectedSampleLabel = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image acquisition error: $e')),
        );
      }
    }
  }

  void _selectClinicalSample(ClinicalSampleItem sample) {
    setState(() {
      _selectedImagePath = sample.assetPath;
      _isCaptured = true;
      _selectedSampleLabel = sample.label;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Benchmark Sample Loaded: ${sample.label} (${sample.subtitle})'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmImage() {
    if (_selectedImagePath == null) return;
    ref.read(screeningSessionProvider.notifier).setImage(
      path: _selectedImagePath!,
    );
    widget.onProceedToQuality();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(screeningSessionProvider);
    final patient = session.patient;
    final tr = ref.watch(trProvider);

    final bool isUngradableSample = _selectedSampleLabel?.contains('Ungradable') == true;
    final bool isBorderlineSample = _selectedSampleLabel?.contains('Borderline') == true;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: ResponsiveLayout.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 3-Step Guided Flow Ribbon (Active on Step 2)
              const ScreeningWorkflowRibbon(activeStep: 2),

              // 2. Header with Session Meta & Cancel Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('retinal_acquisition'),
                          style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Patient: ${patient?.patientId ?? "N/A"} • Eye: ${patient?.eye ?? "OD"} • ID: ${session.screeningId ?? "Pending"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Cancel Session'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Viewfinder Reticle Framing Guide / Preview
              Container(
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Captured image or preview
                    if (_selectedImagePath != null)
                      FundusImageViewer(
                        originalImagePath: _selectedImagePath!,
                        eyeTag: patient?.eye,
                        imageId: _selectedSampleLabel ?? 'LIVE-CAPTURE',
                      ),

                    // Retinal Framing Reticle Guide Overlay
                    if (!_isCaptured)
                      CustomPaint(
                        size: const Size(260, 260),
                        painter: _FundusReticlePainter(),
                      ),

                    // Top Guidance Badge
                    Positioned(
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isCaptured ? Icons.check_circle_outline_rounded : Icons.center_focus_strong_rounded,
                              color: _isCaptured ? AppColors.statusGood : AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isCaptured
                                  ? (_selectedSampleLabel != null ? 'Sample: $_selectedSampleLabel' : tr('loaded_guide'))
                                  : tr('reticle_guide'),
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Optical Quality Checklist Card (Ported from Web Card 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('optical_checklist_title'),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: _speakGuidance,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.volume_up_rounded, size: 13, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  tr('speak_guidance'),
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _buildQualityPill(
                          label: isUngradableSample ? 'Clarity: ❌ Blur' : tr('chk_clarity'),
                          isPass: !isUngradableSample,
                        ),
                        _buildQualityPill(
                          label: isBorderlineSample ? 'Light: ⚠️ Low Contrast' : tr('chk_light'),
                          isPass: !isBorderlineSample,
                          isWarning: isBorderlineSample,
                        ),
                        _buildQualityPill(
                          label: tr('chk_center'),
                          isPass: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 5. Image Acquisition Button Controls
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: Text(tr('camera_capture')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(tr('gallery_select')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 6. Clinical Benchmark Test Samples Strip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          tr('clinical_samples_title'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select pre-loaded APTOS-2019 test cases to test any DR stage and optical quality safety gate:',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _samples.map((s) {
                        final isSelected = _selectedSampleLabel == s.label;
                        return InkWell(
                          onTap: () => _selectClinicalSample(s),
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? s.badgeColor.withValues(alpha: 0.12) : AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? s.badgeColor : AppColors.border,
                                width: isSelected ? 1.8 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: s.badgeColor,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.label,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected ? s.badgeColor : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      s.subtitle,
                                      style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 7. Proceed to Quality Evaluation Button
              PrimaryButton(
                text: tr('confirm_quality'),
                icon: Icons.fact_check_rounded,
                useGradient: true,
                onPressed: _selectedImagePath != null ? _confirmImage : null,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityPill({
    required String label,
    required bool isPass,
    bool isWarning = false,
  }) {
    final Color color = isWarning
        ? const Color(0xFFD97706)
        : (isPass ? const Color(0xFF16A34A) : const Color(0xFFDC2626));
    final Color bg = isWarning
        ? const Color(0xFFFEF3C7)
        : (isPass ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWarning
                ? Icons.warning_amber_rounded
                : (isPass ? Icons.check_circle_rounded : Icons.cancel_rounded),
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _FundusReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    final ringPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Outer Target Ring
    canvas.drawCircle(center, radius, ringPaint);

    // Inner Macula Target Circle
    final innerPaint = Paint()
      ..color = Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.35, innerPaint);

    // Optic Disc Guide Ring (Nasal Offset)
    final discCenter = Offset(center.dx - radius * 0.45, center.dy);
    final discPaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(discCenter, radius * 0.22, discPaint);

    // Crosshairs
    final crosshairPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.4)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(center.dx - 18, center.dy),
      Offset(center.dx + 18, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 18),
      Offset(center.dx, center.dy + 18),
      crosshairPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
