import 'package:flutter/material.dart';

/// A tappable card with a radio mark, for picking one option from a list:
/// the batch on Product found and the payment method on Checkout.
///
/// The selected card gets a thicker teal border. The whole card is the tap
/// target, at least 56dp tall.
class AppRadioCard extends StatelessWidget {
  const AppRadioCard({
    super.key,
    required this.selected,
    required this.onTap,
    required this.child,
    this.leading,
    this.radioFirst = true,
  });

  final bool selected;

  /// Null disables the card.
  final VoidCallback? onTap;

  final Widget child;

  /// Shown before [child], e.g. a payment method's icon.
  final Widget? leading;

  /// Radio mark at the start of the card (batches) or at the end (payment
  /// methods), as in the design.
  final bool radioFirst;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(12);
    final radio = Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      color: selected ? colors.primary : colors.onSurfaceVariant,
    );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? colors.primary : colors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (radioFirst) ...[radio, const SizedBox(width: 12)],
                  if (leading != null) ...[leading!, const SizedBox(width: 12)],
                  Expanded(child: child),
                  if (!radioFirst) ...[const SizedBox(width: 12), radio],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
