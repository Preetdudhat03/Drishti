import 'package:flutter/material.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';
import 'drishti_logo.dart';

class ResponsiveScaffold extends StatelessWidget {
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
          icon: Icon(Icons.rate_review_outlined),
          selectedIcon: Icon(Icons.rate_review_rounded),
          label: 'Review Queue',
        ),
        NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics_rounded),
          label: 'System Status',
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
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F1E36), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF334155),
                width: 1,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            const DrishtiLogo(
              size: 34,
              showText: false,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16.5,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
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
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
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
                                color: Color(0xFF94A3B8),
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
        actions: actions,
      ),
      body: Row(
        children: [
          if (isDesktop || isTablet)
            NavigationRail(
              backgroundColor: Colors.white,
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
                      label: Text(d.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  )
                  .toList(),
            ),
          if (isDesktop || isTablet) const VerticalDivider(thickness: 1, width: 1, color: AppColors.border),
          Expanded(child: body),
        ],
      ),
      bottomNavigationBar: (!isDesktop && !isTablet)
          ? NavigationBar(
              backgroundColor: Colors.white,
              indicatorColor: AppColors.accentLight,
              selectedIndex: currentIndex.clamp(0, destinations.length - 1),
              onDestinationSelected: onNavigationIndexChanged,
              destinations: destinations,
            )
          : null,
      floatingActionButton: floatingActionButton,
    );
  }
}
