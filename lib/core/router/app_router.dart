import 'package:go_router/go_router.dart';

import '../widgets/app_shell.dart';
import '../widgets/feature_placeholder_page.dart';
import 'route_paths.dart';

/// Creates the app's router.
///
/// The five tabs use a [StatefulShellRoute.indexedStack]: each tab keeps its
/// own navigation stack, so switching tabs never loses where the user was
/// and the system back button only pops within the current tab.
///
/// Feature owners: replace the [FeaturePlaceholderPage] in your branch with
/// your real page, and add sub-routes (e.g. product details) under it.
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          _tab(RoutePaths.home, 'Dashboard'),
          _tab(RoutePaths.sell, 'Sell'),
          _tab(RoutePaths.stock, 'Inventory'),
          _tab(RoutePaths.reports, 'Reports'),
          _tab(RoutePaths.settings, 'Settings'),
        ],
      ),
    ],
  );
}

StatefulShellBranch _tab(String path, String title) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (context, state) => FeaturePlaceholderPage(title: title),
      ),
    ],
  );
}
