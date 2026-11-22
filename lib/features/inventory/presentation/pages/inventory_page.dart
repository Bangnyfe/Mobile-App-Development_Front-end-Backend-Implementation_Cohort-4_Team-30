import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/inventory_item.dart';
import '../../domain/entities/product.dart';
import '../../domain/inventory_filter.dart';
import '../cubit/inventory_cubit.dart';
import '../widgets/inventory_status_chip.dart';

/// The Stock tab: every product with its units in stock, a search box and
/// filter chips for Low stock, Expiring soon and Expired.
///
/// Low stock and expiring soon follow the alert settings (Settings ›
/// Alerts), so they always agree with the dashboard and notifications.
class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key, this.clock = DateTime.now});

  /// Injected so tests get fixed expiry chips.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final settings = context.select(
      (SettingsCubit cubit) => cubit.state.settings,
    );
    final rules = InventoryRules(
      today: clock(),
      alertDays: settings.expiryAlertDays,
      defaultReorderLevel: settings.lowStockThreshold,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            tooltip: 'Register product',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _registerProduct(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.addStock),
        icon: const Icon(Icons.add),
        label: const Text('Add stock'),
      ),
      body: SafeArea(
        child: BlocBuilder<InventoryCubit, InventoryState>(
          builder: (context, state) => switch (state.status) {
            InventoryStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            InventoryStatus.failure => _ErrorView(
              message: state.errorMessage ?? '',
            ),
            InventoryStatus.loaded when state.items.isEmpty =>
              const _NoProductsView(),
            InventoryStatus.loaded => _InventoryList(
              state: state,
              rules: rules,
            ),
          },
        ),
      ),
    );
  }
}

Future<void> _registerProduct(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final product = await context.push<Product>(RoutePaths.registerProduct);
  if (product == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text('${product.name} registered. Use Add stock to receive it.'),
    ),
  );
}

class _InventoryList extends StatelessWidget {
  const _InventoryList({required this.state, required this.rules});

  final InventoryState state;
  final InventoryRules rules;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InventoryCubit>();
    final counts = rules.counts(state.items);
    final visible = rules.apply(
      state.items,
      filter: state.filter,
      query: state.query,
    );

    // Centred and width-capped like the other screens, so rows stay
    // readable in landscape.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  key: const Key('inventorySearch'),
                  onChanged: cubit.search,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Search by name or barcode',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    for (final filter in InventoryFilter.values) ...[
                      ChoiceChip(
                        label: Text('${filter.label} (${counts[filter]})'),
                        selected: state.filter == filter,
                        onSelected: (_) => cubit.selectFilter(filter),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
            if (visible.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _NothingMatchesView(),
              )
            else
              SliverPadding(
                // Bottom space so the Add stock button never hides a row.
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                sliver: SliverToBoxAdapter(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final (index, item) in visible.indexed) ...[
                          if (index > 0) const Divider(indent: 62),
                          _InventoryRow(item: item, rules: rules),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({required this.item, required this.rules});

  final InventoryItem item;
  final InventoryRules rules;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final product = item.product;
    final units = item.sellableUnitsOn(rules.today);
    final details = [
      if (product.form.isNotEmpty) product.form,
      if (product.packSize.isNotEmpty) product.packSize,
      Formatters.rwf(product.sellingPrice),
    ].join(' · ');

    return InkWell(
      // push, not go, so back returns to the list.
      onTap: () => context.push(RoutePaths.stockProduct(product.id)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.unitCount(units),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InventoryStatusChip(item: item, rules: rules),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoProductsView extends StatelessWidget {
  const _NoProductsView();

  @override
  Widget build(BuildContext context) => const _MessageView(
    icon: Icons.inventory_2_outlined,
    title: 'No products yet',
    message: 'Products show here once they are registered.',
  );
}

class _NothingMatchesView extends StatelessWidget {
  const _NothingMatchesView();

  @override
  Widget build(BuildContext context) => const _MessageView(
    icon: Icons.search_off,
    title: 'Nothing matches',
    message: 'Try another filter or search.',
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => _MessageView(
    icon: Icons.cloud_off_outlined,
    title: "Couldn't load the inventory",
    message: message,
    action: FilledButton(
      onPressed: () => context.read<InventoryCubit>().start(),
      child: const Text('Try again'),
    ),
  );
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
