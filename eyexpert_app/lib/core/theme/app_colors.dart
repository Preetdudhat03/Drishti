import 'package:flutter/material.dart';

/// Drishti "Future Clinical Intelligence" Design System Tokens
/// 80% Neutral Surfaces, 15% Structure & Typography, 5% AI Accents
class AppColors {
  // ----------------- 1. PRIMARY WORKSTATION FOUNDATION -----------------
  static const Color obsidian = Color(0xFF080B12); // Deepest viewport background
  static const Color deepSpace = Color(0xFF0D111C); // Workstation canvas base
  static const Color graphite = Color(0xFF151B28); // Standard panel / card surface
  static const Color elevatedSurface = Color(0xFF1B2230); // Hovered / interactive surface
  static const Color borderDark = Color(0xFF273143); // Precision 1px HUD border
  static const Color borderSubtle = Color(0xFF1E2638); // Secondary divider

  // Light Mode Foundation
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightElevated = Color(0xFFEDF2F7);

  // Default Theme aliases for backward-compatible routing
  static const Color primary = deepSpace;
  static const Color primaryDark = obsidian;
  static const Color primaryLight = elevatedSurface;
  static const Color secondary = graphite;
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color border = lightBorder;

  // ----------------- 2. AI & COMPUTER VISION ACCENTS (5%) -----------------
  static const Color electricBlue = Color(0xFF4F8CFF); // Primary AI action, selection, active workflow
  static const Color aiViolet = Color(0xFF8B5CF6); // Grad-CAM activation & neural attention
  static const Color hudCyan = Color(0xFF22D3EE); // Optical reticle, scanning lines, live metrics
  static const Color accent = electricBlue;
  static const Color accentLight = Color(0xFFEBF3FF);

  // ----------------- 3. CLINICAL SEMANTIC STATES -----------------
  static const Color statusGood = Color(0xFF22C55E); // ✓ Optimal / Normal L0
  static const Color statusGoodBg = Color(0xFFF0FDF4);
  static const Color statusGoodDarkBg = Color(0xFF092B15);

  static const Color statusBorderline = Color(0xFFF59E0B); // ⚠ Borderline / CLAHE target
  static const Color statusBorderlineBg = Color(0xFFFEF3C7);
  static const Color statusBorderlineDarkBg = Color(0xFF332004);

  static const Color statusUngradable = Color(0xFFF43F5E); // ✕ Ungradable / Safety block
  static const Color statusUngradableBg = Color(0xFFFFF1F2);
  static const Color statusUngradableDarkBg = Color(0xFF3B0B14);

  static const Color referableAlert = Color(0xFFFB3B4B); // ⚠ Referable DR (L2-L4)
  static const Color referableAlertBg = Color(0xFFFFECEE);
  static const Color referableDarkBg = Color(0xFF450A11);

  static const Color pending = Color(0xFF60A5FA); // Awaiting Clinician Triage
  static const Color pendingBg = Color(0xFFEFF6FF);
  static const Color pendingDarkBg = Color(0xFF0E223D);

  static const Color validated = Color(0xFF34D399); // Confirmed Clinician Sign-off
  static const Color validatedBg = Color(0xFFECFDF5);
  static const Color validatedDarkBg = Color(0xFF063321);

  // ----------------- 4. TYPOGRAPHY & CONTRAST -----------------
  static const Color textPrimary = Color(0xFF0F172A); // High-contrast dark
  static const Color textSecondary = Color(0xFF475569); // Mid-tone
  static const Color textMuted = Color(0xFF94A3B8); // Low-emphasis

  static const Color darkTextPrimary = Color(0xFFF8FAFC); // High-contrast light on dark
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Mid-tone on dark
  static const Color darkTextMuted = Color(0xFF64748B); // Low-emphasis on dark

  // ----------------- 5. WORKSTATION HUD & BANNER -----------------
  static const Color offlineBannerBg = Color(0xFF1E293B);
  static const Color offlineBannerText = Color(0xFFF8FAFC);
  static const Color hudGlow = Color(0x3322D3EE);
}
