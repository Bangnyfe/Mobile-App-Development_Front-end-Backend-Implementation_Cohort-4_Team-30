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
        // The POS slice replaces this with the CartCubit's item count, e.g.
        // context.select((CartCubit cubit) => cubit.state.itemCount).
        // CartCubit must then be provided in app.dart, above the router,
        // so the badge and the Sell screens share the same cart.
        cartCount: 0,
        // Tapping the tab you are already on returns it to its first screen.
        onTabSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
