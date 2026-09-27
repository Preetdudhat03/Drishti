import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 650 &&
      MediaQuery.sizeOf(context).width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  /// Top clearance for content so it sits cleanly below the floating glassmorphic top bar,
  /// while allowing smooth scrolling underneath it.
  static double topBarClearance(BuildContext context) {
    final statusBar = MediaQuery.paddingOf(context).top;
    return statusBar + 86.0;
  }

  /// Bottom clearance for content so it is not obscured by the floating bottom navigation bar.
  static double bottomBarClearance(BuildContext context) {
    final isDesktopOrTablet = isDesktop(context) || isTablet(context);
    if (isDesktopOrTablet) return 36.0;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return bottomInset + 88.0;
  }

  /// Standard responsive page padding for full-screen scrollable views inside ResponsiveScaffold.
  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
      16.0,
      topBarClearance(context),
      16.0,
      bottomBarClearance(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100 && desktop != null) {
      return desktop!;
    } else if (width >= 650 && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}
