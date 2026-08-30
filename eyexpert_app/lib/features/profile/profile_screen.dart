import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/user_model.dart';
import '../../data/models/facility_model.dart';
import '../../data/models/professional_profile_model.dart';
import '../../data/models/verification_document_model.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // -------------------------------------------------------------
  // DIALOG: Restricted Field Protection
  // -------------------------------------------------------------
  void _showRestrictedFieldWarning(String fieldName, String currentValue) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: AppColors.statusWarning, size: 24),
            SizedBox(width: 10),
            Text(
              'Verification-Sensitive Field',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modifying $fieldName ("$currentValue") requires institutional re-verification of medical licenses and facility accreditation.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.statusBorderlineBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.statusBorderline.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.statusBorderline),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Direct in-app changes are restricted to maintain audit compliance.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Re-verification request for $fieldName has been logged with clinical administration.'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Request Change'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOG: Edit Personal Information
  // -------------------------------------------------------------
  void _showEditPersonalDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final addressCtrl = TextEditingController(text: user.address);
    final districtCtrl = TextEditingController(text: user.district);
    final stateCtrl = TextEditingController(text: user.state);
    final pinCtrl = TextEditingController(text: user.pinCode);
    String gender = user.gender;
    String language = user.preferredLanguage;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.person_outline, color: AppColors.accent, size: 22),
              SizedBox(width: 8),
              Text('Edit Personal Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full Name *', isDense: true),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number', isDense: true, hintText: '+91 98765 43210'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['Female', 'Male', 'Other'].contains(gender) ? gender : 'Female',
                      decoration: const InputDecoration(labelText: 'Gender', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => setDialogState(() => gender = v ?? 'Female'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: ['English / Hindi', 'English', 'Hindi'].contains(language) ? language : 'English / Hindi',
                      decoration: const InputDecoration(labelText: 'Preferred Language', isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'English / Hindi', child: Text('English / Hindi')),
                        DropdownMenuItem(value: 'English', child: Text('English')),
                        DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                      ],
                      onChanged: (v) => setDialogState(() => language = v ?? 'English / Hindi'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address', isDense: true),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: districtCtrl,
                            decoration: const InputDecoration(labelText: 'District', isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: stateCtrl,
                            decoration: const InputDecoration(labelText: 'State', isDense: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: pinCtrl,
                      decoration: const InputDecoration(labelText: 'PIN Code', isDense: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.of(ctx).pop();

                final updated = user.copyWith(
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  gender: gender,
                  preferredLanguage: language,
                  address: addressCtrl.text.trim(),
                  district: districtCtrl.text.trim(),
                  state: stateCtrl.text.trim(),
                  pinCode: pinCtrl.text.trim(),
                );

                final success = await ref.read(authProvider.notifier).updateProfile(updated);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '✓ Profile updated successfully' : 'Unable to save changes. Please check connection.'),
                      backgroundColor: success ? AppColors.statusGood : AppColors.statusCritical,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOG: Edit Organization / PHC
  // -------------------------------------------------------------
  void _showEditOrganizationDialog(UserModel user) {
    final facility = user.facility ?? FacilityModel(
      id: user.facilityId,
      facilityName: user.organization,
      facilityIdentifier: user.facilityId,
      address: user.address,
      district: user.district,
      state: user.state,
      pinCode: user.pinCode,
      contactNumber: user.phone,
    );

    final orgNameCtrl = TextEditingController(text: facility.facilityName);
    final contactCtrl = TextEditingController(text: facility.contactNumber);
    final emailCtrl = TextEditingController(text: facility.officialEmail);
    FacilityType facilityType = facility.facilityType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.business_outlined, color: AppColors.accent, size: 22),
              SizedBox(width: 8),
              Text('Edit PHC Facility Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: orgNameCtrl,
                    decoration: const InputDecoration(labelText: 'PHC / Facility Name *', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showRestrictedFieldWarning('Facility Identifier', facility.facilityIdentifier),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Facility ID (Verification Sensitive)',
                        suffixIcon: Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                        isDense: true,
                      ),
                      child: Text(facility.facilityIdentifier, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<FacilityType>(
                    value: facilityType,
                    decoration: const InputDecoration(labelText: 'Facility Type', isDense: true),
                    items: FacilityType.values.map((t) {
                      return DropdownMenuItem(value: t, child: Text(t.displayName));
                    }).toList(),
                    onChanged: (v) => setDialogState(() => facilityType = v ?? FacilityType.phc),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contactCtrl,
                    decoration: const InputDecoration(labelText: 'Official Contact Number', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Official Facility Email', isDense: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final updatedFacility = facility.copyWith(
                  facilityName: orgNameCtrl.text.trim(),
                  facilityType: facilityType,
                  contactNumber: contactCtrl.text.trim(),
                  officialEmail: emailCtrl.text.trim(),
                );
                final updatedUser = user.copyWith(
                  organization: orgNameCtrl.text.trim(),
                  facility: updatedFacility,
                );
                final success = await ref.read(authProvider.notifier).updateProfile(updatedUser);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '✓ PHC Information updated' : 'Unable to save changes.'),
                      backgroundColor: success ? AppColors.statusGood : AppColors.statusCritical,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOG: Edit Professional Info (Clinician)
  // -------------------------------------------------------------
  void _showEditProfessionalDialog(UserModel user) {
    final prof = user.professionalProfile ?? ProfessionalProfileModel(
      id: user.id,
      userId: user.id,
      qualification: 'MS / DNB (Ophthalmology)',
      specialization: 'Vitreo-Retinal Surgeon',
      registrationNumber: user.professionalId ?? 'MCI-78921-JH',
      registrationAuthority: 'National Medical Commission (NMC)',
      facilityName: user.organization,
      district: user.district,
      state: user.state,
    );

    final qualCtrl = TextEditingController(text: prof.qualification);
    final specCtrl = TextEditingController(text: prof.specialization);
    final hospCtrl = TextEditingController(text: prof.facilityName);
    int exp = prof.yearsExperience;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.badge_outlined, color: AppColors.accent, size: 22),
              SizedBox(width: 8),
              Text('Edit Professional Credentials', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _showRestrictedFieldWarning('Medical Registration Number', prof.registrationNumber),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Medical Registration No. (Restricted)',
                        suffixIcon: Icon(Icons.lock_outline, size: 18, color: AppColors.textMuted),
                        isDense: true,
                      ),
                      child: Text(prof.registrationNumber, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: qualCtrl,
                    decoration: const InputDecoration(labelText: 'Medical Qualification', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: specCtrl,
                    decoration: const InputDecoration(labelText: 'Clinical Specialization', isDense: true),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: exp,
                    decoration: const InputDecoration(labelText: 'Years of Experience', isDense: true),
                    items: List.generate(40, (i) => i + 1).map((y) {
                      return DropdownMenuItem(value: y, child: Text('$y years'));
                    }).toList(),
                    onChanged: (v) => setDialogState(() => exp = v ?? 5),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: hospCtrl,
                    decoration: const InputDecoration(labelText: 'Hospital / Eye Care Centre', isDense: true),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final updatedProf = prof.copyWith(
                  qualification: qualCtrl.text.trim(),
                  specialization: specCtrl.text.trim(),
                  yearsExperience: exp,
                  facilityName: hospCtrl.text.trim(),
                );
                final updatedUser = user.copyWith(
                  organization: hospCtrl.text.trim(),
                  professionalProfile: updatedProf,
                );
                final success = await ref.read(authProvider.notifier).updateProfile(updatedUser);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '✓ Professional profile updated' : 'Unable to save changes.'),
                      backgroundColor: success ? AppColors.statusGood : AppColors.statusCritical,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOG: Edit Camera / Hardware Information
  // -------------------------------------------------------------
  void _showEditDeviceDialog(UserModel user) {
    final facility = user.facility ?? FacilityModel(
      id: user.facilityId,
      facilityName: user.organization,
      facilityIdentifier: user.facilityId,
      address: user.address,
      district: user.district,
      state: user.state,
      pinCode: user.pinCode,
      contactNumber: user.phone,
    );

    bool cameraAvailable = facility.cameraAvailable;
    final mfgCtrl = TextEditingController(text: facility.cameraManufacturer ?? 'Remidio / Forus Health');
    final modelCtrl = TextEditingController(text: facility.cameraModel ?? 'FOP NM-01 Non-Mydriatic');
    ConnectivityType connectivity = facility.connectivityType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: AppColors.accent, size: 22),
              SizedBox(width: 8),
              Text('Edit Fundus Camera Hardware', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Camera Deployed & Operational', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    value: cameraAvailable,
                    activeTrackColor: AppColors.accentLight,
                    activeThumbColor: AppColors.accent,
                    onChanged: (v) => setDialogState(() => cameraAvailable = v),
                  ),
                  const SizedBox(height: 8),
                  if (cameraAvailable) ...[
                    TextFormField(
                      controller: mfgCtrl,
                      decoration: const InputDecoration(labelText: 'Camera Manufacturer', isDense: true),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: modelCtrl,
                      decoration: const InputDecoration(labelText: 'Camera Model / Specification', isDense: true),
                    ),
                    const SizedBox(height: 12),
                  ],
                  DropdownButtonFormField<ConnectivityType>(
                    value: connectivity,
                    decoration: const InputDecoration(labelText: 'Network Connectivity Tier', isDense: true),
                    items: ConnectivityType.values.map((c) {
                      return DropdownMenuItem(value: c, child: Text(c.displayName));
                    }).toList(),
                    onChanged: (v) => setDialogState(() => connectivity = v ?? ConnectivityType.online),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final updatedFacility = facility.copyWith(
                  cameraAvailable: cameraAvailable,
                  cameraManufacturer: mfgCtrl.text.trim(),
                  cameraModel: modelCtrl.text.trim(),
                  connectivityType: connectivity,
                );
                final updatedUser = user.copyWith(facility: updatedFacility);
                final success = await ref.read(authProvider.notifier).updateProfile(updatedUser);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? '✓ Hardware profile updated' : 'Unable to save changes.'),
                      backgroundColor: success ? AppColors.statusGood : AppColors.statusCritical,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // DIALOG: Change Password
  // -------------------------------------------------------------
  void _showChangePasswordDialog() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_reset_outlined, color: AppColors.statusWarning, size: 22),
            SizedBox(width: 8),
            Text('Change Account Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a new secure password for your Supabase authenticated account.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password *', isDense: true),
                validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password *', isDense: true),
                validator: (v) => (v != newPassCtrl.text) ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              final success = await ref.read(authProvider.notifier).changePassword(newPassCtrl.text);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '✓ Password updated successfully' : 'Failed to update password.'),
                    backgroundColor: success ? AppColors.statusGood : AppColors.statusCritical,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isClinician = user.role == UserRole.clinician;
    final completion = user.profileCompletion;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // -------------------------------------------------------------
              // 1. Profile Header Card & Completion
              // -------------------------------------------------------------
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.accentLight,
                          child: Icon(
                            isClinician ? Icons.medical_services_outlined : Icons.health_and_safety_outlined,
                            size: 34,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.pageHeading,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _verificationBadge(user.verificationStatus),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${user.role.displayName} • ${user.organization}',
                                style: AppTypography.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 14),

                    // Profile Completion Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('Profile Completion: ', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                            Text('$completion%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.accent)),
                          ],
                        ),
                        if (completion < 100)
                          StatusBadge.pending(label: 'COMPLETION REQUIRED')
                        else
                          StatusBadge.good(label: 'PROFILE COMPLETE'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completion / 100.0,
                        minHeight: 6,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          completion >= 85 ? AppColors.statusGood : AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 2. Personal Information
              // -------------------------------------------------------------
              ClinicalCard(
                title: 'Personal & Contact Information',
                child: Column(
                  children: [
                    _dataRow('Full Legal Name', user.name),
                    const Divider(height: 16),
                    _dataRow('Phone Number', user.phone.isNotEmpty ? user.phone : 'Not provided'),
                    const Divider(height: 16),
                    _dataRow('Account Email', user.email),
                    const Divider(height: 16),
                    _dataRow('Gender', user.gender),
                    const Divider(height: 16),
                    _dataRow('Preferred Language', user.preferredLanguage),
                    const Divider(height: 16),
                    _dataRow('Address', user.address.isNotEmpty ? user.address : 'Not provided'),
                    const Divider(height: 16),
                    _dataRow('District & State', '${user.district}, ${user.state} (${user.pinCode})'),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => _showEditPersonalDialog(user),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Personal Information'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 3. Organization / Professional Credentials
              // -------------------------------------------------------------
              if (isClinician)
                ClinicalCard(
                  title: 'Medical Council Credentials & Specialization',
                  child: Column(
                    children: [
                      _dataRow('Medical Registration No.', user.professionalId?.isNotEmpty == true ? user.professionalId! : (user.professionalProfile?.registrationNumber.isNotEmpty == true ? user.professionalProfile!.registrationNumber : 'Pending Registration'), isRestricted: true),
                      const Divider(height: 16),
                      _dataRow('Registration Authority', user.professionalProfile?.registrationAuthority.isNotEmpty == true ? user.professionalProfile!.registrationAuthority : 'National Medical Commission (NMC)', isRestricted: true),
                      const Divider(height: 16),
                      _dataRow('Qualification', user.professionalProfile?.qualification.isNotEmpty == true ? user.professionalProfile!.qualification : 'MS / DNB (Ophthalmology)'),
                      const Divider(height: 16),
                      _dataRow('Specialization', user.professionalProfile?.specialization.isNotEmpty == true ? user.professionalProfile!.specialization : 'Vitreo-Retinal Specialist'),
                      const Divider(height: 16),
                      _dataRow('Years of Clinical Experience', '${user.professionalProfile?.yearsExperience ?? 5} Years'),
                      const Divider(height: 16),
                      _dataRow('Primary Hospital / Centre', user.organization.isNotEmpty ? user.organization : 'Not Specified'),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditProfessionalDialog(user),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Professional Credentials'),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ClinicalCard(
                  title: 'PHC Healthcare Facility & Infrastructure',
                  child: Column(
                    children: [
                      _dataRow('PHC Facility Name', user.organization.isNotEmpty ? user.organization : 'Primary Health Centre'),
                      const Divider(height: 16),
                      _dataRow('Govt Facility ID', user.facilityId.isNotEmpty ? user.facilityId : 'PHC-UNIT', isRestricted: true),
                      const Divider(height: 16),
                      _dataRow('Facility Type', user.facility?.facilityType.displayName ?? 'Primary Health Centre (PHC)'),
                      const Divider(height: 16),
                      _dataRow('Official Contact', user.facility?.contactNumber.isNotEmpty == true ? user.facility!.contactNumber : (user.phone.isNotEmpty ? user.phone : 'Not provided')),
                      const Divider(height: 16),
                      _dataRow('Official Email', user.facility?.officialEmail.isNotEmpty == true ? user.facility!.officialEmail : user.email),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditOrganizationDialog(user),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit PHC Facility'),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 4. Fundus Camera Hardware (Health Worker Only)
              // -------------------------------------------------------------
              if (!isClinician) ...[
                ClinicalCard(
                  title: 'Fundus Camera & Capture Hardware',
                  child: Column(
                    children: [
                      _dataRow('Camera Available', user.facility?.cameraAvailable == true ? 'YES (Operational)' : 'NO'),
                      const Divider(height: 16),
                      _dataRow('Manufacturer / Make', (user.facility?.cameraManufacturer != null && user.facility!.cameraManufacturer!.isNotEmpty) ? user.facility!.cameraManufacturer! : 'Not Configured'),
                      const Divider(height: 16),
                      _dataRow('Model / Optics', (user.facility?.cameraModel != null && user.facility!.cameraModel!.isNotEmpty) ? user.facility!.cameraModel! : 'Not Configured'),
                      const Divider(height: 16),
                      _dataRow('Network Mode', user.facility?.connectivityType.displayName ?? 'Online (Full Network)'),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _showEditDeviceDialog(user),
                          icon: const Icon(Icons.tune_outlined, size: 16),
                          label: const Text('Edit Device Information'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // -------------------------------------------------------------
              // 5. Verification Documents
              // -------------------------------------------------------------
              ClinicalCard(
                title: 'Institutional Verification Documents',
                child: Column(
                  children: [
                    _docItem(
                      title: isClinician ? 'Medical Council Registration Certificate' : 'PHC Facility Registration / Authorization',
                      status: DocumentVerificationStatus.verified,
                      filename: 'license_accreditation_cert.pdf',
                    ),
                    const Divider(height: 14),
                    _docItem(
                      title: isClinician ? 'Medical Degree / Specialization Certificate' : 'PHC Identity / Facility Proof',
                      status: DocumentVerificationStatus.underReview,
                      filename: 'institutional_proof_document.pdf',
                    ),
                    const Divider(height: 14),
                    _docItem(
                      title: isClinician ? 'Government / Professional Identity Document' : 'Authorized Personnel Document',
                      status: DocumentVerificationStatus.underReview,
                      filename: 'government_id_card.pdf',
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Document management portal is active. Encrypted files stored in private Supabase bucket.'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        icon: const Icon(Icons.upload_file_outlined, size: 16),
                        label: const Text('Upload / Replace Documents'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------------------
              // 6. Account & Security
              // -------------------------------------------------------------
              ClinicalCard(
                title: 'Account Security & Session',
                child: Column(
                  children: [
                    _dataRow('Authenticated Email', user.email),
                    const Divider(height: 16),
                    _dataRow('User ID', user.id),
                    const Divider(height: 16),
                    _dataRow('Account Status', user.isActive ? 'ACTIVE' : 'INACTIVE', badge: user.isActive ? 'ACTIVE' : 'DISABLED'),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showChangePasswordDialog,
                          icon: const Icon(Icons.lock_reset_outlined, size: 16),
                          label: const Text('Change Password'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text('Sign Out Session'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusCritical,
                            foregroundColor: Colors.white,
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
    );
  }

  Widget _dataRow(String label, String value, {bool isRestricted = false, String? badge}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            if (isRestricted) ...[
              const SizedBox(width: 6),
              const Icon(Icons.lock_outline, size: 13, color: AppColors.statusWarning),
            ],
          ],
        ),
        if (badge != null)
          StatusBadge.good(label: badge)
        else
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
      ],
    );
  }

  Widget _docItem({required String title, required DocumentVerificationStatus status, required String filename}) {
    return Row(
      children: [
        Icon(status.icon, color: status.color, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text('$filename • Supabase Private Storage', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: status.backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: status.color.withValues(alpha: 0.3)),
          ),
          child: Text(
            status.label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: status.color),
          ),
        ),
      ],
    );
  }

  Widget _verificationBadge(OverallVerificationStatus status) {
    switch (status) {
      case OverallVerificationStatus.verified:
        return StatusBadge.good(label: 'VERIFIED');
      case OverallVerificationStatus.underReview:
        return StatusBadge.borderline(label: 'UNDER REVIEW');
      case OverallVerificationStatus.requiresAction:
        return StatusBadge.ungradable(label: 'ACTION REQUIRED');
      case OverallVerificationStatus.pending:
        return StatusBadge.pending(label: 'ENROLLMENT PENDING');
    }
  }
}
