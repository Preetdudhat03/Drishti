import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../shared/widgets/drishti_logo.dart';
import 'auth_provider.dart';
import 'widgets/retinal_visual_panel.dart';
import 'widgets/role_selection_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registrationIdController = TextEditingController();

  UserRole _selectedRole = UserRole.healthWorker;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _registrationIdController.dispose();
    super.dispose();
  }

  void _onRoleChanged(UserRole role) {
    if (_selectedRole == role) return;
    setState(() {
      _selectedRole = role;
      _usernameController.clear();
      _passwordController.clear();
      _registrationIdController.clear();
    });
    ref.read(authProvider.notifier).clearError();
  }

  void _handleLogin() {
    ref.read(authProvider.notifier).clearError();
    ref.read(authProvider.notifier).login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      roleRequested: _selectedRole,
      medicalRegistrationId: _selectedRole == UserRole.clinician
          ? _registrationIdController.text.trim()
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isPHC = _selectedRole == UserRole.healthWorker;

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
                        // Left Panel: Clinical Authentication Form
                        Expanded(
                          flex: 5,
                          child: _buildLoginFormPanel(context, authState, isPHC),
                        ),
                        const SizedBox(width: 32),

                        // Right Panel: AI Retinal Imaging Workstation Visual
                        Expanded(
                          flex: 5,
                          child: SizedBox(
                            height: 720,
                            child: RetinalVisualPanel(activeRole: _selectedRole),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Mobile / Narrow Viewport: Single Column Layout
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: _buildLoginFormPanel(context, authState, isPHC),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginFormPanel(
    BuildContext context,
    AuthState authState,
    bool isPHC,
  ) {
    final activeAccent = isPHC ? AppColors.electricBlue : AppColors.aiViolet;

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
            // Header: Drishti Brand + Subtitle + SIH Badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                const DrishtiLogo(
                  size: 34,
                  showText: true,
                  textColor: AppColors.textBright,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.obsidianElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.obsidianBorder,
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_outlined,
                        size: 12,
                        color: AppColors.hudCyan,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'SIH 2026 • PS-26038',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.hudCyan,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Clinical Intelligence & Tele-Ophthalmology Portal',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSubtle,
              ),
            ),
            const SizedBox(height: 20),

            // Step 1: Role Selection Section
            const Text(
              'SELECT CLINICAL ROLE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSubtle,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            RoleSelectionCard(
              role: UserRole.healthWorker,
              isSelected: _selectedRole == UserRole.healthWorker,
              onTap: () => _onRoleChanged(UserRole.healthWorker),
            ),
            const SizedBox(height: 10),
            RoleSelectionCard(
              role: UserRole.clinician,
              isSelected: _selectedRole == UserRole.clinician,
              onTap: () => _onRoleChanged(UserRole.clinician),
            ),
            const SizedBox(height: 20),

            // Step 2: Role Context Summary Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: activeAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: activeAccent.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isPHC ? Icons.local_hospital_outlined : Icons.shield_outlined,
                    size: 16,
                    color: activeAccent,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPHC
                              ? 'PHC FIELD SCREENING ENVIRONMENT'
                              : 'SPECIALIST CLINICAL REVIEW WORKSPACE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: activeAccent,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPHC
                              ? 'Facility: Primary Health Centre | Access: Patient Intake & Fundus AI'
                              : 'Clearance: Tele-Ophthalmologist Review & Final Diagnostic Override',
                          style: const TextStyle(
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
            const SizedBox(height: 18),

            // Step 3: Login Input Fields
            // Email / Clinician ID Field
            Text(
              isPHC
                  ? 'REGISTERED EMAIL / HEALTH WORKER ID'
                  : 'PROFESSIONAL EMAIL / CLINICIAN ID',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSubtle,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: AppColors.textBright, fontSize: 14),
              decoration: InputDecoration(
                hintText: isPHC
                    ? 'healthworker@phc.gov.in'
                    : 'clinician@retina-telemed.org',
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
                  borderSide: BorderSide(color: activeAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Password Field
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
                hintText: 'Enter clinical access password',
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
                  borderSide: BorderSide(color: activeAccent, width: 1.5),
                ),
              ),
            ),

            // Optional Medical Registration ID for Clinician
            if (!isPHC) ...[
              const SizedBox(height: 14),
              const Text(
                'MEDICAL REGISTRATION ID (OPTIONAL)',
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
                  hintText: 'e.g. MCI-2018-84729 / State Medical Council',
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
                    borderSide: BorderSide(color: activeAccent, width: 1.5),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

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
              const SizedBox(height: 16),
            ],

            // Step 4: Primary Sign In Button
            ElevatedButton(
              onPressed: authState.isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeAccent,
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPHC ? Icons.login_outlined : Icons.lock_open_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            isPHC
                                ? 'Sign In to PHC Screening Workstation'
                                : 'Sign In to Specialist Review Portal',
                            style: const TextStyle(
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

            // Step 5: Clinical Safety & AI Governance Footer
            Center(
              child: Column(
                children: [
                  const Text(
                    'DRISHTI • SIH 2026 • PS-26038',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDisabled,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'AI-assisted screening • Final clinical validation by an ophthalmologist.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textDisabled.withValues(alpha: 0.8),
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

