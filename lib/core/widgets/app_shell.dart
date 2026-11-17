import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_bottom_nav.dart';

/// Scaffold that wraps every tab screen and shows the bottom navigation.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        // Tapping the tab you are already on returns it to its first screen.
        onTabSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
