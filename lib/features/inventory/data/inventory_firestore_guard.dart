import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/inventory_failure.dart';

/// Turns Firestore errors into an [InventoryFailure] the screens can show.
///
/// The rules refuse pharmacists' owner-only writes with `permission-denied`.
InventoryFailure inventoryFailureFrom(Object error) => switch (error) {
  InventoryFailure failure => failure,
  FirebaseException(code: 'permission-denied') => const InventoryFailure(
    InventoryFailure.ownerOnly,
  ),
  FirebaseException(code: 'not-found') => const InventoryFailure(
    InventoryFailure.notFound,
  ),
  _ => const InventoryFailure(InventoryFailure.generic),
};

/// Runs [action], rethrowing Firestore errors as [InventoryFailure].
Future<T> guardInventory<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on InventoryFailure {
    rethrow;
  } on FirebaseException catch (e) {
    throw inventoryFailureFrom(e);
  }
}

extension InventoryFailureStream<T> on Stream<T> {
  /// Errors on the stream arrive as [InventoryFailure].
  Stream<T> withInventoryFailures() => handleError((Object error) {
    throw inventoryFailureFrom(error);
  });
}
