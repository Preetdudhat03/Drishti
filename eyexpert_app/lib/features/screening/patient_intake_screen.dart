import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Screen Header Banner
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.laserBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Patient Intake & Initialization',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Initialize screening token and demographics for AI retinal pipeline',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Intake Form Card
              ClinicalCard(
                title: 'PATIENT DEMOGRAPHICS',
                titleAction: StatusBadge.aiBadge(label: 'TOKEN ID ACTIVE'),
                child: Column(
                  children: [
                    TextField(
                      controller: _patientIdController,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Patient Identifier / Screening Token *',
                        prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.laserBlue),
                        hintText: 'e.g. PT-2026-8819',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: 'Age (Years)',
                              prefixIcon: const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.textSecondary),
                              hintText: 'e.g. 52',
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: const Icon(Icons.wc_rounded, size: 18, color: AppColors.textSecondary),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'FEMALE', child: Text('Female', style: TextStyle(fontWeight: FontWeight.w600))),
                              DropdownMenuItem(value: 'MALE', child: Text('Male', style: TextStyle(fontWeight: FontWeight.w600))),
                              DropdownMenuItem(value: 'OTHER', child: Text('Other', style: TextStyle(fontWeight: FontWeight.w600))),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        labelText: 'Known Diabetes Duration (Years, Optional)',
                        prefixIcon: Icon(Icons.history_toggle_off_rounded, size: 20, color: AppColors.textSecondary),
                        hintText: 'e.g. 7',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Eye Selection (OD / OS) Card
              ClinicalCard(
                title: 'EXAMINATION EYE SELECTION',
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedEye = 'OD'),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                          decoration: BoxDecoration(
                            color: _selectedEye == 'OD' ? AppColors.accentLight : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedEye == 'OD' ? AppColors.laserBlue : AppColors.border,
                              width: _selectedEye == 'OD' ? 2 : 1.2,
                            ),
                            boxShadow: _selectedEye == 'OD'
                                ? [
                                    BoxShadow(
                                      color: AppColors.laserBlue.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
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
                                    color: _selectedEye == 'OD' ? AppColors.laserBlue : AppColors.textMuted,
                                    size: 26,
                                  ),
                                  if (_selectedEye == 'OD') ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle_rounded, color: AppColors.laserBlue, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'RIGHT EYE (OD)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: _selectedEye == 'OD' ? AppColors.laserBlue : AppColors.textPrimary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Oculus Dexter',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedEye == 'OD' ? AppColors.laserBlue.withValues(alpha: 0.8) : AppColors.textMuted,
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
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
                          decoration: BoxDecoration(
                            color: _selectedEye == 'OS' ? AppColors.accentLight : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedEye == 'OS' ? AppColors.laserBlue : AppColors.border,
                              width: _selectedEye == 'OS' ? 2 : 1.2,
                            ),
                            boxShadow: _selectedEye == 'OS'
                                ? [
                                    BoxShadow(
                                      color: AppColors.laserBlue.withValues(alpha: 0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
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
                                    color: _selectedEye == 'OS' ? AppColors.laserBlue : AppColors.textMuted,
                                    size: 26,
                                  ),
                                  if (_selectedEye == 'OS') ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.check_circle_rounded, color: AppColors.laserBlue, size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'LEFT EYE (OS)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: _selectedEye == 'OS' ? AppColors.laserBlue : AppColors.textPrimary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Oculus Sinister',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _selectedEye == 'OS' ? AppColors.laserBlue.withValues(alpha: 0.8) : AppColors.textMuted,
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
              const SizedBox(height: 22),

              PrimaryButton(
                text: 'Initialize & Proceed to Retinal Capture',
                icon: Icons.camera_enhance_rounded,
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
