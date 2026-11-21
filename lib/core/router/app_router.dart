import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_route_paths.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/pharmacy_setup_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/verify_email_page.dart';
import '../../features/auth/domain/repositories/pharmacy_draft_repository.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/invites/domain/repositories/invite_repository.dart';
import '../../features/invites/presentation/cubit/pharmacy_choice_cubit.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/reports/presentation/pages/reports_hub_page.dart';
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
import 'auth_redirect.dart';
import 'auth_status_listenable.dart';
import 'route_paths.dart';

/// Creates the app's router.
///
/// The five tabs use a [StatefulShellRoute.indexedStack]: each tab keeps its
/// own navigation stack, so switching tabs never loses where the user was
/// and the system back button only pops within the current tab.
///
/// Feature owners: replace the [FeaturePlaceholderPage] in your branch with
/// your real page, and add sub-routes (e.g. product details) under it.
///
/// With [authBloc] (the real app), the app starts on Splash and every
/// navigation is checked by [authRedirect], so each sign-in status always
/// lands on its own screen. Without it (most widget tests), the app opens
/// straight on Home as before.
GoRouter createAppRouter({AuthBloc? authBloc}) {
  return GoRouter(
    initialLocation: authBloc == null ? RoutePaths.home : AuthRoutePaths.splash,
    refreshListenable: authBloc == null ? null : AuthStatusListenable(authBloc),
    redirect: authBloc == null
        ? null
        : (context, state) => authRedirect(
            status: authBloc.state.status,
            location: state.uri.path,
          ),
    routes: [
      ..._authRoutes,
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
                  _salesHistoryRoute(RoutePaths.saleDetails),
                  // Reads the app-wide NotificationsCubit, which the bell
                  // shares.
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsPage(),
                  ),
                ],
              ),
            ],
          ),
          _tab(RoutePaths.sell, 'Sell'),
          _tab(RoutePaths.stock, 'Inventory'),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.reports,
                builder: (context, state) => const ReportsHubPage(),
                // Sub-routes stay inside the Reports tab, so the bottom
                // bar stays visible and back returns to the hub.
                routes: [
                  _salesHistoryRoute(RoutePaths.reportsSaleDetails),
                  // Brian: replace these placeholders with your reports.
                  GoRoute(
                    path: 'inventory',
                    builder: (context, state) =>
                        const FeaturePlaceholderPage(title: 'Inventory report'),
                  ),
                  GoRoute(
                    path: 'expiry-waste',
                    builder: (context, state) => const FeaturePlaceholderPage(
                      title: 'Expiry & waste report',
                    ),
                  ),
                ],
              ),
            ],
          ),
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

/// Sales history and Sale details as a sub-route of whichever tab opens
/// them (Home and Reports). [saleDetailsPath] keeps the details in the same
/// tab, so the selected tab never jumps.
GoRoute _salesHistoryRoute(String Function(String saleId) saleDetailsPath) {
  return GoRoute(
    path: 'sales',
    builder: (context, state) => BlocProvider(
      create: (context) =>
          SalesHistoryCubit(context.read<SalesRepository>())..start(),
      child: SalesHistoryPage(saleDetailsPath: saleDetailsPath),
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
  );
}

/// Screens outside the tabs, so the bottom bar is hidden on them.
final _authRoutes = <RouteBase>[
  GoRoute(
    path: AuthRoutePaths.splash,
    builder: (context, state) => const SplashPage(),
  ),
  GoRoute(
    path: AuthRoutePaths.login,
    builder: (context, state) => const LoginPage(),
  ),
  GoRoute(
    path: AuthRoutePaths.register,
    builder: (context, state) => const RegisterPage(),
  ),
  GoRoute(
    path: AuthRoutePaths.forgotPassword,
    builder: (context, state) => const ForgotPasswordPage(),
  ),
  GoRoute(
    path: AuthRoutePaths.verifyEmail,
    builder: (context, state) => const VerifyEmailPage(),
  ),
  GoRoute(
    path: AuthRoutePaths.pharmacySetup,
    builder: (context, state) {
      // The redirect only sends signed-in users here; the check covers the
      // moment of signing out, before the router moves to Login.
      final user = context.read<AuthBloc>().state.user;
      if (user == null) return const SplashPage();
      return BlocProvider(
        create: (context) => PharmacyChoiceCubit(
          inviteRepository: context.read<InviteRepository>(),
          draftRepository: context.read<PharmacyDraftRepository>(),
          user: user,
        )..load(),
        child: const PharmacySetupPage(),
      );
    },
  ),
];

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
