import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/pinned_bottom_bar.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../../domain/entities/product.dart';
import '../../domain/stock_form_rules.dart';
import '../cubit/add_stock_cubit.dart';

/// Receives a delivery: scan the pack, enter the batch details, confirm.
///
/// A GS1 DataMatrix on the pack fills in the batch number and expiry date.
/// A barcode that isn't registered yet leads to Register product first,
/// then straight back here with the same scan.
class AddStockPage extends StatelessWidget {
  const AddStockPage({super.key, this.clock = DateTime.now});

  /// Injected so tests get a fixed "today" for the expiry checks.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add stock')),
      body: SafeArea(
        child: BlocBuilder<AddStockCubit, AddStockState>(
          builder: (context, state) => switch (state) {
            AddStockScan() => const _ScanView(),
            AddStockLookingUp() => const Center(
              child: CircularProgressIndicator(),
            ),
            AddStockNotRegistered(:final code) => _NotRegisteredView(
              barcode: code.gtin,
            ),
            AddStockDetails() => _DetailsForm(
              // A new form for each product, so fields never carry over.
              key: ValueKey(state.product.id),
              state: state,
              today: clock(),
            ),
            AddStockDone() => _DoneView(state: state),
            AddStockFailure(:final message) => _Message(
              icon: Icons.cloud_off_outlined,
              title: "Couldn't find the product",
              message: message,
              actions: [
                FilledButton(
                  onPressed: () => context.read<AddStockCubit>().scanAnother(),
                  child: const Text('Try again'),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

Future<void> _scan(BuildContext context) async {
  final cubit = context.read<AddStockCubit>();
  final code = await ScannerPage.open(context, title: 'Scan to add stock');
  if (code != null) await cubit.scanned(code);
}

class _ScanView extends StatelessWidget {
  const _ScanView();

  @override
  Widget build(BuildContext context) => _Message(
    icon: Icons.qr_code_scanner,
    title: 'Scan the pack',
    message:
        'Scan the barcode on the box. The square 2D code also fills in the '
        'batch number and expiry date. You can type the number instead.',
    actions: [
      FilledButton.icon(
        onPressed: () => _scan(context),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan barcode'),
      ),
    ],
  );
}

class _NotRegisteredView extends StatelessWidget {
  const _NotRegisteredView({required this.barcode});

  final String barcode;

  Future<void> _register(BuildContext context) async {
    final cubit = context.read<AddStockCubit>();
    final product = await context.push<Product>(
      RoutePaths.registerProduct,
      extra: barcode,
    );
    if (product != null) cubit.productRegistered(product);
  }

  @override
  Widget build(BuildContext context) => _Message(
    icon: Icons.inventory_2_outlined,
    title: 'New product',
    message:
        'No product has the barcode $barcode yet. Register it first, then '
        'add this batch.',
    actions: [
      FilledButton(
        onPressed: () => _register(context),
        child: const Text('Register new product'),
      ),
      TextButton(
        onPressed: () => _scan(context),
        child: const Text('Scan again'),
      ),
    ],
  );
}

class _DetailsForm extends StatefulWidget {
  const _DetailsForm({super.key, required this.state, required this.today});

  final AddStockDetails state;
  final DateTime today;

  @override
  State<_DetailsForm> createState() => _DetailsFormState();
}

class _DetailsFormState extends State<_DetailsForm> {
  final _formKey = GlobalKey<FormState>();
  late final _batchNumber = TextEditingController(
    text: widget.state.code?.batchNumber ?? '',
  );
  final _quantity = TextEditingController();
  final _costPrice = TextEditingController();
  late DateTime? _expiryDate = widget.state.code?.expiryDate;

  @override
  void dispose() {
    _batchNumber.dispose();
    _quantity.dispose();
    _costPrice.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry(FormFieldState<DateTime> field) async {
    final today = DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day,
    );
    final picked = await showDatePicker(
      context: context,
      helpText: 'Expiry date',
      initialDate: _expiryDate != null && !_expiryDate!.isBefore(today)
          ? _expiryDate!
          : DateTime(today.year + 1, today.month, today.day),
      firstDate: today,
      lastDate: DateTime(today.year + 20),
    );
    if (picked == null) return;
    setState(() => _expiryDate = picked);
    field.didChange(picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AddStockCubit>().save(
      batchNumber: _batchNumber.text,
      expiryDate: _expiryDate!,
      quantity: int.parse(_quantity.text.trim()),
      costPrice: int.parse(_costPrice.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final product = widget.state.product;
    final details = [
      if (product.form.isNotEmpty) product.form,
      if (product.packSize.isNotEmpty) product.packSize,
      'sells at ${Formatters.rwf(product.sellingPrice)}',
    ].join(' · ');

    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.medication_outlined),
                        title: Text(
                          product.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(details),
                      ),
                    ),
                    if (widget.state.code?.batchNumber != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Batch and expiry filled in from the scanned code. '
                          'Check them against the pack.',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('batchNumberField'),
                      controller: _batchNumber,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Batch number',
                      ),
                      validator: StockFormRules.batchNumber,
                    ),
                    const SizedBox(height: 12),
                    FormField<DateTime>(
                      initialValue: _expiryDate,
                      validator: (value) =>
                          StockFormRules.expiryDate(value, today: widget.today),
                      builder: (field) => InkWell(
                        key: const Key('expiryDateField'),
                        onTap: () => _pickExpiry(field),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Expiry date',
                            errorText: field.errorText,
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            field.value == null
                                ? 'Choose a date'
                                : Formatters.date(field.value!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('quantityField'),
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Units received',
                      ),
                      validator: StockFormRules.quantity,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('costPriceField'),
                      controller: _costPrice,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Cost per unit (RWF)',
                      ),
                      validator: StockFormRules.costPrice,
                      onFieldSubmitted: (_) => _save(),
                    ),
                    if (widget.state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.state.errorMessage!,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.danger,
                        ),
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
                onPressed: widget.state.saving ? null : _save,
                child: Text(widget.state.saving ? 'Saving…' : 'Add to stock'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.state});

  final AddStockDone state;

  @override
  Widget build(BuildContext context) {
    final batch = state.batch;
    return _Message(
      icon: Icons.check_circle_outline,
      iconColor: AppColors.success,
      title: 'Stock added',
      message:
          '${Formatters.unitCount(batch.quantity)} of ${state.product.name}, '
          'batch ${batch.batchNumber}, expiring '
          '${Formatters.date(batch.expiryDate)}.',
      actions: [
        FilledButton(
          onPressed: () => context.read<AddStockCubit>().scanAnother(),
          child: const Text('Add another'),
        ),
        TextButton(onPressed: () => context.pop(), child: const Text('Done')),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.iconColor = AppColors.textSecondary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 56, color: iconColor),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              for (final action in actions) ...[
                action,
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
