import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/services/mock_data_service.dart';
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
  Map<String, dynamic>? _selectedScenario;
  bool _isCaptured = false;

  final List<Map<String, dynamic>> _scenarios = MockDataService.getDemoScenarios();

  @override
  void initState() {
    super.initState();
    // Default to Moderate NPDR scenario
    _selectedScenario = _scenarios[2];
    _selectedImagePath = _selectedScenario!['imageAsset'];
  }

  void _selectScenario(Map<String, dynamic> scenario) {
    setState(() {
      _selectedScenario = scenario;
      _selectedImagePath = scenario['imageAsset'];
      _isCaptured = true;
    });
  }

  void _confirmImage() {
    if (_selectedImagePath == null) return;
    ref.read(screeningSessionProvider.notifier).setImage(
      path: _selectedImagePath!,
      demoScenario: _selectedScenario,
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
          constraints: const BoxConstraints(maxWidth: 700),
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
                        'Retinal Fundus Image Capture',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Patient: ${patient?.patientId ?? "N/A"} • Eye: ${patient?.eye ?? "OD"} • ID: ${session.screeningId ?? "Pending"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancel Session'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Viewfinder Framing Guide / Preview
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Captured image or camera simulation
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
                          color: Colors.black87.withOpacity(0.8),
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

              // Instructions Checklist Card
              ClinicalCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _guidanceItem(Icons.crop_free_rounded, 'Center retinal field'),
                    _guidanceItem(Icons.auto_fix_high_rounded, 'Maintain sharp focus'),
                    _guidanceItem(Icons.wb_sunny_outlined, 'Ensure illumination'),
                    _guidanceItem(Icons.vibration_rounded, 'Hold camera steady'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Sample Retinal Fundus Selector
              ClinicalCard(
                title: 'Select Verified Retinal Scenario (Demonstration / Evaluation)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose a curated fundus photograph to test the full quality & AI screening workflow:',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _scenarios.map((s) {
                        final bool isSelected = _selectedScenario?['id'] == s['id'];
                        final bool isUngradable = s['expectedLevel'] == -1;
                        final bool isReferable = (s['expectedLevel'] ?? 0) >= 2;

                        return ChoiceChip(
                          avatar: Icon(
                            isUngradable
                                ? Icons.warning_amber_rounded
                                : isReferable
                                    ? Icons.notification_important_rounded
                                    : Icons.check_circle_outline,
                            size: 16,
                            color: isSelected ? Colors.white : Colors.black54,
                          ),
                          label: Text(
                            s['title'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                          onSelected: (_) => _selectScenario(s),
                        );
                      }).toList(),
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
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _FundusReticlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.tealAccent.withOpacity(0.6)
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
