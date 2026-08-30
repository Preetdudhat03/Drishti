import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/user_model.dart';
import '../../data/models/facility_model.dart';
import '../../shared/widgets/drishti_logo.dart';
import '../../shared/widgets/status_badge.dart';
import '../auth/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onCancelToLogin;

  const OnboardingScreen({
    super.key,
    required this.onCancelToLogin,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0; // 0 to 4

  // Form Keys
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // Step 1: Account
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  UserRole _selectedRole = UserRole.healthWorker;
  bool _obscurePassword = true;

  // Step 2: Personal Info
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gender = 'Female';
  String _preferredLanguage = 'English / Hindi';
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  // Step 3: PHC Specific
  final _phcNameController = TextEditingController();
  final _phcIdController = TextEditingController();
  FacilityType _facilityType = FacilityType.phc;
  final _villageTownController = TextEditingController();
  final _officialContactController = TextEditingController();
  final _officialEmailController = TextEditingController();
  bool _cameraAvailable = true;
  final _cameraManufacturerController = TextEditingController();
  final _cameraModelController = TextEditingController();
  ConnectivityType _connectivityType = ConnectivityType.online;

  // Step 3: Clinician Specific
  final _medicalRegNoController = TextEditingController();
  final _regAuthorityController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _specializationController = TextEditingController();
  int _yearsExperience = 5;
  final _hospitalNameController = TextEditingController();
  final _clinicianFacilityIdController = TextEditingController();

  // Step 4: Documents Attached
  final Map<String, String> _selectedDocumentNames = {};

  // Step 5: Declaration
  bool _hasAcceptedDeclaration = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _phcNameController.dispose();
    _phcIdController.dispose();
    _villageTownController.dispose();
    _officialContactController.dispose();
    _officialEmailController.dispose();
    _cameraManufacturerController.dispose();
    _cameraModelController.dispose();
    _medicalRegNoController.dispose();
    _regAuthorityController.dispose();
    _qualificationController.dispose();
    _specializationController.dispose();
    _hospitalNameController.dispose();
    _clinicianFacilityIdController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1FormKey.currentState!.validate()) return;
    } else if (_currentStep == 1) {
      if (!_step2FormKey.currentState!.validate()) return;
    } else if (_currentStep == 2) {
      if (!_step3FormKey.currentState!.validate()) return;
    }

    if (_currentStep < 4) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      widget.onCancelToLogin();
    }
  }

  Future<void> _submitEnrollment() async {
    if (!_hasAcceptedDeclaration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please acknowledge the institutional verification declaration.'),
          backgroundColor: AppColors.statusCritical,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).registerAndOnboard(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      role: _selectedRole,
      district: _districtController.text.trim(),
      stateName: _stateController.text.trim(),
      address: _addressController.text.trim(),
      pinCode: _pinCodeController.text.trim(),
      gender: _gender,
      preferredLanguage: _preferredLanguage,
      organizationName: _selectedRole == UserRole.healthWorker
          ? _phcNameController.text.trim()
          : _hospitalNameController.text.trim(),
      facilityId: _selectedRole == UserRole.healthWorker
          ? _phcIdController.text.trim()
          : _clinicianFacilityIdController.text.trim(),
      facilityType: _facilityType.displayName,
      cameraManufacturer: _cameraManufacturerController.text.trim(),
      cameraModel: _cameraModelController.text.trim(),
      cameraAvailable: _cameraAvailable,
      connectivity: _connectivityType.name.toUpperCase(),
      medicalRegistrationNo: _medicalRegNoController.text.trim(),
      registrationAuthority: _regAuthorityController.text.trim(),
      qualification: _qualificationController.text.trim(),
      specialization: _specializationController.text.trim(),
      yearsExperience: _yearsExperience,
    );

    if (!success && mounted) {
      final error = ref.read(authProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Registration failed. Please check your connection.'),
          backgroundColor: AppColors.statusCritical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: _prevStep,
        ),
        title: Row(
          children: [
            const DrishtiLogo(size: 26, showText: false, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'Workstation Registration & Clinical Enrollment',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: widget.onCancelToLogin,
            child: const Text('Back to Login', style: TextStyle(color: Colors.white70)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Stepper Header
                  _buildStepperHeader(),
                  const SizedBox(height: 24),

                  // Step Content
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildCurrentStepView(),
                  ),
                  const SizedBox(height: 20),

                  // Navigation Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: authState.isLoading ? null : _prevStep,
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(_currentStep == 0 ? 'Cancel' : 'Previous Step'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                      if (_currentStep < 4)
                        ElevatedButton.icon(
                          onPressed: _nextStep,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text('Continue to Next Step'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: authState.isLoading ? null : _submitEnrollment,
                          icon: authState.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text(authState.isLoading ? 'Enrolling...' : 'Complete Enrollment & Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final steps = [
      '01 ACCOUNT',
      '02 PROFILE',
      '03 ORGANIZATION',
      '04 DOCUMENTS',
      '05 REVIEW',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isActive = index == _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : (isCompleted ? AppColors.accentLight : Colors.transparent),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCompleted)
                          const Icon(Icons.check_circle, size: 14, color: AppColors.accent)
                        else
                          Container(
                            width: 16,
                            height: 16,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? Colors.white : AppColors.border,
                            ),
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: isActive ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            steps[index],
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : (isCompleted ? AppColors.accent : AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (index < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade400),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Account();
      case 1:
        return _buildStep2Personal();
      case 2:
        return _buildStep3Organization();
      case 3:
        return _buildStep4Documents();
      case 4:
      default:
        return _buildStep5Review();
    }
  }

  // -------------------------------------------------------------
  // STEP 01 — ACCOUNT CREATION
  // -------------------------------------------------------------
  Widget _buildStep1Account() {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 01 — Account Credentials & Role Selection', style: AppTypography.sectionHeading),
          const SizedBox(height: 4),
          const Text(
            'Credentials are fully encrypted and securely authenticated with Supabase Auth.',
            style: AppTypography.bodySecondary,
          ),
          const Divider(height: 28),

          // Role Selector Card
          const Text('SELECT CLINICAL ROLE *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _roleOptionCard(
                  role: UserRole.healthWorker,
                  title: 'PHC Health Worker',
                  subtitle: 'Primary health centres, field screening, fundus image capture',
                  icon: Icons.local_hospital_outlined,
                  isSelected: _selectedRole == UserRole.healthWorker,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _roleOptionCard(
                  role: UserRole.clinician,
                  title: 'Ophthalmologist',
                  subtitle: 'Eye specialist, AI validation, clinical grading & review',
                  icon: Icons.remove_red_eye_outlined,
                  isSelected: _selectedRole == UserRole.clinician,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Email
          const Text('OFFICIAL / WORK EMAIL *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'e.g. officer.ramgarh@drishti.org',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter an official email address';
              if (!val.contains('@') || !val.contains('.')) return 'Please enter a valid email format';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password
          const Text('PASSWORD *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'Minimum 8 characters with letters & numbers',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (val) {
              if (val == null || val.length < 6) return 'Password must be at least 6 characters long';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password
          const Text('CONFIRM PASSWORD *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscurePassword,
            decoration: const InputDecoration(
              hintText: 'Re-enter your password',
              prefixIcon: Icon(Icons.lock_reset_outlined, size: 20),
            ),
            validator: (val) {
              if (val != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _roleOptionCard({
    required UserRole role,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentLight : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? AppColors.accent : AppColors.textSecondary, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 02 — PERSONAL INFORMATION
  // -------------------------------------------------------------
  Widget _buildStep2Personal() {
    return Form(
      key: _step2FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 02 — Personal & Contact Information', style: AppTypography.sectionHeading),
          const SizedBox(height: 4),
          const Text(
            'Institutional profile identity for reporting and clinical sign-offs.',
            style: AppTypography.bodySecondary,
          ),
          const Divider(height: 28),

          // Full Name
          const Text('FULL LEGAL NAME *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _fullNameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Dr. Priya Sharma / Anita Kumari',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter your full name' : null,
          ),
          const SizedBox(height: 16),

          // Phone & Gender
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PHONE NUMBER *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '+91 98765 43210',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter contact phone' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('GENDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (val) => setState(() => _gender = val ?? 'Female'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preferred Language
          const Text('PREFERRED INTERFACE LANGUAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _preferredLanguage,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.translate, size: 20)),
            items: const [
              DropdownMenuItem(value: 'English / Hindi', child: Text('English / Hindi (दृष्टि Bilingual)')),
              DropdownMenuItem(value: 'English', child: Text('English (Medical Standard)')),
              DropdownMenuItem(value: 'Hindi', child: Text('Hindi (हिन्दी)')),
            ],
            onChanged: (val) => setState(() => _preferredLanguage = val ?? 'English / Hindi'),
          ),
          const SizedBox(height: 16),

          // Address
          const Text('POSTAL / CLINIC ADDRESS *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              hintText: 'Sector 4, Main Health Campus Road',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
            ),
            validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter address' : null,
          ),
          const SizedBox(height: 16),

          // District, State, PIN
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DISTRICT *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(hintText: 'Ramgarh'),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STATE *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(hintText: 'Jharkhand'),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PIN CODE *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _pinCodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: '829122'),
                      validator: (val) => (val == null || val.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 03 — ORGANIZATION / PROFESSIONAL INFORMATION
  // -------------------------------------------------------------
  Widget _buildStep3Organization() {
    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedRole == UserRole.healthWorker
                ? 'Step 03 — PHC Facility & Fundus Camera Information'
                : 'Step 03 — Medical Council Credentials & Eye Hospital',
            style: AppTypography.sectionHeading,
          ),
          const SizedBox(height: 4),
          Text(
            _selectedRole == UserRole.healthWorker
                ? 'Details regarding your primary health centre and attached screening hardware.'
                : 'Professional registration number and clinical consultation location.',
            style: AppTypography.bodySecondary,
          ),
          const Divider(height: 28),

          if (_selectedRole == UserRole.healthWorker) ...[
            // PHC Information
            const Text('PHC / HEALTH CENTRE NAME *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phcNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. PHC Ramgarh Community Health Unit',
                prefixIcon: Icon(Icons.business_outlined, size: 20),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'PHC Name is required' : null,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('GOVT FACILITY ID *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _phcIdController,
                        decoration: const InputDecoration(hintText: 'PHC-RAMGARH-01'),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Facility ID is required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('FACILITY TYPE *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<FacilityType>(
                        value: _facilityType,
                        decoration: const InputDecoration(isDense: true),
                        items: FacilityType.values.map((t) {
                          return DropdownMenuItem(value: t, child: Text(t.displayName, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (val) => setState(() => _facilityType = val ?? FacilityType.phc),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fundus Camera Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accentLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.camera_alt_outlined, color: AppColors.accent, size: 20),
                          SizedBox(width: 8),
                          Text('FUNDUS CAMERA DEPLOYMENT', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                      Switch.adaptive(
                        value: _cameraAvailable,
                        activeTrackColor: AppColors.accentLight,
                        activeThumbColor: AppColors.accent,
                        onChanged: (v) => setState(() => _cameraAvailable = v),
                      ),
                    ],
                  ),
                  if (_cameraAvailable) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cameraManufacturerController,
                            decoration: const InputDecoration(labelText: 'Manufacturer / Vendor', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _cameraModelController,
                            decoration: const InputDecoration(labelText: 'Camera Model / Type', isDense: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // Clinician Fields
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MEDICAL REGISTRATION NO. *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _medicalRegNoController,
                        decoration: const InputDecoration(hintText: 'e.g. MCI-78921-JH'),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Registration number is required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REGISTRATION AUTHORITY *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _regAuthorityController,
                        decoration: const InputDecoration(hintText: 'NMC / State Medical Council'),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Authority is required' : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('QUALIFICATION *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _qualificationController,
                        decoration: const InputDecoration(hintText: 'e.g. MS / DNB / FRCS (Ophthalmology)'),
                        validator: (val) => (val == null || val.trim().isEmpty) ? 'Qualification is required' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('EXPERIENCE (YRS) *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _yearsExperience,
                        decoration: const InputDecoration(isDense: true),
                        items: List.generate(35, (i) => i + 1).map((y) {
                          return DropdownMenuItem(value: y, child: Text('$y yrs'));
                        }).toList(),
                        onChanged: (val) => setState(() => _yearsExperience = val ?? 5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('HOSPITAL / EYE CENTRE NAME *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _hospitalNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. District Eye Care Institute / Tertiary Apex Hospital',
                prefixIcon: Icon(Icons.local_hospital_outlined, size: 20),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Hospital name is required' : null,
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 04 — REQUIRED DOCUMENTS
  // -------------------------------------------------------------
  Widget _buildStep4Documents() {
    final docs = _selectedRole == UserRole.healthWorker
        ? [
            {'type': 'PHC_REGISTRATION', 'title': 'Facility Registration / Authorization', 'mandatory': true},
            {'type': 'FACILITY_PROOF', 'title': 'PHC Identity / Facility Proof', 'mandatory': true},
            {'type': 'PERSONNEL_AUTHORIZATION', 'title': 'Authorized Personnel Document', 'mandatory': true},
            {'type': 'SUPPORTING_DOC', 'title': 'Additional Supporting Document', 'mandatory': false},
          ]
        : [
            {'type': 'MEDICAL_REGISTRATION_CERT', 'title': 'Medical Council Registration Certificate', 'mandatory': true},
            {'type': 'DEGREE_QUALIFICATION', 'title': 'Medical Degree / Specialization Certificate', 'mandatory': true},
            {'type': 'PROFESSIONAL_ID_PROOF', 'title': 'Government / Professional Identity Document', 'mandatory': true},
            {'type': 'HOSPITAL_ASSOCIATION_PROOF', 'title': 'Hospital / Clinic Association Proof', 'mandatory': false},
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 04 — Verification Document Upload', style: AppTypography.sectionHeading),
        const SizedBox(height: 4),
        const Text(
          'Documents are securely transferred to private Supabase Storage buckets. Uploaded documents enter the "Under Review" state.',
          style: AppTypography.bodySecondary,
        ),
        const Divider(height: 28),

        ...docs.map((d) {
          final type = d['type'] as String;
          final title = d['title'] as String;
          final isMandatory = d['mandatory'] as bool;
          final fileName = _selectedDocumentNames[type];
          final hasFile = fileName != null;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasFile ? AppColors.statusGoodBg : AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: hasFile ? AppColors.statusGood.withValues(alpha: 0.4) : AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  hasFile ? Icons.check_circle_rounded : Icons.upload_file_outlined,
                  color: hasFile ? AppColors.statusGood : AppColors.accent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                          ),
                          if (isMandatory) ...[
                            const SizedBox(width: 4),
                            const Text('*', style: TextStyle(color: AppColors.statusCritical, fontWeight: FontWeight.bold)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasFile ? '$fileName • Ready for Supabase Storage' : 'PDF, JPEG, or PNG (Max 10 MB)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: hasFile ? AppColors.statusGood : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedDocumentNames[type] = '${type.toLowerCase()}_verified_doc.pdf';
                    });
                  },
                  icon: Icon(hasFile ? Icons.refresh : Icons.attach_file, size: 16),
                  label: Text(hasFile ? 'Replace' : 'Upload'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 05 — REVIEW & SUBMIT
  // -------------------------------------------------------------
  Widget _buildStep5Review() {
    final roleName = _selectedRole == UserRole.healthWorker ? 'PHC Health Worker' : 'Ophthalmologist';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Step 05 — Review & Institutional Verification', style: AppTypography.sectionHeading),
        const SizedBox(height: 4),
        const Text(
          'Please verify all credentials before submitting your enrollment.',
          style: AppTypography.bodySecondary,
        ),
        const Divider(height: 28),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _reviewRow('Role & Access Level', roleName, isHighlight: true),
              const Divider(height: 16),
              _reviewRow('Work Email', _emailController.text),
              const Divider(height: 16),
              _reviewRow('Full Name', _fullNameController.text),
              const Divider(height: 16),
              _reviewRow('Contact Phone', _phoneController.text),
              const Divider(height: 16),
              _reviewRow('Location / District', '${_districtController.text}, ${_stateController.text} (${_pinCodeController.text})'),
              const Divider(height: 16),
              if (_selectedRole == UserRole.healthWorker) ...[
                _reviewRow('PHC Facility Name', _phcNameController.text),
                const Divider(height: 16),
                _reviewRow('Facility Identifier', _phcIdController.text),
                const Divider(height: 16),
                _reviewRow('Fundus Camera', _cameraAvailable ? '${_cameraManufacturerController.text} (${_cameraModelController.text})' : 'Not Deployed'),
              ] else ...[
                _reviewRow('Registration No.', _medicalRegNoController.text),
                const Divider(height: 16),
                _reviewRow('Authority', _regAuthorityController.text),
                const Divider(height: 16),
                _reviewRow('Specialization', '${_specializationController.text} ($_yearsExperience yrs exp)'),
                const Divider(height: 16),
                _reviewRow('Hospital / Clinic', _hospitalNameController.text),
              ],
              const Divider(height: 16),
              _reviewRow(
                'Documents Attached',
                '${_selectedDocumentNames.length} verification files prepared',
                badge: 'UNDER REVIEW',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Statutory Declaration
        CheckboxListTile(
          value: _hasAcceptedDeclaration,
          activeColor: AppColors.accent,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'I certify under medical ethics and regulatory standards that all clinical identity, institutional facilities, and registration credentials provided are authentic and up to date.',
            style: TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textPrimary),
          ),
          onChanged: (val) => setState(() => _hasAcceptedDeclaration = val ?? false),
        ),
      ],
    );
  }

  Widget _reviewRow(String label, String value, {bool isHighlight = false, String? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        if (badge != null)
          StatusBadge.borderline(label: badge)
        else
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
                color: isHighlight ? AppColors.accent : AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
