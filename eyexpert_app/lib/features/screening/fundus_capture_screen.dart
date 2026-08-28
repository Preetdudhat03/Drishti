import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
import '../../shared/widgets/workflow_step_bar.dart';
import 'screening_session_provider.dart';

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
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImagePath = null;
    _isCaptured = false;
  }

  Future<void> _loadSampleAsset(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final filename = assetPath.split('/').last;
      final file = File('${Directory.systemTemp.path}/$filename');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      setState(() {
        _selectedImagePath = file.path;
        _isCaptured = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sample: $e')),
        );
      }
    }
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. WORKFLOW STEP INDICATOR
              const WorkflowStepBar(currentStep: 2),
              const SizedBox(height: 16),

              // 2. HEADER & SESSION INFO
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Retinal Image Acquisition',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Patient: ${patient?.patientId ?? "N/A"} • Eye: ${patient?.eye ?? "OD"} • Session: ${session.screeningId ?? "Pending"}',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.darkTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.darkTextSecondary,
                      side: const BorderSide(color: AppColors.borderDark),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text('Cancel Session', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. RETINAL VIEWPORT (THE HERO OF THE PRODUCT)
              Container(
                height: 380,
                decoration: BoxDecoration(
                  color: AppColors.obsidian,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderDark, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_selectedImagePath != null)
                      FundusImageViewer(
                        originalImagePath: _selectedImagePath!,
                        eyeTag: patient?.eye,
                        imageId: session.screeningId,
                        showReticle: false,
                        showControls: false,
                      )
                    else
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.deepSpace,
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: const Icon(Icons.remove_red_eye_outlined, color: AppColors.hudCyan, size: 32),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'OPTICAL RETINAL VIEWPORT',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Align ophthalmic lens adapter or select ground-truth sample below',
                            style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 11.5),
                          ),
                        ],
                      ),

                    // Optical Framing Reticle Guide
                    if (!_isCaptured)
                      IgnorePointer(
                        child: CustomPaint(
                          size: const Size(260, 260),
                          painter: _ReticlePainter(),
                        ),
                      ),

                    // Live Optical Alignment Indicators
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.deepSpace.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCaptured ? Icons.check_circle : Icons.center_focus_strong_rounded,
                                  color: _isCaptured ? AppColors.statusGood : AppColors.hudCyan,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isCaptured ? 'Retinal Photo Buffered' : 'Aperture: 45° Posterior Pole',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.deepSpace.withValues(alpha: 0.90),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.borderDark),
                            ),
                            child: const Text(
                              'RAW RGB SENSOR',
                              style: TextStyle(color: AppColors.darkTextMuted, fontSize: 9.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. ACQUISITION ACTION STRIP (Camera & Gallery)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Capture with Camera', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.electricBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Upload Image File', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: Colors.white,
                        backgroundColor: AppColors.deepSpace,
                        side: const BorderSide(color: AppColors.borderDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 5. CLINICAL BENCHMARK GROUND-TRUTH SELECTOR (FOR DEMO / AUDIT)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.deepSpace,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, color: AppColors.hudCyan, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: AppColors.deepSpace,
                          isExpanded: true,
                          hint: const Text(
                            'Load Clinical Benchmark Sample (APTOS Dataset)...',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_good_normal.png',
                              child: Text('Normal Retina — Level 0 (Non-Referable)', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_good_npdr_mild.png',
                              child: Text('Mild NPDR — Level 1 (Non-Referable)', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_good_npdr_moderate.png',
                              child: Text('Moderate NPDR — Level 2 (Referable Alert)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.statusBorderline)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_good_pdr_severe.png',
                              child: Text('Proliferative DR — Level 4 (Severe Referable)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.referableAlert)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_borderline_illum.png',
                              child: Text('Borderline Illumination (CLAHE Enhancement Target)', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_ungradable_blur.png',
                              child: Text('Ungradable Motion Blur (Safety Gate Rejection)', style: TextStyle(fontSize: 12, color: AppColors.statusUngradable)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_ungradable_dark.png',
                              child: Text('Ungradable Underexposed (Safety Gate Rejection)', style: TextStyle(fontSize: 12, color: AppColors.statusUngradable)),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) _loadSampleAsset(val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 6. CONFIRM & PROCEED CTA
              ElevatedButton.icon(
                onPressed: _selectedImagePath != null ? _confirmImage : null,
                icon: const Icon(Icons.verified_outlined, size: 18),
                label: const Text('CONFIRM & EVALUATE IMAGE QUALITY', style: TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.graphite,
                  disabledForegroundColor: AppColors.darkTextMuted,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.hudCyan.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    canvas.drawCircle(center, radius, paint);
    paint.color = AppColors.hudCyan.withValues(alpha: 0.25);
    canvas.drawCircle(center, radius * 0.35, paint);

    paint.color = AppColors.hudCyan.withValues(alpha: 0.80);
    const arm = 14.0;
    canvas.drawLine(Offset(center.dx - arm, center.dy), Offset(center.dx + arm, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - arm), Offset(center.dx, center.dy + arm), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
