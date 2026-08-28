import 'package:flutter/material.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class ProbabilityDistributionWidget extends StatelessWidget {
  final Map<int, double> classProbabilities;
  final int predictedLevel;
  final bool isDark;

  const ProbabilityDistributionWidget({
    super.key,
    required this.classProbabilities,
    required this.predictedLevel,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i <= 4; i++) _buildClassBar(i, classProbabilities[i] ?? 0.0),
      ],
    );
  }

  Widget _buildClassBar(int level, double prob) {
    final severity = DRSeverity.fromLevel(level);
    final bool isPredicted = level == predictedLevel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: severity.color,
                      shape: BoxShape.circle,
                      boxShadow: isPredicted
                          ? [
                              BoxShadow(
                                color: severity.color.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'L$level: ${severity.shortName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isPredicted ? FontWeight.w800 : FontWeight.w500,
                      color: isPredicted
                          ? (isDark ? Colors.white : AppColors.textPrimary)
                          : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              Text(
                AppFormatters.formatProbability(prob),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isPredicted ? FontWeight.w800 : FontWeight.w600,
                  color: isPredicted
                      ? severity.color
                      : (isDark ? AppColors.darkTextMuted : AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: prob,
              minHeight: isPredicted ? 7 : 5,
              backgroundColor: isDark ? AppColors.elevatedSurface : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPredicted ? severity.color : severity.color.withValues(alpha: 0.40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
