import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/product.dart';
import '../../domain/product_form_rules.dart';

/// What the owner typed in [showEditPricingDialog]. A null [reorderLevel]
/// means "use the pharmacy default".
typedef PricingEdit = ({int sellingPrice, int? reorderLevel});

/// Asks for a new selling price and reorder level. Returns null if the
/// owner cancels.
Future<PricingEdit?> showEditPricingDialog(
  BuildContext context, {
  required Product product,
  required int defaultReorderLevel,
}) => showDialog<PricingEdit>(
  context: context,
  builder: (_) => _EditPricingDialog(
    product: product,
    defaultReorderLevel: defaultReorderLevel,
  ),
);

class _EditPricingDialog extends StatefulWidget {
  const _EditPricingDialog({
    required this.product,
    required this.defaultReorderLevel,
  });

  final Product product;
  final int defaultReorderLevel;

  @override
  State<_EditPricingDialog> createState() => _EditPricingDialogState();
}

class _EditPricingDialogState extends State<_EditPricingDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _price = TextEditingController(
    text: '${widget.product.sellingPrice}',
  );
  late final _reorderLevel = TextEditingController(
    text: widget.product.reorderLevel?.toString() ?? '',
  );

  @override
  void dispose() {
    _price.dispose();
    _reorderLevel.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop<PricingEdit>((
      sellingPrice: int.parse(_price.text.trim()),
      reorderLevel: ProductFormRules.parseReorderLevel(_reorderLevel.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit price and reorder level'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('sellingPriceField'),
                controller: _price,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Selling price (RWF)',
                ),
                validator: ProductFormRules.sellingPrice,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('reorderLevelField'),
                controller: _reorderLevel,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Reorder level (units)',
                  helperText:
                      'Leave empty to use the default '
                      '(${widget.defaultReorderLevel})',
                ),
                validator: ProductFormRules.reorderLevel,
                onFieldSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
