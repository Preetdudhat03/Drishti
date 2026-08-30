import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import '../../features/auth/auth_provider.dart';
import 'drishti_logo.dart';
import 'connection_status_pill.dart';

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
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.rate_review_outlined),
          selectedIcon: Icon(Icons.rate_review_rounded),
          label: 'Review Queue',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_shared_outlined),
          selectedIcon: Icon(Icons.folder_shared_rounded),
          label: 'Cases',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: 'Analytics',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description_rounded),
          label: 'Reports',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ];
    }

    return const [
      NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard_rounded),
        label: 'Home',
      ),
      NavigationDestination(
        icon: Icon(Icons.camera_enhance_outlined),
        selectedIcon: Icon(Icons.camera_enhance_rounded),
        label: 'Screening',
      ),
      NavigationDestination(
        icon: Icon(Icons.folder_shared_outlined),
        selectedIcon: Icon(Icons.folder_shared_rounded),
        label: 'Patients',
      ),
      NavigationDestination(
        icon: Icon(Icons.cloud_sync_outlined),
        selectedIcon: Icon(Icons.cloud_sync_rounded),
        label: 'Sync',
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
        backgroundColor: AppColors.obsidianSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.obsidianBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout_outlined, color: AppColors.statusWarning, size: 20),
            SizedBox(width: 10),
            Text(
              'Sign out of Drishti?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textBright,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your current screening data will remain safely synchronized.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSubtle,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSubtle),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCritical,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Sign Out'),
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
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF080B12), Color(0xFF0D111C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.obsidianBorder,
                width: 1,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            const DrishtiLogo(
              size: 32,
              showText: false,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (currentUser != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isClinician ? AppColors.aiViolet : AppColors.electricBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              '${currentUser!.role.displayName.toUpperCase()} • ${currentUser!.name}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textSubtle,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: ConnectionStatusPill(isCompact: !isDesktop),
          ),
          if (actions != null) ...actions!,
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: AppColors.textSubtle, size: 20),
            tooltip: 'Sign Out',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop || isTablet)
            NavigationRail(
              backgroundColor: AppColors.obsidianCanvas,
              selectedIndex: currentIndex.clamp(0, destinations.length - 1),
              onDestinationSelected: onNavigationIndexChanged,
              labelType: isDesktop
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.selected,
              unselectedIconTheme: const IconThemeData(color: AppColors.textSubtle),
              selectedIconTheme: IconThemeData(
                color: isClinician ? AppColors.aiViolet : AppColors.electricBlue,
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: AppColors.textSubtle,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              selectedLabelTextStyle: TextStyle(
                color: isClinician ? AppColors.aiViolet : AppColors.electricBlue,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
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
            const VerticalDivider(thickness: 1, width: 1, color: AppColors.obsidianBorder),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? NavigationBar(
              backgroundColor: AppColors.obsidianCanvas,
              indicatorColor: (isClinician ? AppColors.aiViolet : AppColors.electricBlue).withValues(alpha: 0.2),
              selectedIndex: currentIndex.clamp(0, destinations.length - 1),
              onDestinationSelected: onNavigationIndexChanged,
              destinations: destinations,
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}

