import 'package:flutter/material.dart';

class AppColors {
  // Drishti Clinical Intelligence Palette
  static const Color primary = Color(0xFF0B1F33); // Deep Navy
  static const Color primaryDark = Color(0xFF06111D);
  static const Color primaryLight = Color(0xFFE2E8F0);
  
  static const Color accent = Color(0xFF0F766E); // Medical Teal
  static const Color accentLight = Color(0xFFE6F4F2);
  static const Color secondary = Color(0xFF1E3A5F);

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC); // Clinical Off-White
  static const Color surface = Color(0xFFFFFFFF); // Pure White Card
  static const Color border = Color(0xFFE2E8F0); // Subtle 1px border

  // Typography Colors
  static const Color textPrimary = Color(0xFF0F172A); // Dark Slate
  static const Color textSecondary = Color(0xFF64748B); // Slate
  static const Color textMuted = Color(0xFF94A3B8);

  // Semantic Clinical Status Colors
  static const Color statusGood = Color(0xFF15803D); // ✓ GOOD
  static const Color statusGoodBg = Color(0xFFF0FDF4);

  static const Color statusBorderline = Color(0xFFD97706); // ⚠ BORDERLINE
  static const Color statusBorderlineBg = Color(0xFFFEF3C7);

  static const Color statusUngradable = Color(0xFFDC2626); // ✕ UNGRADABLE
  static const Color statusUngradableBg = Color(0xFFFEF2F2);

  static const Color referableAlert = Color(0xFFB91C1C); // ⚠ REFERABLE DR
  static const Color referableAlertBg = Color(0xFFFFF1F2);

  static const Color pending = Color(0xFF2563EB); // Pending Review
  static const Color pendingBg = Color(0xFFEFF6FF);

  // Offline Banner
  static const Color offlineBannerBg = Color(0xFF334155);
  static const Color offlineBannerText = Color(0xFFFFFFFF);
}
