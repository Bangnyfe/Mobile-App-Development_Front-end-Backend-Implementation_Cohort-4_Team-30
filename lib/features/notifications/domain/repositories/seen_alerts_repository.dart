/// Remembers which alerts the user has already seen, so the bell only
/// counts new ones. Saved on the device, so each phone keeps its own.
abstract interface class SeenAlertsRepository {
  Future<Set<String>> loadSeenIds();

  /// Replaces the saved IDs. Saving only the current alerts' IDs keeps the
  /// list from growing with alerts that no longer exist.
  Future<void> saveSeenIds(Set<String> ids);
}
