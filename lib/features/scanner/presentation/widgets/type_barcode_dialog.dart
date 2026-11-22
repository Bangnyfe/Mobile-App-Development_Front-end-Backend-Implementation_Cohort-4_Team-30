import 'package:flutter/material.dart';

import '../../domain/entities/scanned_code.dart';
import '../../domain/gs1_parser.dart';

/// Lets the user type the number under the barcode when it won't scan.
/// Closes with the [ScannedCode], or null if cancelled.
class TypeBarcodeDialog extends StatefulWidget {
  const TypeBarcodeDialog({super.key});

  static Future<ScannedCode?> show(BuildContext context) =>
      showDialog<ScannedCode>(
        context: context,
        builder: (_) => const TypeBarcodeDialog(),
      );

  static const invalidMessage =
      "That number isn't a valid barcode. Check the digits and try again.";

  @override
  State<TypeBarcodeDialog> createState() => _TypeBarcodeDialogState();
}

class _TypeBarcodeDialogState extends State<TypeBarcodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(Gs1Parser.parse(_controller.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Type the barcode'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Barcode number',
            hintText: 'e.g. 6001007012342',
            helperText: 'The digits printed under the barcode',
          ),
          validator: (value) => Gs1Parser.parse(value ?? '') == null
              ? TypeBarcodeDialog.invalidMessage
              : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Use barcode')),
      ],
    );
  }
}
