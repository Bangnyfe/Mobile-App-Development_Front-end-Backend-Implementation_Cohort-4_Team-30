import '../domain/repositories/seen_alerts_repository.dart';

/// Keeps the seen alert IDs in memory only, so they're forgotten when the
/// app closes. The app uses this when no other repository is given (e.g.
/// in tests); `main.dart` passes `SharedPrefsSeenAlertsRepository`.
class InMemorySeenAlertsRepository implements SeenAlertsRepository {
  InMemorySeenAlertsRepository([Set<String> seenIds = const {}])
    : _seenIds = {...seenIds};

  Set<String> _seenIds;

  @override
  Future<Set<String>> loadSeenIds() async => {..._seenIds};

  @override
  Future<void> saveSeenIds(Set<String> ids) async => _seenIds = {...ids};
}
