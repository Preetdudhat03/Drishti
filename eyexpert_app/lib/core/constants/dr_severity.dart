import 'package:flutter/material.dart';

enum DRSeverity {
  level0(
    level: 0,
    shortName: 'No DR',
    fullName: 'No Apparent Diabetic Retinopathy',
    description: 'No microaneurysms, hemorrhages, or retinal lesions detected.',
    isReferable: false,
    color: Color(0xFF1B8755),
    recommendation: 'Routine annual diabetic eye screening recommended.',
  ),
  level1(
    level: 1,
    shortName: 'Mild NPDR',
    fullName: 'Mild Non-Proliferative Diabetic Retinopathy',
    description: 'Microaneurysms only. Early disease stage.',
    isReferable: false,
    color: Color(0xFF007791),
    recommendation: 'Repeat screening in 6 to 12 months with glycemic control counseling.',
  ),
  level2(
    level: 2,
    shortName: 'Moderate NPDR',
    fullName: 'Moderate Non-Proliferative Diabetic Retinopathy',
    description: 'More than microaneurysms but less than severe NPDR (hard exudates/cotton wool spots).',
    isReferable: true,
    color: Color(0xFFE67E22),
    recommendation: 'Ophthalmologist review and dilated fundus examination recommended within 2 to 4 months.',
  ),
  level3(
    level: 3,
    shortName: 'Severe NPDR',
    fullName: 'Severe Non-Proliferative Diabetic Retinopathy',
    description: 'Significant hemorrhages, venous beading, or IRMA according to 4:2:1 clinical criteria.',
    isReferable: true,
    color: Color(0xFFD9534F),
    recommendation: 'Urgent ophthalmologist referral within 2 to 4 weeks for evaluation and potential intervention.',
  ),
  level4(
    level: 4,
    shortName: 'Proliferative DR',
    fullName: 'Proliferative Diabetic Retinopathy',
    description: 'Neovascularization of the disc/retina and/or vitreous/preretinal hemorrhage.',
    isReferable: true,
    color: Color(0xFFC0392B),
    recommendation: 'High-priority urgent referral to a retina specialist for immediate panretinal photocoagulation or anti-VEGF assessment.',
  );

  final int level;
  final String shortName;
  final String fullName;
  final String description;
  final bool isReferable;
  final Color color;
  final String recommendation;

  const DRSeverity({
    required this.level,
    required this.shortName,
    required this.fullName,
    required this.description,
    required this.isReferable,
    required this.color,
    required this.recommendation,
  });

  static DRSeverity fromLevel(int level) {
    switch (level) {
      case 0:
        return DRSeverity.level0;
      case 1:
        return DRSeverity.level1;
      case 2:
        return DRSeverity.level2;
      case 3:
        return DRSeverity.level3;
      case 4:
        return DRSeverity.level4;
      default:
        return DRSeverity.level0;
    }
  }

  static bool checkIsReferable(int level) => level >= 2;
}
