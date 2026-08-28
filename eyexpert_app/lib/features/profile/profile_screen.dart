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
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: const Icon(Icons.person_rounded, size: 36, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user?.name ?? 'Health Worker',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              if (user?.isDemoAccount ?? true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: const Text(
                                    'DEMO ACCOUNT',
                                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.amber),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.role.displayName ?? 'Health Worker',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                          Text(
                            user?.organization ?? 'Demo Primary Health Centre',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Workflow Mode Selection Card
              ClinicalCard(
                title: 'Operational Workflow Mode',
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'DEMO',
                      groupValue: workflowMode,
                      title: const Text('DEMO MODE — SIMULATED WORKFLOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: const Text('Interactive clinical walkthrough with curated demonstration scenarios.', style: TextStyle(fontSize: 11)),
                      onChanged: (val) {
                        if (val != null) ref.read(authProvider.notifier).setWorkflowMode(val);
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      value: 'VALIDATION',
                      groupValue: workflowMode,
                      title: const Text('VALIDATION MODE — REAL APTOS TEST DATA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: const Text('Exploration of real held-out APTOS 2019 test cases & verified Grad-CAM heatmaps.', style: TextStyle(fontSize: 11)),
                      onChanged: (val) {
                        if (val != null) ref.read(authProvider.notifier).setWorkflowMode(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Role Switching Card (Demonstration Convenience)
              ClinicalCard(
                title: 'Role Switcher (Demonstration Control)',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Switch between Field Health Worker and Clinician personas to experience the full end-to-end human-in-the-loop screening workflow:',
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
                            child: const Text('Switch to Health Worker'),
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
                            child: const Text('Switch to Clinician'),
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
}
