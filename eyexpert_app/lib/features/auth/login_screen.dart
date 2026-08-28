import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController(text: 'healthworker.demo@eyexpert');
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
                  // App Icon & Branding
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.remove_red_eye_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: const Text(
                        AppConstants.sihProblemStatement,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Quick Demo Account Selection Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.touch_app_rounded, size: 16, color: AppColors.secondary),
                            SizedBox(width: 6),
                            Text(
                              'QUICK DEMO ACCESS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _quickDemoLogin(UserRole.healthWorker),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  side: BorderSide(
                                    color: _selectedRole == UserRole.healthWorker
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    width: _selectedRole == UserRole.healthWorker ? 2 : 1,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Text('Health Worker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('Sunita Sharma', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _quickDemoLogin(UserRole.clinician),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  side: BorderSide(
                                    color: _selectedRole == UserRole.clinician
                                        ? AppColors.primary
                                        : Colors.grey.shade300,
                                    width: _selectedRole == UserRole.clinician ? 2 : 1,
                                  ),
                                ),
                                child: const Column(
                                  children: [
                                    Text('Ophthalmologist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('Dr. Rajesh Kumar', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Login Form
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username or Health Worker ID',
                      prefixIcon: Icon(Icons.badge_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.statusUngradableBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(color: AppColors.statusUngradable, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  PrimaryButton(
                    text: 'Sign In to EyeXpert',
                    onPressed: _handleLogin,
                    isLoading: authState.isLoading,
                    icon: Icons.login_rounded,
                  ),
                  const SizedBox(height: 24),

                  const MedicalDisclaimerBanner(isCompact: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
