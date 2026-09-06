import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ConfidenceSliderCard extends StatefulWidget {
  final String title;
  final String riskLabel;
  final bool isHighRisk;
  final double confidence; // 0.0 to 1.0
  final String explanation;
  final List<String>? clinicalFindings;

  const ConfidenceSliderCard({
    super.key,
    required this.title,
    required this.riskLabel,
    required this.isHighRisk,
    required this.confidence,
    required this.explanation,
    this.clinicalFindings,
  });

  @override
  State<ConfidenceSliderCard> createState() => _ConfidenceSliderCardState();
}

class _ConfidenceSliderCardState extends State<ConfidenceSliderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final int percentInt = (widget.confidence * 100).round();
    final double clampedConf = widget.confidence.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Condition Title & Risk Pill Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.isHighRisk
                      ? AppColors.badgeHighRiskBg
                      : AppColors.badgeLowRiskBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isHighRisk
                        ? AppColors.badgeHighRiskBorder
                        : AppColors.badgeLowRiskBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.riskLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.isHighRisk
                        ? AppColors.badgeHighRiskText
                        : AppColors.badgeLowRiskText,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Dark Capsule Slider Track with Metallic Knurled Knob
          LayoutBuilder(
            builder: (context, constraints) {
              final double trackWidth = constraints.maxWidth;
              const double trackHeight = 22;
              const double knobSize = 26;
              final double maxKnobOffset = trackWidth - knobSize;
              final double currentKnobOffset = maxKnobOffset * clampedConf;

              return SizedBox(
                height: 32,
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Outer background capsule track
                    Container(
                      width: trackWidth,
                      height: trackHeight,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(trackHeight / 2),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                    ),

                    // Filled Active Dark Track
                    Container(
                      width: (currentKnobOffset + (knobSize / 2)).clamp(trackHeight, trackWidth),
                      height: trackHeight,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                        ),
                        borderRadius: BorderRadius.circular(trackHeight / 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),

                    // 3D Metallic Slider Knob
                    Positioned(
                      left: currentKnobOffset.clamp(0.0, maxKnobOffset),
                      child: Container(
                        width: knobSize,
                        height: knobSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // Confidence Readout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONFIDENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                '$percentInt%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // "Why this diagnosis?" Expandable Action
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Why this diagnosis?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.explanation,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (widget.clinicalFindings != null &&
                      widget.clinicalFindings!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'CLINICAL MARKERS:',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.clinicalFindings!
                          .map(
                            (f) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                f,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
