import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The five-tab bottom navigation from the prototype:
/// Home, Sell, Stock, Reports, Settings.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.cartCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  /// Number of items in the cart, shown as a badge on the Sell tab.
  /// The badge is hidden when this is 0.
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onTabSelected,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: _withCartBadge(const Icon(Icons.shopping_cart_outlined)),
            selectedIcon: _withCartBadge(const Icon(Icons.shopping_cart)),
            label: 'Sell',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          const NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _withCartBadge(Widget icon) =>
      Badge.count(count: cartCount, isLabelVisible: cartCount > 0, child: icon);
}
