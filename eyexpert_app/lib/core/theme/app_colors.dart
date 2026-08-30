import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // Drishti Clinical Light Theme Palette
  // ==========================================
  static const Color background = Color(0xFFF8FAFC); // Crisp Slate-50 Background
  static const Color surface = Color(0xFFFFFFFF); // Pure White Card Surface
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Elevated Surface
  static const Color border = Color(0xFFE2E8F0); // Clean Slate-200 Border
  static const Color borderFocused = Color(0xFF0F766E); // Medical Teal Focus Border

  // ==========================================
  // Brand & Clinical Accents
  // ==========================================
  static const Color primary = Color(0xFF0B1F33); // Deep Navy (Header / Brand)
  static const Color primaryDark = Color(0xFF06111D);
  static const Color primaryLight = Color(0xFFF1F5F9); // Light Navy / Slate Tint
  
  static const Color accent = Color(0xFF0F766E); // Medical Teal
  static const Color accentLight = Color(0xFFF0FDFA); // Soft Teal Tint
  static const Color secondary = Color(0xFF1E3A5F);
  static const Color electricBlue = Color(0xFF2563EB); // Royal / Electric Blue
  static const Color aiViolet = Color(0xFF7C3AED); // Grad-CAM / AI Explainability Violet
  static const Color hudCyan = Color(0xFF0891B2); // Cyan Telemetry

  // ==========================================
  // Typography Colors (Light Mode)
  // ==========================================
  static const Color textPrimary = Color(0xFF0F172A); // High emphasis Slate-900
  static const Color textSecondary = Color(0xFF475569); // Medium emphasis Slate-600
  static const Color textMuted = Color(0xFF94A3B8); // Low emphasis Slate-400
  static const Color textDisabled = Color(0xFFCBD5E1); // Disabled Slate-300
  static const Color textBright = Color(0xFFFFFFFF); // White text on dark elements

  // ==========================================
  // Semantic Clinical Status & Alert Colors
  // ==========================================
  static const Color statusNormal = Color(0xFF059669); // Emerald
  static const Color statusGood = Color(0xFF059669);
  static const Color statusGoodBg = Color(0xFFECFDF5); // Soft Emerald Tint

  static const Color statusWarning = Color(0xFFD97706); // Amber
  static const Color statusBorderline = Color(0xFFD97706);
  static const Color statusBorderlineBg = Color(0xFFFFFBEB); // Soft Amber Tint

  static const Color statusCritical = Color(0xFFDC2626); // Crimson Red
  static const Color statusUngradable = Color(0xFFDC2626);
  static const Color statusUngradableBg = Color(0xFFFEF2F2); // Soft Crimson Tint
  static const Color referableAlert = Color(0xFFDC2626);
  static const Color referableAlertBg = Color(0xFFFEF2F2);

  static const Color statusInfo = Color(0xFF2563EB);
  static const Color pending = Color(0xFF2563EB);
  static const Color pendingBg = Color(0xFFEFF6FF); // Soft Blue Tint

  // Offline Status Banner
  static const Color offlineBannerBg = Color(0xFF0F172A);
  static const Color offlineBannerText = Color(0xFFF8FAFC);

  // ==========================================
  // Dark / Obsidian Workstation Aliases
  // (Maintained for widgets that request dark HUD accents)
  // ==========================================
  static const Color obsidianDeep = Color(0xFF080B12);
  static const Color obsidianCanvas = Color(0xFF0D111C);
  static const Color obsidianSurface = Color(0xFF151B28);
  static const Color obsidianElevated = Color(0xFF1A2234);
  static const Color obsidianBorder = Color(0xFF243048);
  static const Color obsidianBorderGlow = Color(0xFF3B82F6);
  static const Color textSubtle = Color(0xFF64748B);
  static const Color textMutedDark = Color(0xFF64748B);
}
