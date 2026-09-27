import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/services/audio_guidance_service.dart';
import '../../data/models/user_model.dart';
import '../../features/auth/auth_provider.dart';
import 'connection_status_pill.dart';
import 'ethereal_background.dart';

class ResponsiveScaffold extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationIndexChanged;
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final UserModel? currentUser;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationIndexChanged,
    required this.body,
    required this.title,
    this.actions,
    this.currentUser,
    this.floatingActionButton,
  });

  List<NavigationDestination> _getDestinations(UserRole? role, String Function(String) tr) {
    if (role == UserRole.clinician) {
      return [
        NavigationDestination(
          icon: const Icon(Icons.fact_check_outlined),
          selectedIcon: const Icon(Icons.fact_check_rounded),
          label: tr('nav_queue'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.grid_view_rounded),
          selectedIcon: const Icon(Icons.grid_view_sharp),
          label: tr('nav_cases'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.speed_rounded),
          selectedIcon: const Icon(Icons.speed_rounded),
          label: tr('nav_overview'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.description_outlined),
          selectedIcon: const Icon(Icons.description_rounded),
          label: tr('nav_reports'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person_rounded),
          label: tr('nav_profile'),
        ),
      ];
    }

    if (role == UserRole.healthWorker || role == UserRole.admin) {
      return [
        NavigationDestination(
          icon: const Icon(Icons.space_dashboard_outlined),
          selectedIcon: const Icon(Icons.space_dashboard_rounded),
          label: tr('nav_dashboard'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.camera_enhance_outlined),
          selectedIcon: const Icon(Icons.camera_enhance_rounded),
          label: tr('nav_intake'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.folder_shared_outlined),
          selectedIcon: const Icon(Icons.folder_shared_rounded),
          label: tr('nav_patients'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.sync_rounded),
          selectedIcon: const Icon(Icons.sync_rounded),
          label: tr('nav_sync'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: const Icon(Icons.person_rounded),
          label: tr('nav_profile'),
        ),
      ];
    }

    return [
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person_rounded),
        label: tr('nav_profile'),
      ),
    ];
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final tr = ref.read(trProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(tr('sign_out_title'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text(tr('sign_out_desc'), style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.badgeHighRiskBg,
              foregroundColor: AppColors.badgeHighRiskText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(tr('sign_out'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context, WidgetRef ref) {
    final currentCode = ref.read(localeProvider);
    final tr = ref.read(trProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final scrollController = ScrollController();
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top drag handle bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr('select_language'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('language_subtitle'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                // Scrollable Language Items with custom Scrollbar
                Flexible(
                  child: Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(8),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Column(
                        children: [
                          for (final lang in AppLocalizations.supportedLanguages) ...[
                            InkWell(
                              onTap: () {
                                ref.read(localeProvider.notifier).setLanguage(lang.code);
                                Navigator.pop(ctx);
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: lang.code == currentCode
                                      ? AppColors.primaryLight
                                      : AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: lang.code == currentCode
                                        ? AppColors.primary
                                        : AppColors.border,
                                    width: lang.code == currentCode ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(lang.flag, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            lang.localName,
                                            style: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: FontWeight.w800,
                                              color: lang.code == currentCode
                                                  ? AppColors.primary
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            lang.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (lang.code == currentCode)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: 15,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isClinician = currentUser?.role == UserRole.clinician;
    final tr = ref.watch(trProvider);
    final destinations = _getDestinations(currentUser?.role, tr);
    final currentLang = ref.watch(currentLanguageProvider);
    final isAudioEnabled = ref.watch(audioGuidanceEnabledProvider);
    final activeAudioCue = ref.watch(activeAudioCueProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(84),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.8),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Brand Emblem
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                          ),
                          child: const Icon(
                            Icons.remove_red_eye_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        
                        // Title & Role
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      title,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'SIH 2026',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (currentUser != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Text(
                                    isClinician
                                        ? tr('specialist')
                                        : tr('phc_screener'),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Fast Role Switcher Pill for Jury / Evaluation
                        InkWell(
                          onTap: () {
                            final nextRole = isClinician ? UserRole.healthWorker : UserRole.clinician;
                            ref.read(authProvider.notifier).switchWorkspaceRole(nextRole);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: isClinician ? const Color(0xFFFEF3C7) : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isClinician ? const Color(0xFFF59E0B) : AppColors.primary,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isClinician ? Icons.medical_services_outlined : Icons.health_and_safety_outlined,
                                  size: 14,
                                  color: isClinician ? const Color(0xFFB45309) : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isMobile
                                      ? (isClinician ? 'Screener' : 'Doctor')
                                      : (isClinician ? tr('switch_to_screener') : tr('switch_to_doctor')),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: isClinician ? const Color(0xFFB45309) : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Audio Guidance Toggle
                        IconButton(
                          icon: Icon(
                            isAudioEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: isAudioEnabled ? AppColors.primary : AppColors.textMuted,
                            size: 19,
                          ),
                          tooltip: tr('audio_guide'),
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: () => ref.read(audioGuidanceEnabledProvider.notifier).toggle(),
                        ),
                        const SizedBox(width: 4),

                        // Language Selector Pill
                        InkWell(
                          onTap: () => _showLanguageModal(context, ref),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(currentLang.flag, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 3),
                                Text(
                                  currentLang.code.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Online/Offline Status Indicator
                        ConnectionStatusPill(isCompact: true),
                        if (actions != null) ...actions!,
                        const SizedBox(width: 4),

                        // Sign Out Button
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 18),
                          tooltip: 'Sign Out',
                          padding: const EdgeInsets.all(6),
                          constraints: const BoxConstraints(),
                          onPressed: () => _showLogoutDialog(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: EtherealBackground(
        child: Stack(
          children: [
            Row(
              children: [
                if (isDesktop || isTablet)
                  NavigationRail(
                    backgroundColor: Colors.transparent,
                    selectedIndex: currentIndex.clamp(0, destinations.length - 1),
                    onDestinationSelected: onNavigationIndexChanged,
                    labelType: isDesktop
                        ? NavigationRailLabelType.all
                        : NavigationRailLabelType.selected,
                    unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
                    selectedIconTheme: const IconThemeData(
                      color: AppColors.primary,
                      size: 24,
                    ),
                    indicatorColor: AppColors.primaryLight,
                    unselectedLabelTextStyle: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                    destinations: destinations
                        .map(
                          (d) => NavigationRailDestination(
                            icon: d.icon,
                            selectedIcon: d.selectedIcon,
                            label: Text(d.label),
                          ),
                        )
                        .toList(),
                  ),
                Expanded(child: body),
              ],
            ),

            // Floating Audio Guidance Cue Subtitle Banner
            if (activeAudioCue != null)
              Positioned(
                top: ResponsiveLayout.topBarClearance(context) - 20,
                left: 16,
                right: 16,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, val, child) {
                    return Opacity(
                      opacity: val,
                      child: Transform.translate(
                        offset: Offset(0, (1 - val) * -10),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                activeAudioCue.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (activeAudioCue.hindiText != null && currentLang.code != 'en')
                                Text(
                                  activeAudioCue.hindiText!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => ref.read(activeAudioCueProvider.notifier).clear(),
                          child: const Icon(Icons.close_rounded, color: Colors.white70, size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: (isMobile)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.8),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: NavigationBarTheme(
                        data: NavigationBarThemeData(
                          height: 64,
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          indicatorColor: AppColors.primaryLight,
                          indicatorShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelTextStyle: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              );
                            }
                            return const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            );
                          }),
                          iconTheme: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const IconThemeData(
                                color: AppColors.primary,
                                size: 22,
                              );
                            }
                            return const IconThemeData(
                              color: AppColors.textSecondary,
                              size: 22,
                            );
                          }),
                        ),
                        child: NavigationBar(
                          backgroundColor: Colors.transparent,
                          selectedIndex: currentIndex.clamp(0, destinations.length - 1),
                          onDestinationSelected: onNavigationIndexChanged,
                          destinations: destinations,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButton: isClinician ? null : floatingActionButton,
    );
  }
}
