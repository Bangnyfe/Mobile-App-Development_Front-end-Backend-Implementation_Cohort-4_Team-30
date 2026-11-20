import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/dashboard/data/fake_dashboard_repository.dart';
import 'features/dashboard/domain/repositories/dashboard_repository.dart';
import 'features/pos/presentation/cubit/cart_cubit.dart';
import 'features/sales/data/fake_sales_repository.dart';
import 'features/sales/domain/repositories/sales_repository.dart';
import 'features/settings/data/fake_account_repository.dart';
import 'features/settings/domain/repositories/account_repository.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/presentation/cubit/account_cubit.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

/// Root widget.
///
/// Repositories are provided here, above the router, so every screen's
/// Cubit can read them with `context.read<...>()`. Tests pass their own
/// router and repositories so they run without Firebase.
///
/// Cubits that several screens share (settings, account and the cart) are
/// provided here too, so every tab sees the same state.
///
/// [authBloc] is provided above everything when given (the real app), so
/// the auth screens can read it and per-user state is reset when the
/// signed-in user changes.
class PharmacyApp extends StatelessWidget {
  const PharmacyApp({
    super.key,
    required this.router,
    required this.settingsRepository,
    this.authBloc,
    this.dashboardRepository,
    this.accountRepository,
    this.salesRepository,
  });

  final GoRouter router;

  /// Null in widget tests that do not exercise sign-in.
  final AuthBloc? authBloc;

  final SettingsRepository settingsRepository;

  /// Defaults to the fake repository until the Firestore one is merged.
  final DashboardRepository? dashboardRepository;

  /// Defaults to the fake repository until auth and the data layer are
  /// merged.
  final AccountRepository? accountRepository;

  /// Defaults to the fake repository until auth gives us the signed-in
  /// user's pharmacy ID for `FirestoreSalesRepository`.
  final SalesRepository? salesRepository;

  @override
  Widget build(BuildContext context) {
    final bloc = authBloc;
    Widget app = MaterialApp.router(
      title: 'Pharmacy Inventory & POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
    if (bloc != null) {
      app = BlocListener<AuthBloc, AuthState>(
        bloc: bloc,
        // Another user signed in, or the user signed out: drop the previous
        // user's cart and reload the account shown in Settings, so nothing
        // from one session leaks into the next.
        listenWhen: (previous, current) =>
            previous.user?.uid != current.user?.uid,
        listener: (context, state) {
          context.read<CartCubit>().clear();
          context.read<AccountCubit>().load();
        },
        child: app,
      );
    }

    final tree = MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DashboardRepository>(
          create: (_) => dashboardRepository ?? FakeDashboardRepository(),
        ),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<AccountRepository>(
          create: (_) => accountRepository ?? const FakeAccountRepository(),
        ),
        RepositoryProvider<SalesRepository>(
          create: (_) => salesRepository ?? FakeSalesRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                SettingsCubit(context.read<SettingsRepository>())..load(),
          ),
          BlocProvider(
            create: (context) =>
                AccountCubit(context.read<AccountRepository>())..load(),
          ),
          // One cart for the whole app: the Sell tab's badge and the Sell
          // screens read the same CartCubit, so they never disagree.
          BlocProvider(create: (_) => CartCubit()),
        ],
        child: app,
      ),
    );

    return bloc == null
        ? tree
        : BlocProvider<AuthBloc>.value(value: bloc, child: tree);
  }
}
