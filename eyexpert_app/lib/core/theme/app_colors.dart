import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // Drishti Obsidian / Deep Space Palette
  // ==========================================
  static const Color obsidianDeep = Color(0xFF080B12); // Deep Space
  static const Color obsidianCanvas = Color(0xFF0D111C); // Dark Canvas
  static const Color obsidianSurface = Color(0xFF151B28); // Workstation Card Surface
  static const Color obsidianElevated = Color(0xFF1A2234); // Elevated Surface
  static const Color obsidianBorder = Color(0xFF243048); // Subtle 1px Grid Border
  static const Color obsidianBorderGlow = Color(0xFF3B82F6); // Active Focus/Glow

  // ==========================================
  // AI Clinical Accents & Highlights
  // ==========================================
  static const Color electricBlue = Color(0xFF4F8CFF); // Primary Active AI Accent
  static const Color aiViolet = Color(0xFF8B5CF6); // Explainability / Grad-CAM Accent
  static const Color hudCyan = Color(0xFF22D3EE); // HUD Telemetry / Retinal Scan
  static const Color medicalTeal = Color(0xFF0F766E); // Legacy / Clinical Action

  // ==========================================
  // Semantic Clinical Status Colors
  // ==========================================
  static const Color statusNormal = Color(0xFF10B981); // Emerald (Good / Non-referable)
  static const Color statusWarning = Color(0xFFF59E0B); // Amber (Borderline / Moderate DR)
  static const Color statusCritical = Color(0xFFEF4444); // Crimson (Severe / Referable DR)
  static const Color statusInfo = Color(0xFF3B82F6); // Electric Blue (Information)

  // ==========================================
  // Workstation Typography Colors (Dark Mode)
  // ==========================================
  static const Color textBright = Color(0xFFF8FAFC); // High emphasis heading
  static const Color textSubtle = Color(0xFF94A3B8); // Medium emphasis / labels
  static const Color textMutedDark = Color(0xFF64748B); // Low emphasis / hints
  static const Color textDisabled = Color(0xFF475569); // Inactive state

  // ==========================================
  // Classic / Compatibility Aliases
  // ==========================================
  static const Color primary = Color(0xFF0B1F33); // Deep Navy
  static const Color primaryDark = Color(0xFF06111D);
  static const Color primaryLight = Color(0xFFE2E8F0);
  
  static const Color accent = Color(0xFF4F8CFF); // Electric Blue default
  static const Color accentLight = Color(0xFF1E293B);
  static const Color secondary = Color(0xFF1E3A5F);

  // Background & Surfaces (Compatibility)
  static const Color background = Color(0xFF080B12); // Deep Space
  static const Color surface = Color(0xFF151B28); // Workstation Card
  static const Color border = Color(0xFF243048); // Subtle border

  // Typography (Compatibility)
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // Semantic Status Aliases
  static const Color statusGood = Color(0xFF10B981);
  static const Color statusGoodBg = Color(0xFF064E3B);

  static const Color statusBorderline = Color(0xFFF59E0B);
  static const Color statusBorderlineBg = Color(0xFF78350F);

  static const Color statusUngradable = Color(0xFFEF4444);
  static const Color statusUngradableBg = Color(0xFF7F1D1D);

  static const Color referableAlert = Color(0xFFEF4444);
  static const Color referableAlertBg = Color(0xFF7F1D1D);

  static const Color pending = Color(0xFF3B82F6);
  static const Color pendingBg = Color(0xFF1E3A8A);

  // Offline Banner
  static const Color offlineBannerBg = Color(0xFF1E293B);
  static const Color offlineBannerText = Color(0xFFF8FAFC);
}
