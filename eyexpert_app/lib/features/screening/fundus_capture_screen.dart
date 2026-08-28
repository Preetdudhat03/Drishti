import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
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
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Session Meta
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Retinal Fundus Image Acquisition',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      Text(
                        'Patient: ${patient?.patientId ?? "N/A"} • Eye: ${patient?.eye ?? "OD"} • ID: ${session.screeningId ?? "Pending"}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
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
              const SizedBox(height: 14),

              // Viewfinder Framing Guide / Preview
              Container(
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Captured image or preview
                    if (_selectedImagePath != null)
                      FundusImageViewer(
                        originalImagePath: _selectedImagePath!,
                        eyeTag: patient?.eye,
                        imageId: 'IMG-2026-0912',
                      ),

                    // Retinal Framing Reticle Guide Overlay
                    if (!_isCaptured)
                      CustomPaint(
                        size: const Size(260, 260),
                        painter: _FundusReticlePainter(),
                      ),

                    // Live Guidance Prompt Banner
                    Positioned(
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black87.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isCaptured ? Icons.check_circle_outline : Icons.center_focus_strong_rounded,
                              color: AppColors.accent,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isCaptured
                                  ? 'Image Loaded • Inspect Retinal FOV'
                                  : 'Center optic disc & macula inside reticle guide',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Camera Acquisition Buttons Strip (Camera, Gallery, Retake)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text('Capture with Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Select from File'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Benchmark Clinical Retinal Cases Dropdown (for Evaluator / Testing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text(
                            'Load Clinical Benchmark Case (APTOS)...',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_good_normal.png',
                              child: Text('Level 0: Normal Retina (Non-Referable)', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_good_npdr_mild.png',
                              child: Text('Level 1: Mild NPDR (Non-Referable)', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_good_npdr_moderate.png',
                              child: Text('Level 2: Moderate NPDR (Referable)', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_good_pdr_severe.png',
                              child: Text('Level 4: Proliferative DR (Referable)', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_borderline_illum.png',
                              child: Text('Borderline: Low Contrast (CLAHE Target)', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_ungradable_blur.png',
                              child: Text('Ungradable: Motion Blur (Safety Gate)', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: 'assets/sample_fundus/sample_ungradable_dark.png',
                              child: Text('Ungradable: Underexposed (Safety Gate)', style: TextStyle(fontSize: 12)),
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
              const SizedBox(height: 12),

              // Instructions Checklist Card
              ClinicalCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceAround,
                      children: [
                        _guidanceItem(Icons.crop_free_rounded, 'Center field'),
                        _guidanceItem(Icons.auto_fix_high_rounded, 'Sharp focus'),
                        _guidanceItem(Icons.wb_sunny_outlined, 'Illumination'),
                        _guidanceItem(Icons.vibration_rounded, 'Hold steady'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Compatible with handheld fundus cameras, ophthalmic slit-lamp smartphone adapters, and direct device uploads.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Confirm & Evaluate Image Quality',
                      icon: Icons.verified_outlined,
                      onPressed: _selectedImagePath != null ? _confirmImage : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _isCaptured = false;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retake'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guidanceItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}

class _FundusReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;

    // Circular reticle
    canvas.drawCircle(center, radius, paint);

    // Crosshair ticks
    const tickLength = 12.0;
    canvas.drawLine(Offset(center.dx - radius - tickLength, center.dy), Offset(center.dx - radius + tickLength, center.dy), paint);
    canvas.drawLine(Offset(center.dx + radius - tickLength, center.dy), Offset(center.dx + radius + tickLength, center.dy), paint);
    canvas.drawLine(Offset(center.dx, center.dy - radius - tickLength), Offset(center.dx, center.dy - radius + tickLength), paint);
    canvas.drawLine(Offset(center.dx, center.dy + radius - tickLength), Offset(center.dx, center.dy + radius + tickLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
