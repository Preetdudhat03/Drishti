import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/clinical_card.dart';
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
  final _patientIdController = TextEditingController(text: 'PT-2026-8819');
  final _ageController = TextEditingController(text: '54');
  final _diabetesDurationController = TextEditingController(text: '8');
  String _selectedGender = 'FEMALE';
  String _selectedEye = 'OD'; // 'OD' (Right Eye) or 'OS' (Left Eye)

  @override
  void dispose() {
    _patientIdController.dispose();
    _ageController.dispose();
    _diabetesDurationController.dispose();
    super.dispose();
  }

  void _autofillDemoPatient(String id, String age, String gender, String duration, String eye) {
    setState(() {
      _patientIdController.text = id;
      _ageController.text = age;
      _selectedGender = gender;
      _diabetesDurationController.text = duration;
      _selectedEye = eye;
    });
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
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              const Text(
                'New Retinal Screening Session',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Enter minimal patient identifiers to initialize image capture session.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),

              // Demo Patient Quick Selection Pills
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.person_pin, size: 16),
                    label: const Text('Demo Pt #1 (OD - Moderate)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _autofillDemoPatient('PT-2026-8819', '54', 'FEMALE', '8', 'OD'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.person_pin, size: 16),
                    label: const Text('Demo Pt #2 (OS - Severe)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _autofillDemoPatient('PT-2026-7734', '62', 'MALE', '14', 'OS'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.person_pin, size: 16),
                    label: const Text('Demo Pt #3 (OD - Normal)', style: TextStyle(fontSize: 11)),
                    onPressed: () => _autofillDemoPatient('PT-2026-5402', '39', 'MALE', '2', 'OD'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Intake Form Card
              ClinicalCard(
                title: 'Patient Information',
                child: Column(
                  children: [
                    TextField(
                      controller: _patientIdController,
                      decoration: const InputDecoration(
                        labelText: 'Patient Identifier / Screening Token *',
                        prefixIcon: Icon(Icons.tag_rounded, size: 20),
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
                            decoration: const InputDecoration(
                              labelText: 'Age (Years)',
                              prefixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.wc_rounded, size: 18),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                              DropdownMenuItem(value: 'MALE', child: Text('Male')),
                              DropdownMenuItem(value: 'OTHER', child: Text('Other')),
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
                      decoration: const InputDecoration(
                        labelText: 'Known Diabetes Duration (Years, Optional)',
                        prefixIcon: Icon(Icons.history_toggle_off_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Eye Selection (OD / OS) Card
              ClinicalCard(
                title: 'Select Eye for Examination',
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedEye = 'OD'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            color: _selectedEye == 'OD' ? AppColors.primary.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedEye == 'OD' ? AppColors.primary : Colors.grey.shade300,
                              width: _selectedEye == 'OD' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.remove_red_eye_outlined,
                                color: _selectedEye == 'OD' ? AppColors.primary : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'RIGHT EYE (OD)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _selectedEye == 'OD' ? AppColors.primary : Colors.black87,
                                ),
                              ),
                              const Text('Oculus Dexter', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                            color: _selectedEye == 'OS' ? AppColors.primary.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedEye == 'OS' ? AppColors.primary : Colors.grey.shade300,
                              width: _selectedEye == 'OS' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.remove_red_eye_outlined,
                                color: _selectedEye == 'OS' ? AppColors.primary : Colors.grey,
                                size: 28,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'LEFT EYE (OS)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _selectedEye == 'OS' ? AppColors.primary : Colors.black87,
                                ),
                              ),
                              const Text('Oculus Sinister', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              PrimaryButton(
                text: 'Proceed to Retinal Image Capture',
                icon: Icons.camera_alt_rounded,
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
