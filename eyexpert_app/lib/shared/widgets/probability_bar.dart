import 'package:flutter/material.dart';
import '../../core/constants/dr_severity.dart';
import '../../core/utils/formatters.dart';

class ProbabilityDistributionWidget extends StatelessWidget {
  final Map<int, double> classProbabilities;
  final int predictedLevel;

  const ProbabilityDistributionWidget({
    super.key,
    required this.classProbabilities,
    required this.predictedLevel,
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
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: severity.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Level $level: ${severity.shortName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isPredicted ? FontWeight.w700 : FontWeight.w500,
                      color: isPredicted ? Colors.black87 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              Text(
                AppFormatters.formatProbability(prob),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isPredicted ? FontWeight.w700 : FontWeight.w500,
                  color: isPredicted ? severity.color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: prob,
              minHeight: isPredicted ? 8 : 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isPredicted ? severity.color : severity.color.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
