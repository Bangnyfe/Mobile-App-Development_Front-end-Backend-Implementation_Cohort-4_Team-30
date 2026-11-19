import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/sales/domain/repositories/sales_repository.dart';
import '../../features/sales/presentation/cubit/sale_details_cubit.dart';
import '../../features/sales/presentation/cubit/sales_history_cubit.dart';
import '../../features/sales/presentation/pages/sale_details_page.dart';
import '../../features/sales/presentation/pages/sales_history_page.dart';
import '../../features/settings/presentation/pages/categories_page.dart';
import '../../features/settings/presentation/pages/pharmacy_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/staff_page.dart';
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                builder: (context, state) => BlocProvider(
                  create: (context) =>
                      DashboardCubit(context.read<DashboardRepository>())
                        ..start(),
                  child: const DashboardPage(),
                ),
                // Inside the Home tab, so the bottom bar stays visible and
                // back returns to the dashboard.
                routes: [
                  GoRoute(
                    path: 'sales',
                    builder: (context, state) => BlocProvider(
                      create: (context) =>
                          SalesHistoryCubit(context.read<SalesRepository>())
                            ..start(),
                      child: const SalesHistoryPage(),
                    ),
                    routes: [
                      GoRoute(
                        path: ':saleId',
                        builder: (context, state) => BlocProvider(
                          create: (context) => SaleDetailsCubit(
                            context.read<SalesRepository>(),
                            state.pathParameters['saleId']!,
                          )..load(),
                          child: const SaleDetailsPage(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          _tab(RoutePaths.sell, 'Sell'),
          _tab(RoutePaths.stock, 'Inventory'),
          _tab(RoutePaths.reports, 'Reports'),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                builder: (context, state) => const SettingsPage(),
                // Sub-routes stay inside the Settings tab, so the bottom
                // bar stays visible and back returns to Settings.
                routes: [
                  GoRoute(
                    path: 'pharmacy',
                    builder: (context, state) => const PharmacyProfilePage(),
                  ),
                  GoRoute(
                    path: 'staff',
                    builder: (context, state) => const StaffPage(),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (context, state) => const CategoriesPage(),
                  ),
                ],
              ),
            ],
          ),
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
