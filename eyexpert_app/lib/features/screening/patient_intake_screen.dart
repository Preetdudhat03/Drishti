import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/workflow_step_bar.dart';
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. STEP PROGRESS INDICATOR
              const WorkflowStepBar(currentStep: 1),
              const SizedBox(height: 16),

              // 2. HEADER
              const Text(
                'Patient & Screening Intake',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
              ),
              const SizedBox(height: 3),
              const Text(
                'Initialize patient record and designate examination eye before retinal imaging.',
                style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
              ),
              const SizedBox(height: 16),

              // 3. INTAKE FORM CONTAINER
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.deepSpace,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PATIENT IDENTIFIERS',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.darkTextSecondary, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _patientIdController,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: const InputDecoration(
                        labelText: 'Patient Identifier / Screening Token *',
                        prefixIcon: Icon(Icons.tag_rounded, size: 20, color: AppColors.hudCyan),
                        hintText: 'e.g. PT-2026-8819',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: const InputDecoration(
                              labelText: 'Age (Years)',
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGender,
                            dropdownColor: AppColors.deepSpace,
                            style: const TextStyle(color: Colors.white, fontSize: 13.5),
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.wc_rounded, size: 18),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'FEMALE', child: Text('Female', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'MALE', child: Text('Male', style: TextStyle(color: Colors.white))),
                              DropdownMenuItem(value: 'OTHER', child: Text('Other', style: TextStyle(color: Colors.white))),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedGender = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _diabetesDurationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5),
                      decoration: const InputDecoration(
                        labelText: 'Known Diabetes Duration (Years, Optional)',
                        prefixIcon: Icon(Icons.history_toggle_off_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. EYE SELECTION CONTAINER
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.deepSpace,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TARGET RETINAL FIELD',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.darkTextSecondary, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedEye = 'OD'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _selectedEye == 'OD' ? AppColors.obsidian : AppColors.graphite,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedEye == 'OD' ? AppColors.hudCyan : AppColors.borderDark,
                                  width: _selectedEye == 'OD' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: _selectedEye == 'OD' ? AppColors.hudCyan : AppColors.darkTextMuted,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'RIGHT EYE (OD)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: _selectedEye == 'OD' ? AppColors.hudCyan : Colors.white,
                                    ),
                                  ),
                                  const Text('Oculus Dexter', style: TextStyle(fontSize: 10.5, color: AppColors.darkTextMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedEye = 'OS'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                              decoration: BoxDecoration(
                                color: _selectedEye == 'OS' ? AppColors.obsidian : AppColors.graphite,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedEye == 'OS' ? AppColors.hudCyan : AppColors.borderDark,
                                  width: _selectedEye == 'OS' ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: _selectedEye == 'OS' ? AppColors.hudCyan : AppColors.darkTextMuted,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'LEFT EYE (OS)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: _selectedEye == 'OS' ? AppColors.hudCyan : Colors.white,
                                    ),
                                  ),
                                  const Text('Oculus Sinister', style: TextStyle(fontSize: 10.5, color: AppColors.darkTextMuted)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. SUBMIT ACTION
              ElevatedButton.icon(
                onPressed: _handleSubmit,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: const Text('PROCEED TO RETINAL IMAGE CAPTURE', style: TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
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
