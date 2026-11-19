import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Asks for a whole number between [min] and [max].
///
/// Returns the number, or null if the user cancels. Out-of-range input is
/// shown under the field and can't be saved.
Future<int?> showNumberSettingDialog(
  BuildContext context, {
  required String title,
  required String unit,
  required int initialValue,
  required int min,
  required int max,
}) => showDialog<int>(
  context: context,
  builder: (_) => _NumberSettingDialog(
    title: title,
    unit: unit,
    initialValue: initialValue,
    min: min,
    max: max,
  ),
);

class _NumberSettingDialog extends StatefulWidget {
  const _NumberSettingDialog({
    required this.title,
    required this.unit,
    required this.initialValue,
    required this.min,
    required this.max,
  });

  final String title;
  final String unit;
  final int initialValue;
  final int min;
  final int max;

  @override
  State<_NumberSettingDialog> createState() => _NumberSettingDialogState();
}

class _NumberSettingDialogState extends State<_NumberSettingDialog> {
  late final _controller = TextEditingController(
    text: '${widget.initialValue}',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final value = int.tryParse(_controller.text);
    if (value == null || value < widget.min || value > widget.max) {
      setState(
        () => _error = 'Enter a number from ${widget.min} to ${widget.max}.',
      );
      return;
    }
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(suffixText: widget.unit, errorText: _error),
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
