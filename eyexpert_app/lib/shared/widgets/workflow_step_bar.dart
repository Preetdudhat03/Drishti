import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class WorkflowStepBar extends StatelessWidget {
  final int currentStep;
  final List<String> steps;
  final ValueChanged<int>? onStepTapped;

  const WorkflowStepBar({
    super.key,
    required this.currentStep,
    required this.steps,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: (onStepTapped != null && i <= currentStep)
                    ? () => onStepTapped!(i)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: i < currentStep
                            ? AppColors.accent
                            : i == currentStep
                                ? AppColors.accent
                                : AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i <= currentStep
                              ? AppColors.accent
                              : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: i < currentStep
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: i == currentStep
                                    ? Colors.white
                                    : AppColors.textMuted,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        steps[i],
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: i == currentStep
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: i == currentStep
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 16,
                  height: 2,
                  color: i < currentStep ? AppColors.accent : AppColors.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}