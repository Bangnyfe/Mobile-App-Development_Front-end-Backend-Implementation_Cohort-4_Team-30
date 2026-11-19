import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
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
class PharmacyApp extends StatelessWidget {
  const PharmacyApp({
    super.key,
    required this.router,
    required this.settingsRepository,
    this.dashboardRepository,
    this.accountRepository,
    this.salesRepository,
  });

  final GoRouter router;

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
    return MultiRepositoryProvider(
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
        child: MaterialApp.router(
          title: 'Pharmacy Inventory & POS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }
}
