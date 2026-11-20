import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/features/notifications/data/shared_prefs_seen_alerts_repository.dart';

Future<SharedPrefsSeenAlertsRepository> repositoryWith(
  Map<String, Object> values,
) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPrefsSeenAlertsRepository(await SharedPreferences.getInstance());
}

void main() {
  test('nothing has been seen on a new install', () async {
    final repository = await repositoryWith({});

    expect(await repository.loadSeenIds(), isEmpty);
  });

  test('saved IDs load back', () async {
    final repository = await repositoryWith({});

    await repository.saveSeenIds({'low:p1', 'expired:b1'});

    expect(await repository.loadSeenIds(), {'low:p1', 'expired:b1'});
  });

  test('saving replaces the old IDs', () async {
    final repository = await repositoryWith({
      SharedPrefsSeenAlertsRepository.seenIdsKey: ['low:old'],
    });

    await repository.saveSeenIds({'low:new'});

    expect(await repository.loadSeenIds(), {'low:new'});
  });
}
