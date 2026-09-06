import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  // App Title
  static const TextStyle appTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: AppColors.textPrimary,
  );

  // Page Headings
  static const TextStyle pageHeading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  // Section Headings
  static const TextStyle sectionHeading = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // Body
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // Dominant Clinical Result
  static const TextStyle clinicalResultLevel = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.8,
  );

  static const TextStyle clinicalResultSeverity = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
  );

  // Badges & Labels
  static const TextStyle badgeLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  // Telemetry Code / Monospace
  static const TextStyle telemetryCode = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
}
