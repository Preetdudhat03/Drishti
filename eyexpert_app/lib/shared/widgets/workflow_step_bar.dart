import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class WorkflowStepBar extends StatelessWidget {
  final int currentStep; // 1 to 5

  const WorkflowStepBar({
    super.key,
    required this.currentStep,
  });

  static const List<String> steps = [
    'PATIENT',
    'CAPTURE',
    'QUALITY',
    'ANALYSIS',
    'REVIEW',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.deepSpace,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = (index ~/ 2) + 1;
            final isPassed = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isPassed ? AppColors.electricBlue : AppColors.borderDark,
              ),
            );
          }

          final stepNum = (index ~/ 2) + 1;
          final stepLabel = steps[stepNum - 1];
          final isActive = stepNum == currentStep;
          final isCompleted = stepNum < currentStep;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.electricBlue
                      : isActive
                          ? AppColors.electricBlue.withValues(alpha: 0.20)
                          : AppColors.graphite,
                  border: Border.all(
                    color: isActive
                        ? AppColors.electricBlue
                        : isCompleted
                            ? AppColors.electricBlue
                            : AppColors.borderDark,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : Text(
                          '0$stepNum',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isActive ? AppColors.electricBlue : AppColors.darkTextMuted,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                stepLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : isCompleted
                          ? AppColors.darkTextSecondary
                          : AppColors.darkTextMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
