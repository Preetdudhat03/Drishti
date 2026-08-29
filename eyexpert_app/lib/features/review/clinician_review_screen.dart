import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive_layout.dart';
import '../../data/models/screening_case_model.dart';
import '../../data/models/clinician_review_model.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/fundus_image_viewer.dart';
import '../../shared/widgets/probability_bar.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../auth/auth_provider.dart';
import '../reports/screening_report_screen.dart';
import 'review_queue_provider.dart';
import '../../shared/widgets/connection_status_pill.dart';

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

  void _openFullReport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SafeArea(
            child: ScreeningReportScreen(
              screeningCase: widget.screeningCase,
              onBack: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleValidateAi() async {
    final pred = widget.screeningCase.prediction;
    if (pred == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF991B1B),
          content: Text('AI inference is still pending or ungradable. Please complete AI processing before validating.'),
        ),
      );
      return;
    }

    final drLevel = pred.drLevel;
    setState(() => _isSubmitting = true);
    try {
      final user = ref.read(authProvider).user;
      await ref.read(reviewQueueProvider.notifier).submitClinicianDecision(
        screeningId: widget.screeningCase.screeningId,
        action: ClinicianAction.validateAiResult,
        finalDrLevel: drLevel,
        clinicalNotes: 'AI Level $drLevel (${pred.severityLabel}) classification confirmed and validated by reviewing clinician.',
        clinicianName: user?.name ?? 'Dr. Rajesh Kumar',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF166534),
            content: Text('✓ AI screening result confirmed and validated.'),
          ),
        );
        widget.onReviewSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF991B1B),
            content: Text('Submission error: $e'),
          ),
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
          const SnackBar(content: Text('Case marked ungradable. Clinical recapture notification sent.')),
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
    final isDesktop = ResponsiveLayout.isDesktop(context);

    Widget imageComparisonWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORIGINAL RETINAL FUNDUS', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    height: isDesktop ? 280 : 200,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FundusImageViewer(
                        originalImagePath: (c.image?.imageUrl.isNotEmpty == true)
                            ? c.image!.imageUrl
                            : (exp?.originalImageUrl.isNotEmpty == true)
                                ? exp!.originalImageUrl
                                : (exp?.overlayImageUrl.isNotEmpty == true)
                                    ? exp!.overlayImageUrl
                                    : 'assets/sample_fundus/sample_good_npdr_moderate.png',
                        eyeTag: c.patient.eye,
                      ),
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
                  const Text('GRAD-CAM NEURAL ATTENTION', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    height: isDesktop ? 280 : 200,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: FundusImageViewer(
                        originalImagePath: (exp?.gradcamImageUrl.isNotEmpty == true)
                            ? exp!.gradcamImageUrl
                            : (exp?.overlayImageUrl.isNotEmpty == true)
                                ? exp!.overlayImageUrl
                                : (c.image?.imageUrl.isNotEmpty == true)
                                    ? c.image!.imageUrl
                                    : 'assets/sample_fundus/sample_good_npdr_moderate.png',
                        eyeTag: 'Grad-CAM XAI',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    Widget decisionControlWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AI Screening Card
        ClinicalCard(
          title: 'AI SCREENING (DECISION SUPPORT)',
          titleAction: StatusBadge.aiBadge(label: 'AI FINDING'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      pred != null
                          ? 'Level ${pred.drLevel} — ${pred.severityLabel}'
                          : (c.quality?.isUngradable ?? false)
                              ? 'Inference Blocked (Image Ungradable)'
                              : 'Awaiting AI Analysis',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (pred != null)
                    pred.referable
                        ? StatusBadge.referable(label: 'REFERABLE')
                        : StatusBadge.nonReferable(label: 'NON-REFERABLE'),
                ],
              ),
              const SizedBox(height: 8),
              if (pred != null) ...[
                Text('Model Probability: ${AppFormatters.formatProbability(pred.modelProbability)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
                const SizedBox(height: 8),
                ProbabilityDistributionWidget(
                  classProbabilities: pred.classProbabilities,
                  predictedLevel: pred.drLevel,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Clinician Final Decision Card
        ClinicalCard(
          title: 'FINAL CLINICIAN DECISION',
          titleAction: StatusBadge.clinicianBadge(),
          backgroundColor: review != null ? AppColors.accentLight.withValues(alpha: 0.5) : Colors.white,
          borderColor: review != null ? AppColors.accent : AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (review != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'STATUS: ${review.action.label.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.accent),
                    ),
                    Text(
                      review.finalDrLevel != null ? 'Validated Level ${review.finalDrLevel}' : 'Ungradable',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text('Reviewing Ophthalmologist: ${review.clinicianName ?? "Dr. Rajesh Kumar"}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Clinical Notes: "${review.clinicalNotes}"',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Timestamp: ${AppFormatters.formatDateTime(review.reviewedAt)}',
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: AppColors.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'AI assists. Doctor decides.',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Review the fundus photograph and Grad-CAM neural attention map. Validate the AI finding or formulate an override with clinical notes.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Override Expansion Drawer
        if (_showOverrideModal) ...[
          ClinicalCard(
            title: 'Formulate Clinician Override',
            borderColor: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Final Clinical DR Level:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: List.generate(5, (lvl) {
                    final sev = DRSeverity.fromLevel(lvl);
                    final isSel = _overrideLevel == lvl;
                    return ChoiceChip(
                      label: Text('Level $lvl (${sev.shortName})'),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
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
                    labelText: 'Mandatory Clinical Notes / Diagnostic Rationale *',
                    hintText: 'Enter clinical observations (e.g., localized microaneurysms, hemorrhages, macular edema)...',
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
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Decision Action Buttons vs Finalized Banner
        if (!_showOverrideModal) ...[
          if (review != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clinical Review Finalized & Signed',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Signed by ${review.clinicianName ?? "Ophthalmologist"} • ${AppFormatters.formatDateTime(review.reviewedAt)}',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _overrideLevel = review.finalDrLevel ?? pred?.drLevel ?? 0;
                      _notesController.text = review.clinicalNotes;
                      _showOverrideModal = true;
                    }),
                    icon: const Icon(Icons.edit_note_rounded, size: 16),
                    label: const Text('Amend Decision', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: PrimaryButton(
                    text: '✓ Validate AI Result',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _handleValidateAi,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: PrimaryButton(
                    text: 'Override',
                    icon: Icons.edit_note_rounded,
                    isSecondary: true,
                    onPressed: () => setState(() => _showOverrideModal = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: PrimaryButton(
                    text: 'Ungradable',
                    icon: Icons.highlight_off_rounded,
                    isDestructive: true,
                    isLoading: _isSubmitting,
                    onPressed: _handleMarkUngradable,
                  ),
                ),
              ],
            ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openFullReport,
            icon: const Icon(Icons.description_outlined, size: 18),
            label: const Text(
              'VIEW FULL CLINICAL REPORT (PDF / PRINT)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.3),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );

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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text('Screening ID: ${c.screeningId}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openFullReport,
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white),
            tooltip: 'View Full Patient Report (PDF / Print)',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: ConnectionStatusPill(isCompact: true),
          ),
          if (c.isReferable)
            Container(
              margin: const EdgeInsets.only(right: 12),
              child: StatusBadge.referable(label: 'PRIORITY: REFERABLE'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isDesktop) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: imageComparisonWidget),
                      const SizedBox(width: 16),
                      Expanded(flex: 5, child: decisionControlWidget),
                    ],
                  ),
                ] else ...[
                  imageComparisonWidget,
                  const SizedBox(height: 14),
                  decisionControlWidget,
                ],
                const SizedBox(height: 16),
                const MedicalDisclaimerBanner(isCompact: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
