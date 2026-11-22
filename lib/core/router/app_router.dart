import 'package:flutter/widgets.dart';
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
import '../../features/invites/presentation/cubit/pharmacy_invites_cubit.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/pos/data/fake_checkout_repository.dart';
import '../../features/pos/domain/entities/sale_receipt.dart';
import '../../features/pos/domain/repositories/checkout_repository.dart';
import '../../features/pos/domain/repositories/product_catalog.dart';
import '../../features/pos/presentation/cubit/batch_pick_cubit.dart';
import '../../features/pos/presentation/cubit/cart_cubit.dart';
import '../../features/pos/presentation/cubit/checkout_cubit.dart';
import '../../features/pos/presentation/cubit/payment_form_cubit.dart';
import '../../features/pos/presentation/cubit/product_search_cubit.dart';
import '../../features/pos/presentation/pages/cart_page.dart';
import '../../features/pos/presentation/pages/checkout_page.dart';
import '../../features/pos/presentation/pages/product_found_page.dart';
import '../../features/pos/presentation/pages/receipt_page.dart';
import '../../features/pos/presentation/pages/sell_page.dart';
import '../../features/reports/presentation/cubit/stock_reports_cubit.dart';
import '../../features/reports/presentation/pages/expiry_waste_report_page.dart';
import '../../features/reports/presentation/pages/inventory_report_page.dart';
import '../../features/reports/presentation/pages/reports_hub_page.dart';
import '../../features/sales/domain/repositories/sales_repository.dart';
import '../../features/sales/presentation/cubit/sale_details_cubit.dart';
import '../../features/sales/presentation/cubit/sales_history_cubit.dart';
import '../../features/sales/presentation/pages/sale_details_page.dart';
import '../../features/sales/presentation/pages/sales_history_page.dart';
import '../../features/scanner/domain/entities/found_product.dart';
import '../../features/scanner/domain/repositories/product_lookup_repository.dart';
import '../../features/scanner/presentation/cubit/scan_cubit.dart';
import '../../features/settings/presentation/pages/categories_page.dart';
import '../../features/settings/presentation/pages/pharmacy_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/staff_page.dart';
import '../../features/stock_removal/domain/entities/removal_reason.dart';
import '../../features/stock_removal/domain/repositories/stock_removal_repository.dart';
import '../../features/stock_removal/presentation/cubit/remove_stock_cubit.dart';
import '../../features/stock_removal/presentation/pages/remove_stock_page.dart';
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
///
/// [checkoutRepository] saves confirmed sales: `main.dart` passes
/// `FirestoreCheckoutRepository`, and tests get [FakeCheckoutRepository]
/// by default (see [_sellRoute]).
GoRouter createAppRouter({
  AuthBloc? authBloc,
  CheckoutRepository? checkoutRepository,
}) {
  // Screens that open above the tabs (no bottom bar) use this navigator.
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
      _removeStockRoute,
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
          StatefulShellBranch(
            routes: [
              _sellRoute(
                rootNavigatorKey: rootNavigatorKey,
                checkoutRepository:
                    checkoutRepository ?? FakeCheckoutRepository(),
                authBloc: authBloc,
              ),
            ],
          ),
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
                  // Each report loads the stock and removals when opened,
                  // so a removal made meanwhile always shows.
                  GoRoute(
                    path: 'inventory',
                    builder: (context, state) => BlocProvider(
                      create: (context) => StockReportsCubit(
                        context.read<StockRemovalRepository>(),
                      )..load(),
                      child: const InventoryReportPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'expiry-waste',
                    builder: (context, state) => BlocProvider(
                      create: (context) => StockReportsCubit(
                        context.read<StockRemovalRepository>(),
                      )..load(),
                      child: const ExpiryWasteReportPage(),
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
                    builder: (context, state) {
                      // Inviting needs a signed-in owner and their pharmacy,
                      // so it only shows with auth (not in most tests).
                      final user = authBloc?.state.user;
                      final pharmacyId = user?.pharmacyId;
                      if (user == null || !user.isOwner || pharmacyId == null) {
                        return const StaffPage();
                      }
                      return BlocProvider(
                        create: (context) => PharmacyInvitesCubit(
                          inviteRepository: context.read<InviteRepository>(),
                          pharmacyId: pharmacyId,
                          ownerUid: user.uid,
                          ownerName: user.name,
                        )..start(),
                        child: const StaffPage(canInvite: true),
                      );
                    },
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

/// The Sell tab and its flow: Sell → Product found → Cart → Checkout →
/// Receipt. The sub-screens open on the root navigator, above the tabs, so
/// the bottom bar is hidden on them as in the Figma flow, while their paths
/// stay under /sell and back returns to Sell.
///
/// The cart is the app-wide CartCubit from `app.dart`.
GoRoute _sellRoute({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required CheckoutRepository checkoutRepository,
  AuthBloc? authBloc,
}) {
  return GoRoute(
    path: RoutePaths.sell,
    // The app looks barcodes up, and searches names, in the signed-in
    // pharmacy's Firestore products (see main.dart); tests use the sample
    // products. Checkout must use the same source, since it takes stock
    // from those batches.
    builder: (context, state) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ScanCubit(context.read<ProductLookupRepository>()),
        ),
        BlocProvider(
          create: (context) =>
              ProductSearchCubit(context.read<ProductCatalog>()),
        ),
      ],
      child: const SellPage(),
    ),
    routes: [
      GoRoute(
        path: 'product',
        parentNavigatorKey: rootNavigatorKey,
        // Needs the scanned product; without it (e.g. a restored link)
        // there's nothing to show, so start again from Sell.
        redirect: (context, state) =>
            state.extra is FoundProduct ? null : RoutePaths.sell,
        builder: (context, state) {
          final found = state.extra! as FoundProduct;
          return BlocProvider(
            create: (context) => BatchPickCubit(
              batches: found.batches,
              today: DateTime.now(),
              cart: context.read<CartCubit>().state.items,
            ),
            child: ProductFoundPage(found: found),
          );
        },
      ),
      GoRoute(
        path: 'cart',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CartPage(),
      ),
      GoRoute(
        path: 'checkout',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => CheckoutCubit(checkoutRepository)),
            BlocProvider(create: (_) => PaymentFormCubit()),
          ],
          child: CheckoutPage(signedInUser: authBloc?.state.user),
        ),
      ),
      GoRoute(
        path: 'receipt',
        parentNavigatorKey: rootNavigatorKey,
        redirect: (context, state) =>
            state.extra is SaleReceipt ? null : RoutePaths.sell,
        builder: (context, state) =>
            ReceiptPage(receipt: state.extra! as SaleReceipt),
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

/// Remove stock opens above the tabs, like the Figma flow (no bottom bar).
/// From an expiry notification the query carries the batch and reason.
final _removeStockRoute = GoRoute(
  path: RoutePaths.removeStock,
  builder: (context, state) {
    final query = state.uri.queryParameters;
    final reason = query['reason'];
    return BlocProvider(
      create: (context) =>
          RemoveStockCubit(context.read<StockRemovalRepository>())..start(
            productId: query['productId'],
            batchId: query['batchId'],
            suggestedReason: reason == null
                ? null
                : RemovalReason.fromName(reason),
          ),
      child: const RemoveStockPage(),
    );
  },
);

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
