import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/screening_case_model.dart';
import '../../data/models/clinician_review_model.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
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
        clinicalNotes: 'AI Level ${pred.drLevel} classification confirmed by reviewing clinician.',
        clinicianName: user?.name ?? 'Dr. Rajesh Kumar',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI screening result successfully validated.')),
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
        const SnackBar(content: Text('Clinical explanatory notes are mandatory when overriding an AI result.')),
      );
      return;
    }

    if (_overrideLevel == pred?.drLevel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Override level must differ from AI prediction. Use "Validate" if you agree.')),
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
          const SnackBar(content: Text('Clinician override decision submitted successfully.')),
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
        clinicalNotes: 'Marked ungradable by clinician. Clinical fundus photography recapture ordered.',
        clinicianName: user?.name ?? 'Dr. Rajesh Kumar',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case marked ungradable. Recapture required.')),
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
    final exp = c.explainability;
    final review = c.review;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinician Review • ${c.patient.patientId} (${c.patient.eye})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Screening ID: ${c.screeningId}',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          if (c.isReferable)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: StatusBadge.referable(label: 'PRIORITY: REFERABLE'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Side-by-Side Fundus & Grad-CAM Visuals
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Original Retinal Fundus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 240,
                        child: FundusImageViewer(
                          originalImagePath: c.image?.imageUrl ?? '',
                          eyeTag: c.patient.eye,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Grad-CAM Neural Attention Heatmap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 240,
                        child: FundusImageViewer(
                          originalImagePath: exp?.gradcamImageUrl ?? c.image?.imageUrl ?? '',
                          eyeTag: 'Grad-CAM XAI',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Two Cards: AI Screening Result vs Clinician Final Decision
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CARD 1: AI Screening Result
                Expanded(
                  child: ClinicalCard(
                    title: '1. AI Screening Result (Decision Support)',
                    backgroundColor: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              pred != null
                                  ? 'Level ${pred.drLevel} — ${pred.severityLabel}'
                                  : 'Inference Blocked',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.primary),
                            ),
                            if (pred != null)
                              StatusBadge(
                                label: pred.referable ? 'REFERABLE' : 'NON-REFERABLE',
                                color: pred.referable ? AppColors.referableAlert : AppColors.nonReferable,
                                backgroundColor: pred.referable ? AppColors.referableAlertBg : AppColors.nonReferableBg,
                                icon: Icons.insights_rounded,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pred != null) ...[
                          Text('Model Probability: ${AppFormatters.formatProbability(pred.modelProbability)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ProbabilityDistributionWidget(
                            classProbabilities: pred.classProbabilities,
                            predictedLevel: pred.drLevel,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // CARD 2: Clinician Final Decision
                Expanded(
                  child: ClinicalCard(
                    title: '2. Clinician Final Decision (Human Validation)',
                    backgroundColor: review != null ? Colors.blue.shade50 : Colors.amber.shade50,
                    borderColor: review != null ? Colors.blue.shade300 : Colors.amber.shade400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (review != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'STATUS: ${review.action.label}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.secondary),
                              ),
                              Text(
                                review.finalDrLevel != null ? 'Final: Level ${review.finalDrLevel}' : 'Ungradable',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Reviewer: ${review.clinicianName ?? "Ophthalmologist"}', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text('Clinical Notes: ${review.clinicalNotes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                          const SizedBox(height: 4),
                          Text('Reviewed At: ${AppFormatters.formatDateTime(review.reviewedAt)}',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                        ] else ...[
                          const Row(
                            children: [
                              Icon(Icons.pending_actions_rounded, color: Colors.amber, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Awaiting Clinician Validation',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Review the retinal fundus photograph and Grad-CAM neural activation map above. '
                            'Validate the AI finding or provide an override with explanatory notes.',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Override Selection Panel (when expanding override)
            if (_showOverrideModal) ...[
              ClinicalCard(
                title: 'Clinician Override Formulation',
                borderColor: AppColors.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select Final Clinical Retinopathy Level:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: List.generate(5, (lvl) {
                        final sev = DRSeverity.fromLevel(lvl);
                        final isSel = _overrideLevel == lvl;
                        return ChoiceChip(
                          label: Text('Level $lvl (${sev.shortName})'),
                          selected: isSel,
                          selectedColor: AppColors.secondary,
                          labelStyle: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                          onSelected: (val) {
                            if (val) setState(() => _overrideLevel = lvl);
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Mandatory Clinical Notes / Justification *',
                        hintText: 'Enter clinical observations (e.g., localized hemorrhages, exudates, maculopathy)...',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _showOverrideModal = false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _handleOverrideSubmit,
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text('Submit Final Override'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Rapid Review Decision Buttons
            if (!_showOverrideModal)
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: PrimaryButton(
                      text: 'Validate AI Result',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isSubmitting,
                      onPressed: _handleValidateAi,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: PrimaryButton(
                      text: 'Override AI Finding',
                      icon: Icons.edit_note_rounded,
                      isSecondary: true,
                      onPressed: () => setState(() => _showOverrideModal = true),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: PrimaryButton(
                      text: 'Mark Ungradable',
                      icon: Icons.highlight_off_rounded,
                      isDestructive: true,
                      isLoading: _isSubmitting,
                      onPressed: _handleMarkUngradable,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            const MedicalDisclaimerBanner(isCompact: true),
          ],
        ),
      ),
    );
  }
}
