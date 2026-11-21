import 'entities/removal_reason.dart';

/// The rules a removal must pass, shared by the Cubit (to enable buttons
/// and show messages) and the repositories (as a last check).
///
/// Each returns null when the value is fine, otherwise a message for the
/// user.
abstract final class RemovalRules {
  static String? quantity(int quantity, {required int available}) {
    if (available <= 0) return 'This batch has no units left to remove.';
    if (quantity < 1) return 'Remove at least 1 unit.';
    if (quantity > available) {
      return available == 1
          ? 'Only 1 unit is left in this batch.'
          : 'Only $available units are left in this batch.';
    }
    return null;
  }

  static String? reason(RemovalReason? reason, String note) {
    if (reason == null) return 'Choose a reason to continue.';
    if (reason.requiresNote && note.trim().isEmpty) {
      return 'Add a note to explain the reason.';
    }
    return null;
  }
}
