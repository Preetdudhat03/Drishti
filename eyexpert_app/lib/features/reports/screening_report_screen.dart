import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/screening_case_model.dart';
import '../../data/services/report_service.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../screening/screening_session_provider.dart';

class ScreeningReportScreen extends ConsumerStatefulWidget {
  final ScreeningCaseModel? screeningCase;
  final VoidCallback onBack;

  const ScreeningReportScreen({
    super.key,
    this.screeningCase,
    required this.onBack,
  });

  @override
  ConsumerState<ScreeningReportScreen> createState() => _ScreeningReportScreenState();
}

class _ScreeningReportScreenState extends ConsumerState<ScreeningReportScreen> {
  bool _isExporting = false;

  ScreeningCaseModel _getCase() {
    if (widget.screeningCase != null) {
      return widget.screeningCase!;
    }
    final sessionCase = ref.read(screeningSessionProvider).toScreeningCase();
    if (sessionCase != null) return sessionCase;

    // Fallback template
    return ScreeningCaseModel(
      screeningId: 'EX-2026-000124',
      patient: PatientModel(
        patientId: 'PT-2026-8819',
        age: 54,
        gender: 'FEMALE',
        diabetesDurationYears: 8,
        eye: 'OD',
        facilityId: 'PHC-RAMGARH-01',
        createdAt: DateTime.now(),
      ),
      status: ScreeningStatus.readyForReview,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _handlePrint() async {
    setState(() => _isExporting = true);
    try {
      final c = _getCase();
      await ReportService.printReport(c);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _handleShare() async {
    setState(() => _isExporting = true);
    try {
      final c = _getCase();
      await ReportService.shareReport(c);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _getCase();
    final pred = c.prediction;
    final quality = c.quality;
    final review = c.review;
    final isReferable = pred?.referable ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Screen Navigation Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    tooltip: 'Back',
                  ),
                  const Text(
                    'Screening Summary Report',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _handlePrint,
                    icon: const Icon(Icons.print_outlined),
                    tooltip: 'Print Report',
                  ),
                  IconButton(
                    onPressed: _handleShare,
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Export PDF',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Printable Document Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              AppConstants.appName,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            const Text(
                              AppConstants.appTagline,
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Screening ID: ${c.screeningId}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        isReferable
                            ? StatusBadge.referable()
                            : StatusBadge.nonReferable(),
                      ],
                    ),
                    const Divider(height: 24),

                    // Patient Meta Table
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _infoBlock('Patient ID', c.patient.patientId),
                          _infoBlock('Age / Gender', '${c.patient.age ?? "N/A"} / ${c.patient.gender ?? "N/A"}'),
                          _infoBlock('Eye Examined', AppFormatters.formatEye(c.patient.eye)),
                          _infoBlock('Screening Date', AppFormatters.formatDateTime(c.createdAt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 1: Image Quality
                    const Text('1. Image Quality Assessment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Overall Status: ${quality?.status.label ?? "GOOD"} (${AppFormatters.formatPercentage(quality?.overallScore)})'),
                        Text('Focus: ${quality?.sharpness.status ?? "GOOD"}'),
                        Text('Illumination: ${quality?.illumination.status ?? "GOOD"}'),
                        Text('FOV: ${quality?.fieldOfView.status ?? "ADEQUATE"}'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 2: AI Retinopathy Classification
                    const Text('2. AI Retinopathy Classification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                pred != null
                                    ? 'Level ${pred.drLevel} — ${pred.severityLabel}'
                                    : 'Classification Blocked (Ungradable Quality)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (pred != null)
                                Text(
                                  'Model Probability: ${AppFormatters.formatProbability(pred.modelProbability)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Recommendation: ${pred?.recommendation ?? "Recapture retinal image."}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Clinician Final Decision
                    const Text('3. Clinician Final Decision (Human-in-the-Loop)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: review != null ? Colors.blue.shade50 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: review != null ? Colors.blue.shade200 : Colors.amber.shade300,
                        ),
                      ),
                      child: review != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Action: ${review.action.label}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('Reviewer: ${review.clinicianName ?? "Ophthalmologist"}',
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Clinical Notes: ${review.clinicalNotes}',
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text('Reviewed At: ${AppFormatters.formatDateTime(review.reviewedAt)}',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                              ],
                            )
                          : const Row(
                              children: [
                                Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Human Validation State: PENDING OPHTHALMOLOGIST REVIEW',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Model Provenance
                    const Text('4. Model Provenance & Traceability',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    const Text(
                      'Model: EyeXpert DR Classifier (ResNet-18) | Training Dataset: APTOS 2019 Blindness Detection | Target Layer: layer4[1].conv2',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Statutory Disclaimer
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        AppConstants.standardDisclaimer,
                        style: TextStyle(fontSize: 10, color: Colors.black87, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Row
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      text: 'Print Clinical Report',
                      icon: Icons.print_rounded,
                      isLoading: _isExporting,
                      onPressed: _handlePrint,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      text: 'Export / Share PDF',
                      icon: Icons.share_rounded,
                      isSecondary: true,
                      isLoading: _isExporting,
                      onPressed: _handleShare,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
