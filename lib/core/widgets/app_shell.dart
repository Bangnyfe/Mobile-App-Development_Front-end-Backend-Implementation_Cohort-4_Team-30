import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/pos/presentation/cubit/cart_cubit.dart';
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
        // Units in the cart, from the app-wide CartCubit (see app.dart).
        // select rebuilds only when the count changes.
        cartCount: context.select((CartCubit cubit) => cubit.state.itemCount),
        // Tapping the tab you are already on returns it to its first screen.
        onTabSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
