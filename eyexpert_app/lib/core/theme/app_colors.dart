import 'package:flutter/material.dart';

class AppColors {
  // Clinical Teal / Slate Palette
  static const Color primary = Color(0xFF0D6E6E);
  static const Color primaryDark = Color(0xFF084B4B);
  static const Color primaryLight = Color(0xFFE6F3F3);
  static const Color secondary = Color(0xFF2C5E7A);
  static const Color accent = Color(0xFF00A896);

  // Clinical Status Semantic Colors (High contrast, paired with icons)
  static const Color statusGood = Color(0xFF1B8755);
  static const Color statusGoodBg = Color(0xFFE8F5E9);
  
  static const Color statusBorderline = Color(0xFFD97706);
  static const Color statusBorderlineBg = Color(0xFFFEF3C7);
  
  static const Color statusUngradable = Color(0xFFDC2626);
  static const Color statusUngradableBg = Color(0xFFFEE2E2);

  static const Color referableAlert = Color(0xFFB91C1C);
  static const Color referableAlertBg = Color(0xFFFFECEC);

  static const Color nonReferable = Color(0xFF15803D);
  static const Color nonReferableBg = Color(0xFFF0FDF4);

  // Neutral Colors (Light mode)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF94A3B8);

  // Neutral Colors (Dark mode - clinical high contrast for fundus image viewing)
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceElevatedDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF64748B);

  // Offline / Sync banner colors
  static const Color offlineBannerBg = Color(0xFF475569);
  static const Color offlineBannerText = Color(0xFFFFFFFF);
}
