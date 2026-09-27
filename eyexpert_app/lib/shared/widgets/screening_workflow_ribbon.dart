import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/localization/locale_provider.dart';

class ScreeningWorkflowRibbon extends ConsumerWidget {
  /// activeStep: 1 for Intake, 2 for Capture & Quality, 3 for AI Results & Referral Slip
  final int activeStep;
  final ValueChanged<int>? onStepTapped;

  const ScreeningWorkflowRibbon({
    super.key,
    required this.activeStep,
    this.onStepTapped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final isMobile = ResponsiveLayout.isMobile(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Sleek Dark Slate Cockpit Ribbon
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _buildStepItem(
              stepNum: 1,
              label: tr('step1_ribbon'),
              shortLabel: tr('step1_short'),
              isActive: activeStep == 1,
              isCompleted: activeStep > 1,
              isMobile: isMobile,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: activeStep > 1 ? const Color(0xFF38BDF8) : const Color(0xFF475569),
            ),
          ),
          Expanded(
            child: _buildStepItem(
              stepNum: 2,
              label: tr('step2_ribbon'),
              shortLabel: tr('step2_short'),
              isActive: activeStep == 2,
              isCompleted: activeStep > 2,
              isMobile: isMobile,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 11,
              color: activeStep > 2 ? const Color(0xFF10B981) : const Color(0xFF475569),
            ),
          ),
          Expanded(
            child: _buildStepItem(
              stepNum: 3,
              label: tr('step3_ribbon'),
              shortLabel: tr('step3_short'),
              isActive: activeStep == 3,
              isCompleted: false,
              isMobile: isMobile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int stepNum,
    required String label,
    required String shortLabel,
    required bool isActive,
    required bool isCompleted,
    required bool isMobile,
  }) {
    Color badgeColor;
    Color textColor;

    if (isCompleted) {
      badgeColor = const Color(0xFF10B981); // Emerald check
      textColor = const Color(0xFF94A3B8);
    } else if (isActive) {
      badgeColor = const Color(0xFF0284C7); // Vivid Sky Blue
      textColor = const Color(0xFF38BDF8);
    } else {
      badgeColor = const Color(0xFF334155);
      textColor = const Color(0xFF64748B);
    }

    final displayText = isMobile ? shortLabel : label;

    return InkWell(
      onTap: (onStepTapped != null && isCompleted) ? () => onStepTapped!(stepNum) : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? const Color(0xFF38BDF8) : Colors.transparent,
                  width: isActive ? 1.8 : 0,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 13)
                    : Text(
                        '$stepNum',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12.5,
                  fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                  color: textColor,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
