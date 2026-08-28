import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/user_model.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../../shared/widgets/drishti_logo.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'healthworker.demo@drishti.org');
  final _passwordController = TextEditingController(text: '••••••••');
  UserRole _selectedRole = UserRole.healthWorker;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    ref.read(authProvider.notifier).login(
      username: _usernameController.text,
      password: _passwordController.text,
      roleRequested: _selectedRole,
      isDemo: true,
    );
  }

  void _quickDemoLogin(UserRole role) {
    setState(() {
      _selectedRole = role;
      if (role == UserRole.clinician) {
        _usernameController.text = 'clinician.demo@eyexpert';
      } else {
        _usernameController.text = 'healthworker.demo@eyexpert';
      }
    });
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Minimal EyeXpert Logo
                  const Center(
                    child: EyeXpertLogo(
                      size: 48,
                      showText: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Clinical Intelligence + Human Care',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'SIH 2026 | PS-26038',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Form Card
                  ClinicalCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Workstation Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Role Selector
                        SegmentedButton<UserRole>(
                          segments: const [
                            ButtonSegment(
                              value: UserRole.healthWorker,
                              label: Text('Health Worker'),
                              icon: Icon(Icons.health_and_safety_outlined, size: 16),
                            ),
                            ButtonSegment(
                              value: UserRole.clinician,
                              label: Text('Clinician'),
                              icon: Icon(Icons.medical_services_outlined, size: 16),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (set) {
                            setState(() {
                              _selectedRole = set.first;
                              if (_selectedRole == UserRole.clinician) {
                                _usernameController.text = 'clinician.demo@eyexpert';
                              } else {
                                _usernameController.text = 'healthworker.demo@eyexpert';
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _usernameController,
                          decoration: const InputDecoration(
                            labelText: 'Username / Email',
                            prefixIcon: Icon(Icons.person_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline, size: 20),
                          ),
                        ),
                        const SizedBox(height: 18),

                        PrimaryButton(
                          text: 'Sign In to Screening Workstation',
                          isLoading: authState.isLoading,
                          onPressed: _handleLogin,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Demo Quick Launch Box
                  ClinicalCard(
                    backgroundColor: AppColors.accentLight.withOpacity(0.4),
                    borderColor: AppColors.accent.withOpacity(0.3),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.play_circle_fill_rounded, size: 16, color: AppColors.accent),
                            SizedBox(width: 6),
                            Text(
                              'DEMO QUICK LAUNCH',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _quickDemoLogin(UserRole.healthWorker),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                child: const Text(
                                  'Demo Health Worker\n(Sunita Sharma)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _quickDemoLogin(UserRole.clinician),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.border),
                                ),
                                child: const Text(
                                  'Demo Clinician\n(Dr. Rajesh Kumar)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const MedicalDisclaimerBanner(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
