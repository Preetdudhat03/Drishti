import 'package:flutter/material.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';

class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigationIndexChanged;
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final UserModel? currentUser;
  final String workflowMode;
  final VoidCallback? onModeSwitchPressed;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onNavigationIndexChanged,
    required this.body,
    required this.title,
    this.actions,
    this.currentUser,
    this.workflowMode = 'DEMO',
    this.onModeSwitchPressed,
    this.floatingActionButton,
  });

  List<NavigationDestination> _getDestinations(UserRole? role) {
    if (role == UserRole.clinician) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.rate_review_outlined),
          selectedIcon: Icon(Icons.rate_review_rounded),
          label: 'Reviews',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: 'System',
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
        label: 'Dashboard',
      ),
      NavigationDestination(
        icon: Icon(Icons.camera_enhance_outlined),
        selectedIcon: Icon(Icons.camera_enhance_rounded),
        label: 'Screening',
      ),
      NavigationDestination(
        icon: Icon(Icons.folder_shared_outlined),
        selectedIcon: Icon(Icons.folder_shared_rounded),
        label: 'Cases',
      ),
      NavigationDestination(
        icon: Icon(Icons.cloud_sync_outlined),
        selectedIcon: Icon(Icons.cloud_sync_rounded),
        label: 'Sync Queue',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person_rounded),
        label: 'Profile',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isTablet = ResponsiveLayout.isTablet(context);
    final destinations = _getDestinations(currentUser?.role);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
                const SizedBox(width: 8),
                // Mode Pill
                InkWell(
                  onTap: onModeSwitchPressed,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: workflowMode == 'VALIDATION'
                          ? AppColors.secondary.withOpacity(0.15)
                          : AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: workflowMode == 'VALIDATION' ? AppColors.secondary : AppColors.primary,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      workflowMode == 'VALIDATION'
                          ? 'VALIDATION: REAL APTOS'
                          : 'DEMO: SIMULATED WORKFLOW',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: workflowMode == 'VALIDATION' ? AppColors.secondary : AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (currentUser != null)
              Text(
                '${currentUser!.isDemoAccount ? "DEMO " : ""}${currentUser!.role.displayName.toUpperCase()} • ${currentUser!.name}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        actions: actions,
      ),
      body: Row(
        children: [
          if (isDesktop || isTablet)
            NavigationRail(
              selectedIndex: currentIndex.clamp(0, destinations.length - 1),
              onDestinationSelected: onNavigationIndexChanged,
              labelType: isDesktop
                  ? NavigationRailLabelType.all
                  : NavigationRailLabelType.selected,
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
          if (isDesktop || isTablet) const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? NavigationBar(
              selectedIndex: currentIndex.clamp(0, destinations.length - 1),
              onDestinationSelected: onNavigationIndexChanged,
              destinations: destinations,
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
