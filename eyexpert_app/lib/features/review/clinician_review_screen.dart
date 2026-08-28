import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../data/models/screening_case_model.dart';
import '../../data/models/clinician_review_model.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
import '../../shared/widgets/probability_bar.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../auth/auth_provider.dart';
import 'review_queue_provider.dart';

class ClinicianReviewScreen extends ConsumerStatefulWidget {
  final ScreeningCaseModel screeningCase;
  final VoidCallback onReviewSubmitted;
  final VoidCallback onBack;

  const ClinicianReviewScreen({
    super.key,
    required this.screeningCase,
    required this.onReviewSubmitted,
    required this.onBack,
  });

  @override
  ConsumerState<ClinicianReviewScreen> createState() => _ClinicianReviewScreenState();
}

class _ClinicianReviewScreenState extends ConsumerState<ClinicianReviewScreen> {
  final _notesController = TextEditingController();
  int? _overrideLevel;
  bool _isSubmitting = false;
  bool _showOverrideModal = false;

  @override
  void initState() {
    super.initState();
    _overrideLevel = widget.screeningCase.prediction?.drLevel ?? 0;
    if (widget.screeningCase.review != null) {
      _notesController.text = widget.screeningCase.review!.clinicalNotes;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleValidateAi() async {
    final pred = widget.screeningCase.prediction;
    if (pred == null) return;

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(authProvider).user;
      await ref.read(reviewQueueProvider.notifier).submitClinicianDecision(
        screeningId: widget.screeningCase.screeningId,
        action: ClinicianAction.validateAiResult,
        finalDrLevel: pred.drLevel,
        clinicalNotes: 'AI Level ${pred.drLevel} classification confirmed by reviewing ophthalmologist.',
        clinicianName: user?.name ?? 'Dr. Rajesh Kumar',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ AI screening result confirmed and validated.')),
        );
        widget.onReviewSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleOverrideSubmit() async {
    final pred = widget.screeningCase.prediction;
    if (_notesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clinical notes are mandatory when overriding an AI prediction.')),
      );
      return;
    }

    if (_overrideLevel == pred?.drLevel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Override level must differ from AI prediction. Select Validate AI Result if you agree.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(authProvider).user;
      await ref.read(reviewQueueProvider.notifier).submitClinicianDecision(
        screeningId: widget.screeningCase.screeningId,
        action: ClinicianAction.override,
        finalDrLevel: _overrideLevel,
        clinicalNotes: _notesController.text.trim(),
        clinicianName: user?.name ?? 'Dr. Rajesh Kumar',
      );

      if (mounted) {
        setState(() => _showOverrideModal = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Clinician override decision recorded successfully.')),
        );
        widget.onReviewSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleMarkUngradable() async {
    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(authProvider).user;
      await ref.read(reviewQueueProvider.notifier).submitClinicianDecision(
        screeningId: widget.screeningCase.screeningId,
        action: ClinicianAction.markUngradable,
        finalDrLevel: null,
        clinicalNotes: 'Marked ungradable by reviewing clinician. Recapture required.',
        clinicianName: user?.name ?? 'Dr. Rajesh Kumar',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case marked as UNGRADABLE. Notification sent for recapture.')),
        );
        widget.onReviewSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.screeningCase;
    final pred = c.prediction;
    final quality = c.quality;
    final patient = c.patient;
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final severity = pred != null ? DRSeverity.fromLevel(pred.drLevel) : null;
    final isReferable = pred?.isReferable ?? false;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 12, vertical: isDesktop ? 20 : 14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. WORKSTATION TOP BAR
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    tooltip: 'Back to Review Queue',
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clinician Review Workstation',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.3),
                        ),
                        Text(
                          'Case: ${c.screeningId} | ${patient.patientId} | ${patient.eye}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusTag(c.status.label),
                ],
              ),
              const SizedBox(height: 14),

              // 2. MAIN 3-PANE WORKSTATION (Desktop: 3 Panes, Mobile: Stacked)
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pane 1: Original Retinal Image (35% width)
                    Expanded(
                      flex: 36,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _paneHeader('01. OPTICAL RETINAL VIEWPORT'),
                          const SizedBox(height: 8),
                          FundusImageViewer(
                            originalImagePath: c.imagePath ?? '',
                            mode: FundusViewerMode.original,
                            height: 440,
                            eyeTag: patient.eye,
                            imageId: c.screeningId,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Pane 2: Grad-CAM Explainability Heatmap (34% width)
                    Expanded(
                      flex: 34,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _paneHeader('02. GRAD-CAM ATTRIBUTION MAP'),
                          const SizedBox(height: 8),
                          FundusImageViewer(
                            originalImagePath: c.imagePath ?? '',
                            gradcamImagePath: pred?.heatmapPath,
                            mode: pred?.heatmapPath != null ? FundusViewerMode.overlay : FundusViewerMode.original,
                            height: 440,
                            eyeTag: '${patient.eye} Grad-CAM',
                            imageId: c.screeningId,
                            showControls: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Pane 3: AI Diagnosis & Clinician Actions (30% width)
                    Expanded(
                      flex: 30,
                      child: _buildDecisionPane(pred, severity, isReferable),
                    ),
                  ],
                )
              else ...[
                // Mobile Stacked Workstation
                FundusImageViewer(
                  originalImagePath: c.imagePath ?? '',
                  gradcamImagePath: pred?.heatmapPath,
                  mode: FundusViewerMode.overlay,
                  height: 360,
                  eyeTag: patient.eye,
                  imageId: c.screeningId,
                  showControls: true,
                ),
                const SizedBox(height: 16),
                _buildDecisionPane(pred, severity, isReferable),
              ],
              const SizedBox(height: 20),

              const MedicalDisclaimerBanner(isCompact: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paneHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.deepSpace,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.hudCyan, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildDecisionPane(dynamic pred, DRSeverity? severity, bool isReferable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. AI PREDICTION SUMMARY
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI SCREENING SUMMARY',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),
              if (severity != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${pred.drLevel}: ${severity.shortName}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isReferable ? AppColors.referableAlert : AppColors.statusGood),
                    ),
                    Text(
                      AppFormatters.formatProbability(pred.modelProbability),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (pred.probabilities != null && pred.probabilities!.isNotEmpty)
                  ProbabilityDistributionWidget(
                    probabilities: pred.probabilities!,
                    predictedLevel: pred.drLevel,
                    isDarkMode: false,
                  ),
              ] else
                const Text('No AI classification available', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. CLINICAL DECISION ACTION BUTTONS (NO PLACEHOLDERS)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'CLINICIAN DECISION',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(height: 12),

              // Validate AI Button
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _handleValidateAi,
                icon: const Icon(Icons.verified_rounded, size: 18),
                label: const Text('VALIDATE AI RESULT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusGood,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),

              // Override Button
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : () => setState(() => _showOverrideModal = !_showOverrideModal),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('OVERRIDE DR LEVEL'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.electricBlue,
                  side: const BorderSide(color: AppColors.electricBlue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 10),

              // Mark Ungradable Button
              OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _handleMarkUngradable,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('MARK UNGRADABLE (RETAKE)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.statusUngradable,
                  side: const BorderSide(color: AppColors.statusUngradable),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),

              // Override Form Sub-Panel
              if (_showOverrideModal) ...[
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'SELECT CLINICIAN DR LEVEL:',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  value: _overrideLevel,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Level 0: No DR')),
                    DropdownMenuItem(value: 1, child: Text('Level 1: Mild NPDR')),
                    DropdownMenuItem(value: 2, child: Text('Level 2: Moderate NPDR (Referable)')),
                    DropdownMenuItem(value: 3, child: Text('Level 3: Severe NPDR (Referable)')),
                    DropdownMenuItem(value: 4, child: Text('Level 4: Proliferative DR (Urgent)')),
                  ],
                  onChanged: (val) => setState(() => _overrideLevel = val),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Mandatory Clinical Rationale *',
                    hintText: 'Enter clinical justification for override...',
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleOverrideSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('CONFIRM CLINICIAN OVERRIDE'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.electricBlue),
      ),
    );
  }
}
