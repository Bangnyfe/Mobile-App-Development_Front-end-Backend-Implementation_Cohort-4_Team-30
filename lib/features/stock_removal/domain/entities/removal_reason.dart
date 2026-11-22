/// Why stock left the shelf without being sold.
///
/// Stored in Firestore as the enum name, for example `returnedToSupplier`.
enum RemovalReason {
  expired('Expired'),
  damaged('Damaged'),
  lostOrMissing('Lost or missing'),
  returnedToSupplier('Returned to supplier'),
  recalled('Recalled'),
  other('Other');

  const RemovalReason(this.label);

  /// Text shown on the reason list and in the reports.
  final String label;

  /// "Other" says nothing on its own, so it needs a note.
  bool get requiresNote => this == RemovalReason.other;

  /// Reads the stored name; anything unknown is treated as [other].
  static RemovalReason fromName(String? name) => RemovalReason.values
      .firstWhere((reason) => reason.name == name, orElse: () => other);
}
