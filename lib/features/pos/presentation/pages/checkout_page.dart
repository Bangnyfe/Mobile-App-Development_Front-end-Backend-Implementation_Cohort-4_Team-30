import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_radio_card.dart';
import '../../../../core/widgets/pinned_bottom_bar.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../settings/presentation/cubit/account_cubit.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/sale_receipt.dart';
import '../../domain/services/sale_ids.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../cubit/payment_form_cubit.dart';

/// Choose how the customer pays, take the cash and confirm the sale.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, this.signedInUser, this.clock = DateTime.now});

  /// The signed-in user, whose pharmacy and uid the sale is saved under.
  /// Null without auth (widget tests); the account from Settings is used.
  final AppUser? signedInUser;

  /// For tests; the app uses the real time.
  final DateTime Function() clock;

  static const noPharmacyMessage =
      "Your account isn't linked to a pharmacy yet, so the sale can't be "
      'saved.';

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _cash = TextEditingController();

  @override
  void dispose() {
    _cash.dispose();
    super.dispose();
  }

  /// Who is selling, and for which pharmacy: the signed-in user first, then
  /// the account loaded for Settings. Null if there's no pharmacy.
  _Seller? _seller(BuildContext context) {
    final account = switch (context.read<AccountCubit>().state) {
      AccountLoaded(:final account) => account,
      _ => null,
    };
    final user = widget.signedInUser;
    final pharmacyId = user?.pharmacyId ?? account?.pharmacy.id;
    final soldBy = user?.uid ?? account?.user.id;
    if (pharmacyId == null || soldBy == null) return null;
    return _Seller(
      pharmacyId: pharmacyId,
      soldBy: soldBy,
      name: user?.name ?? account?.user.name ?? '',
      pharmacyName: account?.pharmacy.name ?? '',
      pharmacyLocation: account?.pharmacy.location ?? '',
    );
  }

  void _confirm(BuildContext context) {
    final seller = _seller(context);
    if (seller == null) {
      _showMessage(context, CheckoutPage.noPharmacyMessage);
      return;
    }
    final form = context.read<PaymentFormCubit>().state;
    final now = widget.clock();
    context.read<CheckoutCubit>().checkout(
      items: context.read<CartCubit>().state.items,
      pharmacyId: seller.pharmacyId,
      saleId: SaleIds.saleId(now),
      receiptNo: SaleIds.receiptNo(now),
      soldBy: seller.soldBy,
      paymentMethod: form.method,
      cashReceived: form.cashReceived,
    );
  }

  void _onCheckout(BuildContext context, CheckoutState state) {
    switch (state.status) {
      case CheckoutStatus.failure:
        _showMessage(context, state.error ?? 'Checkout failed.');
      case CheckoutStatus.success:
        final cart = context.read<CartCubit>();
        final form = context.read<PaymentFormCubit>().state;
        final seller = _seller(context);
        final receipt = SaleReceipt.fromCart(
          receiptNo: state.receiptNo ?? '',
          createdAt: widget.clock(),
          pharmacyName: seller?.pharmacyName ?? '',
          pharmacyLocation: seller?.pharmacyLocation ?? '',
          servedBy: seller?.name ?? '',
          paymentMethod: form.method,
          items: cart.state.items,
          cashReceived: form.cashReceived,
        );
        context.go(RoutePaths.sellReceipt, extra: receipt);
        // The sale is saved: start the next one with an empty cart.
        cart.clear();
      case CheckoutStatus.initial || CheckoutStatus.processing:
        break;
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final checkout = context.watch<CheckoutCubit>().state;
    final form = context.watch<PaymentFormCubit>().state;
    final formCubit = context.read<PaymentFormCubit>();
    // The app-wide AccountCubit is created lazily: watching it here starts
    // loading the pharmacy (name, location, seller) as Checkout opens, so
    // it's ready by the time the sale is confirmed.
    context.watch<AccountCubit>();

    return BlocListener<CheckoutCubit, CheckoutState>(
      listener: _onCheckout,
      // Once the sale is saved the cart is cleared; keep showing what was
      // sold while the receipt opens.
      child: BlocBuilder<CartCubit, CartState>(
        buildWhen: (_, _) =>
            context.read<CheckoutCubit>().state.status !=
            CheckoutStatus.success,
        builder: (context, cart) {
          final total = cart.total;
          final change = form.changeFor(total);
          final processing = checkout.status == CheckoutStatus.processing;
          final canConfirm =
              cart.items.isNotEmpty && form.covers(total) && !processing;

          return Scaffold(
            appBar: AppBar(title: const Text('Checkout')),
            body: Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        children: [
                          _AmountDue(cart: cart),
                          const SizedBox(height: 16),
                          Text(
                            'PAYMENT METHOD',
                            style: textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final method in PaymentMethods.all) ...[
                            AppRadioCard(
                              key: ValueKey('payment-$method'),
                              radioFirst: false,
                              selected: form.method == method,
                              onTap: processing
                                  ? null
                                  : () => formCubit.selectMethod(method),
                              leading: _MethodIcon(method: method),
                              child: Text(
                                method,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (form.isCash) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Cash received (RWF)',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              key: const ValueKey('cash-received'),
                              controller: _cash,
                              enabled: !processing,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: formCubit.setCashReceived,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(hintText: '0'),
                            ),
                            const SizedBox(height: 12),
                            _ChangeRow(
                              total: total,
                              cashReceived: form.cashReceived,
                              change: change,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                PinnedBottomBar(
                  children: [
                    FilledButton(
                      onPressed: canConfirm ? () => _confirm(context) : null,
                      child: processing
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                semanticsLabel: 'Saving the sale',
                              ),
                            )
                          : const Text('Confirm sale'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Seller {
  const _Seller({
    required this.pharmacyId,
    required this.soldBy,
    required this.name,
    required this.pharmacyName,
    required this.pharmacyLocation,
  });

  final String pharmacyId;
  final String soldBy;
  final String name;
  final String pharmacyName;
  final String pharmacyLocation;
}

/// The teal "Amount due" banner.
class _AmountDue extends StatelessWidget {
  const _AmountDue({required this.cart});

  final CartState cart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final products = cart.items.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Amount due',
            style: textTheme.bodySmall?.copyWith(color: colors.onPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.rwf(cart.total),
            key: const ValueKey('amount-due'),
            style: textTheme.headlineMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${products == 1 ? '1 product' : '$products products'} · '
            '${Formatters.unitCount(cart.itemCount)}',
            style: textTheme.bodySmall?.copyWith(color: colors.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _MethodIcon extends StatelessWidget {
  const _MethodIcon({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        switch (method) {
          PaymentMethods.mobileMoney => Icons.phone_android,
          PaymentMethods.card => Icons.credit_card,
          _ => Icons.payments_outlined,
        },
        size: 18,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}

/// "Change to give back  RWF 3,100", or how much cash is still missing.
class _ChangeRow extends StatelessWidget {
  const _ChangeRow({
    required this.total,
    required this.cashReceived,
    required this.change,
  });

  final int total;
  final int? cashReceived;
  final int? change;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final cash = cashReceived;
    final short = cash != null && change == null ? total - cash : null;

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              short == null ? 'Change to give back' : 'Not enough cash',
              style: textTheme.bodySmall?.copyWith(
                color: short == null ? colors.onSurfaceVariant : colors.error,
              ),
            ),
          ),
          Text(
            switch ((change, short)) {
              (final int change, _) => Formatters.rwf(change),
              (_, final int short) => '${Formatters.rwf(short)} short',
              _ => '—',
            },
            key: const ValueKey('change-amount'),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: short == null ? colors.primary : colors.error,
            ),
          ),
        ],
      ),
    );
  }
}
