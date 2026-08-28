import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../shared/widgets/clinical_card.dart';
import '../../shared/widgets/status_badge.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/medical_disclaimer_banner.dart';
import '../auth/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final workflowMode = authState.workflowMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Profile Card
              ClinicalCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(Icons.person_rounded, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Sunita Sharma',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.role.displayName ?? 'Health Worker',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          Text(
                            user?.organization ?? 'PHC Ramgarh Tele-Screening Unit',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Facility & Tele-Screening Node Info
              ClinicalCard(
                title: 'Assigned Healthcare Facility',
                child: Column(
                  children: [
                    _facilityRow('Primary Center', 'PHC-RAMGARH-01 (Sector 4)'),
                    const Divider(height: 16),
                    _facilityRow('Referral Center', 'District Eye Hospital (Apex Retinal Unit)'),
                    const Divider(height: 16),
                    _facilityRow('Cloud Telemetry', 'Supabase Real-Time Sync Active'),
                    const Divider(height: 16),
                    _facilityRow('AI Backend', 'PyTorch 2.2+ ResNet-18 Cloud Engine'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Role Switching Card
              ClinicalCard(
                title: 'Switch Active Persona',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toggle between Field Health Worker and Ophthalmologist accounts:',
                      style: TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ref.read(authProvider.notifier).switchRole(UserRole.healthWorker),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: user?.role == UserRole.healthWorker ? AppColors.primary : Colors.grey.shade300,
                                width: user?.role == UserRole.healthWorker ? 2 : 1,
                              ),
                            ),
                            child: const Text('Health Worker'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => ref.read(authProvider.notifier).switchRole(UserRole.clinician),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: user?.role == UserRole.clinician ? AppColors.primary : Colors.grey.shade300,
                                width: user?.role == UserRole.clinician ? 2 : 1,
                              ),
                            ),
                            child: const Text('Ophthalmologist'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sign Out Button
              PrimaryButton(
                text: 'Sign Out Session',
                icon: Icons.logout_rounded,
                isDestructive: true,
                onPressed: () => ref.read(authProvider.notifier).logout(),
              ),
              const SizedBox(height: 16),

              const MedicalDisclaimerBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _facilityRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87)),
      ],
    );
  }
}
