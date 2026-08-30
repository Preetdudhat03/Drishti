import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../shared/widgets/drishti_logo.dart';
import 'auth_provider.dart';
import 'widgets/retinal_visual_panel.dart';

class ClinicianLoginScreen extends ConsumerStatefulWidget {
  const ClinicianLoginScreen({super.key});

  @override
  ConsumerState<ClinicianLoginScreen> createState() => _ClinicianLoginScreenState();
}

class _ClinicianLoginScreenState extends ConsumerState<ClinicianLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registrationIdController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _registrationIdController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    ref.read(authProvider.notifier).clearError();
    final success = await ref.read(authProvider.notifier).login(
      username: _emailController.text.trim(),
      password: _passwordController.text,
      roleRequested: UserRole.clinician,
      medicalRegistrationId: _registrationIdController.text.trim().isNotEmpty
          ? _registrationIdController.text.trim()
          : null,
    );

    if (success) {
      final user = ref.read(authProvider).user;
      if (user != null && user.role != UserRole.clinician) {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.statusCritical,
              content: Text(
                'Access Denied: Specialist review workstation requires Ophthalmologist credentials. Please use the Drishti PHC application.',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.obsidianDeep,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth >= 960;

            if (isWideScreen) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Specialist Login Form
                        Expanded(
                          flex: 5,
                          child: _buildLoginForm(context, authState),
                        ),
                        const SizedBox(width: 32),

                        // Right: Visual Retinal Workstation Canvas
                        const Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 700,
                            child: RetinalVisualPanel(activeRole: UserRole.clinician),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Mobile / Narrow Viewport
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildLoginForm(context, authState),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.obsidianCanvas,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.obsidianBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Drishti Logo + Specialist Badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const DrishtiLogo(
                  size: 36,
                  showText: true,
                  textColor: AppColors.textBright,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.aiViolet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.aiViolet.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'OPHTHALMOLOGIST PORTAL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.aiViolet,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-Assisted Retinal Diagnostic Review Workstation',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 22),

            // Specialist Clearance Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.aiViolet.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.aiViolet.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.remove_red_eye_outlined,
                    size: 18,
                    color: AppColors.aiViolet,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPECIALIST CLINICAL WORKSPACE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.aiViolet,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Review Queue • Grad-CAM Layer-4 • Diagnostic Override • Tele-Reporting',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Input 1: Professional Email / Clinician ID
            const Text(
              'PROFESSIONAL EMAIL / CLINICIAN ID',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSubtle,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: AppColors.textBright, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'clinician@retina-hospital.org',
                hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13.5),
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textSubtle, size: 18),
                fillColor: AppColors.obsidianSurface,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.obsidianBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.obsidianBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.aiViolet, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input 2: Password
            const Text(
              'PASSWORD',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSubtle,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: AppColors.textBright, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter specialist access password',
                hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13.5),
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSubtle, size: 18),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.textSubtle,
                    size: 18,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                fillColor: AppColors.obsidianSurface,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.obsidianBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.obsidianBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.aiViolet, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Input 3: Medical Registration ID (Optional)
            const Text(
              'MEDICAL COUNCIL REGISTRATION ID (OPTIONAL)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSubtle,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _registrationIdController,
              style: const TextStyle(color: AppColors.textBright, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. MCI-2018-84729 / State Council',
                hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 13.5),
                prefixIcon: const Icon(Icons.verified_outlined, color: AppColors.textSubtle, size: 18),
                fillColor: AppColors.obsidianSurface,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.obsidianBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.obsidianBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.aiViolet, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Error Display Banner
            if (authState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.statusCritical.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.statusCritical.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.statusCritical,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        authState.errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textBright,
                          height: 1.4,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(authProvider.notifier).clearError(),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textSubtle,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Submit Button
            ElevatedButton(
              onPressed: authState.isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.aiViolet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: authState.isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          authState.authenticatingMessage ?? 'AUTHENTICATING...',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_open_outlined, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Sign In to Specialist Review Portal',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // Safety & Governance Footer
            const Center(
              child: Column(
                children: [
                  Text(
                    'DRISHTI CLINICIAN • SIH 2026 • PS-26038',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDisabled,
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'AI-assisted screening • Final clinical validation by an ophthalmologist.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
