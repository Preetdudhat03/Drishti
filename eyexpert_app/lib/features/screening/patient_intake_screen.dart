import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/services/audio_guidance_service.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../../shared/widgets/screening_workflow_ribbon.dart';
import 'screening_session_provider.dart';

class PatientIntakeScreen extends ConsumerStatefulWidget {
  final VoidCallback onProceedToCapture;

  const PatientIntakeScreen({super.key, required this.onProceedToCapture});

  @override
  ConsumerState<PatientIntakeScreen> createState() => _PatientIntakeScreenState();
}

class _PatientIntakeScreenState extends ConsumerState<PatientIntakeScreen> {
  late final TextEditingController _patientIdController;
  final _ageController = TextEditingController();
  final _diabetesDurationController = TextEditingController();
  String _selectedGender = 'FEMALE';
  String _selectedEye = 'OD'; // 'OD' (Right Eye) or 'OS' (Left Eye)

  @override
  void initState() {
    super.initState();
    _patientIdController = TextEditingController(
      text: 'PT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
  }

  @override
  void dispose() {
    _patientIdController.dispose();
    _ageController.dispose();
    _diabetesDurationController.dispose();
    super.dispose();
  }

  void _fillDemoPatient() {
    setState(() {
      _patientIdController.text = 'PT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      _ageController.text = '54';
      _selectedGender = 'FEMALE';
      _diabetesDurationController.text = '8';
      _selectedEye = 'OD';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('Demo patient loaded: Kamla Devi, 54y, Diabetic 8y, Right Eye (OD)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _speakIntakeGuidance() {
    final lang = ref.read(localeProvider);
    if (lang == 'hi') {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'मरीज का टोकन नंबर, आयु और जांच हेतु आंख का चयन करें।',
      );
    } else if (lang == 'mr') {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'रुग्णाचा तपशील भरा आणि तपासणीसाठी डोळा निवडा.',
      );
    } else if (lang == 'gu') {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'દર્દીની વિગતો ભરો અને તપાસ માટે આંખ પસંદ કરો.',
      );
    } else if (lang == 'ta') {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'நோயாளி விவரங்களை உள்ளிட்டு பரிசோதனைக்கான கண்ணை தேர்வு செய்யவும்.',
      );
    } else {
      ref.read(activeAudioCueProvider.notifier).announce(
        text: 'Enter patient screening ID, age, and select examination eye (OD/OS).',
      );
    }
  }

  void _handleSubmit() {
    final patientId = _patientIdController.text.trim();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Patient ID')),
      );
      return;
    }

    final int? age = int.tryParse(_ageController.text);
    final int? duration = int.tryParse(_diabetesDurationController.text);

    ref.read(screeningSessionProvider.notifier).startNewSession(
      patientId: patientId,
      age: age,
      gender: _selectedGender,
      diabetesDurationYears: duration,
      eye: _selectedEye,
    );

    widget.onProceedToCapture();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: ResponsiveLayout.pagePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 3-Step Guided Flow Ribbon (Active on Step 1)
              const ScreeningWorkflowRibbon(activeStep: 1),

              // 2. Action Strip: Speak Guidance + Fill Demo Patient
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _speakIntakeGuidance,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_up_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 5),
                          Text(
                            tr('speak_guidance'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _fillDemoPatient,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFFD97706)),
                          const SizedBox(width: 4),
                          Text(
                            tr('fill_demo'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Intake Form Card
              ClinicalCard(
                title: tr('patient_demographics'),
                titleAction: StatusBadge.aiBadge(label: 'TOKEN ACTIVE'),
                child: Column(
                  children: [
                    TextField(
                      controller: _patientIdController,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: '${tr('patient_id')} *',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
                        hintText: 'e.g. PT-2026-8819',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: tr('age'),
                              prefixIcon: const Icon(Icons.cake_outlined, size: 20, color: AppColors.textSecondary),
                              hintText: 'e.g. 54',
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.surfaceMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 6,
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              labelText: tr('gender'),
                              prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textSecondary),
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.surfaceMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(value: 'FEMALE', child: Text(tr('gender_female'))),
                              DropdownMenuItem(value: 'MALE', child: Text(tr('gender_male'))),
                              DropdownMenuItem(value: 'OTHER', child: Text(tr('gender_other'))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedGender = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _diabetesDurationController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr('diabetes_duration'),
                        prefixIcon: const Icon(Icons.history_toggle_off_rounded, size: 20, color: AppColors.textSecondary),
                        hintText: 'e.g. 7 (Optional)',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surfaceMuted,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Examination Eye Selection (OD / OS) Card
              ClinicalCard(
                title: tr('eye_selection'),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedEye = 'OD'),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                          decoration: BoxDecoration(
                            color: _selectedEye == 'OD' ? AppColors.primaryLight : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedEye == 'OD' ? AppColors.primary : AppColors.border,
                              width: _selectedEye == 'OD' ? 2 : 1.2,
                            ),
                            boxShadow: _selectedEye == 'OD'
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.16),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.remove_red_eye_rounded,
                                    color: _selectedEye == 'OD' ? AppColors.primary : AppColors.textMuted,
                                    size: 28,
                                  ),
                                  if (_selectedEye == 'OD') ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                tr('right_eye'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: _selectedEye == 'OD' ? AppColors.primary : AppColors.textPrimary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tr('od_subtitle'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedEye == 'OD'
                                      ? AppColors.primary.withValues(alpha: 0.85)
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedEye = 'OS'),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
                          decoration: BoxDecoration(
                            color: _selectedEye == 'OS' ? AppColors.primaryLight : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedEye == 'OS' ? AppColors.primary : AppColors.border,
                              width: _selectedEye == 'OS' ? 2 : 1.2,
                            ),
                            boxShadow: _selectedEye == 'OS'
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.16),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.remove_red_eye_rounded,
                                    color: _selectedEye == 'OS' ? AppColors.primary : AppColors.textMuted,
                                    size: 28,
                                  ),
                                  if (_selectedEye == 'OS') ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                tr('left_eye'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: _selectedEye == 'OS' ? AppColors.primary : AppColors.textPrimary,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tr('os_subtitle'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedEye == 'OS'
                                      ? AppColors.primary.withValues(alpha: 0.85)
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Submit CTA
              PrimaryButton(
                text: tr('proceed_capture'),
                icon: Icons.camera_enhance_rounded,
                useGradient: true,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 16),

              const MedicalDisclaimerBanner(isCompact: true),
            ],
          ),
        ),
      ),
    );
  }
}
