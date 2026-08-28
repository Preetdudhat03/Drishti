import 'package:flutter/material.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class ProbabilityDistributionWidget extends StatelessWidget {
  final Map<int, double>? classProbabilities;
  final List<double>? probabilities;
  final int predictedLevel;
  final bool isDarkMode;

  const ProbabilityDistributionWidget({
    super.key,
    this.classProbabilities,
    this.probabilities,
    required this.predictedLevel,
    this.isDarkMode = false,
    bool isDark = false,
  });

  double _getProb(int level) {
    if (classProbabilities != null && classProbabilities!.containsKey(level)) {
      return classProbabilities![level]!;
    }
    if (probabilities != null && level < probabilities!.length) {
      return probabilities![level];
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i <= 4; i++) _buildClassBar(i, _getProb(i)),
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
                          ? (isDarkMode ? Colors.white : AppColors.textPrimary)
                          : (isDarkMode ? AppColors.darkTextSecondary : AppColors.textSecondary),
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
                      : (isDarkMode ? AppColors.darkTextMuted : AppColors.textMuted),
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
              backgroundColor: isDarkMode ? AppColors.elevatedSurface : Colors.grey.shade200,
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

