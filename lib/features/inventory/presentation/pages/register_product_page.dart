import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/pinned_bottom_bar.dart';
import '../../../scanner/presentation/pages/scanner_page.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/product.dart';
import '../../domain/product_form_rules.dart';
import '../../domain/stock_form_rules.dart';
import '../cubit/register_product_cubit.dart';

/// Registers a product the pharmacy hasn't stocked before.
///
/// Closes with the new [Product], so Add stock can carry on with it.
class RegisterProductPage extends StatefulWidget {
  const RegisterProductPage({super.key, this.initialBarcode = ''});

  /// The barcode Add stock scanned, if any.
  final String initialBarcode;

  /// Choices for the Form field; anything else can go in the name.
  static const forms = [
    'Tablets',
    'Capsules',
    'Syrup',
    'Suspension',
    'Injection',
    'Cream',
    'Drops',
    'Inhaler',
    'Other',
  ];

  @override
  State<RegisterProductPage> createState() => _RegisterProductPageState();
}

/// The dropdown value that opens "New category".
const _newCategory = '__new__';

class _RegisterProductPageState extends State<RegisterProductPage> {
  final _formKey = GlobalKey<FormState>();
  late final _barcode = TextEditingController(text: widget.initialBarcode);
  final _name = TextEditingController();
  final _packSize = TextEditingController();
  final _price = TextEditingController();
  final _reorderLevel = TextEditingController();
  String _form = RegisterProductPage.forms.first;
  String? _categoryId;

  @override
  void dispose() {
    _barcode.dispose();
    _name.dispose();
    _packSize.dispose();
    _price.dispose();
    _reorderLevel.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await ScannerPage.open(context, title: 'Scan the barcode');
    if (code != null) setState(() => _barcode.text = code.gtin);
  }

  Future<void> _chooseCategory(String? value) async {
    if (value != _newCategory) return setState(() => _categoryId = value);
    final cubit = context.read<RegisterProductCubit>();
    final name = await _askCategoryName(context);
    if (name == null) return;
    final category = await cubit.addCategory(name);
    if (category != null && mounted) {
      setState(() => _categoryId = category.id);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<RegisterProductCubit>().save(
      Product(
        id: '',
        barcode: StockFormRules.normalizedBarcode(_barcode.text)!,
        name: _name.text.trim(),
        form: _form,
        packSize: _packSize.text.trim(),
        categoryId: _categoryId,
        sellingPrice: int.parse(_price.text.trim()),
        reorderLevel: ProductFormRules.parseReorderLevel(_reorderLevel.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultReorderLevel = context.select(
      (SettingsCubit cubit) => cubit.state.settings.lowStockThreshold,
    );

    return BlocConsumer<RegisterProductCubit, RegisterProductState>(
      listenWhen: (previous, current) =>
          current.saved != null && previous.saved == null,
      listener: (context, state) => context.pop(state.saved),
      builder: (context, state) {
        final categoryIds = {for (final c in state.categories) c.id};
        return Scaffold(
          appBar: AppBar(title: const Text('Register product')),
          body: SafeArea(
            child: Form(
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
                            TextFormField(
                              key: const Key('barcodeField'),
                              controller: _barcode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Barcode',
                                suffixIcon: IconButton(
                                  tooltip: 'Scan barcode',
                                  icon: const Icon(Icons.qr_code_scanner),
                                  onPressed: _scanBarcode,
                                ),
                              ),
                              validator: StockFormRules.barcode,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('nameField'),
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Name and strength',
                                hintText: 'e.g. Amoxicillin 500mg',
                              ),
                              validator: ProductFormRules.name,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _form,
                              decoration: const InputDecoration(
                                labelText: 'Form',
                              ),
                              items: [
                                for (final form in RegisterProductPage.forms)
                                  DropdownMenuItem(
                                    value: form,
                                    child: Text(form),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _form = value ?? _form),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('packSizeField'),
                              controller: _packSize,
                              decoration: const InputDecoration(
                                labelText: 'Pack size (optional)',
                                hintText: 'e.g. Strip of 10',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              key: ValueKey(
                                'category-${state.categories.length}',
                              ),
                              initialValue: categoryIds.contains(_categoryId)
                                  ? _categoryId
                                  : null,
                              decoration: const InputDecoration(
                                labelText: 'Category (optional)',
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  child: Text('No category'),
                                ),
                                for (final category in state.categories)
                                  DropdownMenuItem(
                                    value: category.id,
                                    child: Text(category.name),
                                  ),
                                const DropdownMenuItem(
                                  value: _newCategory,
                                  child: Text('+ New category'),
                                ),
                              ],
                              onChanged: _chooseCategory,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('priceField'),
                              controller: _price,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Selling price per unit (RWF)',
                              ),
                              validator: ProductFormRules.sellingPrice,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('reorderField'),
                              controller: _reorderLevel,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Reorder level (optional)',
                                helperText:
                                    'Leave empty to use the default '
                                    '($defaultReorderLevel units)',
                              ),
                              validator: ProductFormRules.reorderLevel,
                            ),
                            if (state.errorMessage != null) ...[
                              const SizedBox(height: 12),
                              Text(
                                state.errorMessage!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.danger),
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
                        onPressed: state.saving ? null : _save,
                        child: Text(
                          state.saving ? 'Saving…' : 'Register product',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<String?> _askCategoryName(BuildContext context) => showDialog<String>(
  context: context,
  builder: (_) => const _NewCategoryDialog(),
);

class _NewCategoryDialog extends StatefulWidget {
  const _NewCategoryDialog();

  @override
  State<_NewCategoryDialog> createState() => _NewCategoryDialogState();
}

class _NewCategoryDialogState extends State<_NewCategoryDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final name = _controller.text.trim();
    Navigator.of(context).pop(name.isEmpty ? null : name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: TextField(
        key: const Key('newCategoryField'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'e.g. Antibiotics'),
        onSubmitted: (_) => _add(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _add, child: const Text('Add')),
      ],
    );
  }
}
