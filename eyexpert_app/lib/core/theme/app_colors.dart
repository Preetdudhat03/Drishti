import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // DiagnoX / Modern Ethereal AI Healthcare Palette
  // ==========================================
  static const Color background = Color(0xFFF8FAFC); // Clean Canvas Light
  static const Color surface = Color(0xFFFFFFFF); // Pure White Surface
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Elevated Surface
  static const Color surfaceMuted = Color(0xFFF1F5F9); // Crisp Slate 100
  static const Color border = Color(0xFFE2E8F0); // Sleek Border
  static const Color borderLight = Color(0xFFF1F5F9);
  static const Color borderFocused = Color(0xFF0D7C85); // Ocean Cyan Focus

  // Ambient Mesh Background Gradients
  static const Color meshCyan = Color(0x3338BDF8); // Ambient Top Glow (20% Opacity)
  static const Color meshTeal = Color(0x2B0D7C85);
  static const Color meshPeach = Color(0x2EFDBA74); // Ambient Bottom Glow (18% Opacity)
  static const Color meshRose = Color(0x1EFECDD3);

  // ==========================================
  // Brand & AI Diagnostic Action Accents
  // ==========================================
  static const Color primary = Color(0xFF0D7C85); // DiagnoX Ocean Cyan CTA
  static const Color primaryDark = Color(0xFF085F67);
  static const Color primaryLight = Color(0xFFE6F4F5); // Soft Cyan Tint
  static const Color oceanTeal = Color(0xFF0D7C85);
  
  static const Color accent = Color(0xFF0D7C85);
  static const Color accentHover = Color(0xFF085F67);
  static const Color accentLight = Color(0xFFE6F4F5);
  static const Color secondary = Color(0xFF1E293B); // Dark Slate Capsule
  
  // Metallic Slider & Dark Capsule Elements
  static const Color sliderTrackDark = Color(0xFF1E293B);
  static const Color sliderThumbKnob = Color(0xFFFFFFFF);
  static const Color sliderThumbRing = Color(0xFFCBD5E1);

  // Backward compatibility aliases
  static const Color solarAmber = Color(0xFFF59E0B);
  static const Color laserGold = Color(0xFFEAB308);
  static const Color cyberOrange = Color(0xFFEA580C);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color electricBlue = Color(0xFF0D7C85);
  static const Color laserBlue = Color(0xFF0D7C85);
  static const Color cyberAzure = Color(0xFF0D7C85);
  static const Color aiViolet = Color(0xFF0D7C85);
  static const Color aiVioletLight = Color(0xFFE6F4F5);
  static const Color hudCyan = Color(0xFF0D7C85);
  static const Color hudCyanLight = Color(0xFFE6F4F5);

  // Gradients for Modern Cards & Accents
  static const LinearGradient primaryPillGradient = LinearGradient(
    colors: [Color(0xFF0E8A94), Color(0xFF0B6F77)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0D7C85), Color(0xFF085F67)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGlowGradient = LinearGradient(
    colors: [Color(0xFF0D7C85), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ==========================================
  // Typography Colors
  // ==========================================
  static const Color textPrimary = Color(0xFF0F172A); // High emphasis Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Medium emphasis Slate 500
  static const Color textMuted = Color(0xFF94A3B8); // Low emphasis Slate 400
  static const Color textDisabled = Color(0xFFCBD5E1); // Disabled Slate 300
  static const Color textBright = Color(0xFFFFFFFF); // White text on dark elements

  // ==========================================
  // DiagnoX Pastel Clinical Status & Risk Badges
  // ==========================================
  // High Risk (Red Flag / Severe)
  static const Color badgeHighRiskBg = Color(0xFFFEE2E2);
  static const Color badgeHighRiskText = Color(0xFFDC2626);
  static const Color badgeHighRiskBorder = Color(0xFFFECACA);

  // Moderate Risk / Warning
  static const Color badgeModerateBg = Color(0xFFFEF3C7);
  static const Color badgeModerateText = Color(0xFFD97706);
  static const Color badgeModerateBorder = Color(0xFFFDE68A);

  // Low Risk / Normal
  static const Color badgeLowRiskBg = Color(0xFFDCFCE7);
  static const Color badgeLowRiskText = Color(0xFF16A34A);
  static const Color badgeLowRiskBorder = Color(0xFFBBF7D0);

  // Tag / Attribute Pills
  static const Color tagBg = Color(0xFFF1F5F9);
  static const Color tagText = Color(0xFF334155);
  static const Color tagCyanBg = Color(0xFFE0F2FE);
  static const Color tagCyanText = Color(0xFF0284C7);

  // Semantic Status Aliases
  static const Color statusNormal = Color(0xFF16A34A);
  static const Color statusGood = Color(0xFF16A34A);
  static const Color statusGoodBg = Color(0xFFDCFCE7);

  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusBorderline = Color(0xFFD97706);
  static const Color statusBorderlineBg = Color(0xFFFEF3C7);

  static const Color statusCritical = Color(0xFFDC2626);
  static const Color statusUngradable = Color(0xFFDC2626);
  static const Color statusUngradableBg = Color(0xFFFEE2E2);
  static const Color referableAlert = Color(0xFFDC2626);
  static const Color referableAlertBg = Color(0xFFFEE2E2);

  static const Color statusInfo = Color(0xFF0D7C85);
  static const Color pending = Color(0xFFD97706);
  static const Color pendingBg = Color(0xFFFEF3C7);

  // Offline Status Banner
  static const Color offlineBannerBg = Color(0xFF1E293B);
  static const Color offlineBannerText = Color(0xFFF8FAFC);

  // Dark / Obsidian Compatibility Aliases
  static const Color obsidianDeep = Color(0xFF0F172A);
  static const Color obsidianCanvas = Color(0xFF0F172A);
  static const Color obsidianSurface = Color(0xFF1E293B);
  static const Color obsidianElevated = Color(0xFF334155);
  static const Color obsidianBorder = Color(0xFF334155);
  static const Color obsidianBorderGlow = Color(0xFF0D7C85);
  static const Color textSubtle = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
}
