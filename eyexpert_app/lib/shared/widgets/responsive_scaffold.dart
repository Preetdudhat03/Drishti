import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/theme/app_colors.dart';
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

  List<NavigationDestination> _getDestinations(UserRole? role) {
    if (role == UserRole.clinician) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.speed_rounded),
          selectedIcon: Icon(Icons.speed_rounded),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.fact_check_outlined),
          selectedIcon: Icon(Icons.fact_check_rounded),
          label: 'Review Queue',
        ),
        NavigationDestination(
          icon: Icon(Icons.grid_view_rounded),
          selectedIcon: Icon(Icons.grid_view_sharp),
          label: 'All Cases',
        ),
        NavigationDestination(
          icon: Icon(Icons.monitor_heart_outlined),
          selectedIcon: Icon(Icons.monitor_heart_rounded),
          label: 'System Status',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description_rounded),
          label: 'Clinical Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.badge_outlined),
          selectedIcon: Icon(Icons.badge_rounded),
          label: 'Credentials',
        ),
      ];
    }

    return const [
      NavigationDestination(
        icon: Icon(Icons.space_dashboard_outlined),
        selectedIcon: Icon(Icons.space_dashboard_rounded),
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.camera_enhance_outlined),
        selectedIcon: Icon(Icons.camera_enhance_rounded),
        label: 'New Intake',
      ),
      NavigationDestination(
        icon: Icon(Icons.folder_shared_outlined),
        selectedIcon: Icon(Icons.folder_shared_rounded),
        label: 'Patients',
      ),
      NavigationDestination(
        icon: Icon(Icons.sync_rounded),
        selectedIcon: Icon(Icons.sync_rounded),
        label: 'Rural Sync',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Sign Out from Workstation?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text('Your local offline session state will be safely preserved.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
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
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final destinations = _getDestinations(currentUser?.role);
    final isClinician = currentUser?.role == UserRole.clinician;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.7),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Brand Emblem
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.remove_red_eye_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        
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
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight.withValues(alpha: 0.8),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'AI v2.4',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (currentUser != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '${isClinician ? "OPHTHALMOLOGY SPECIALIST" : "PRIMARY CARE SCREENER"} • ${currentUser!.organization.toUpperCase()}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Actions & Status
                        ConnectionStatusPill(isCompact: !isDesktop),
                        if (actions != null) ...actions!,
                        const SizedBox(width: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 18),
                            tooltip: 'Sign Out',
                            onPressed: () => _showLogoutDialog(context, ref),
                          ),
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
        child: Row(
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
                indicatorColor: AppColors.primaryLight.withValues(alpha: 0.8),
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
            if (isDesktop || isTablet)
              const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.7),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: NavigationBarTheme(
                        data: NavigationBarThemeData(
                          height: 64,
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          indicatorColor: AppColors.primaryLight.withValues(alpha: 0.8),
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
      floatingActionButton: floatingActionButton,
    );
  }
}
