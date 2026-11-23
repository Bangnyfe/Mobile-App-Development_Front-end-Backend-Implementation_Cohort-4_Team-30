import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team30_app/app.dart';
import 'package:team30_app/core/router/app_router.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/features/settings/data/fake_account_repository.dart';
import 'package:team30_app/features/settings/data/shared_prefs_settings_repository.dart';
import 'package:team30_app/features/settings/domain/entities/pharmacy_account.dart';
import 'package:team30_app/features/settings/domain/repositories/account_repository.dart';

/// Account repository for tests: returns [account] (or throws while
/// [fail] is true), keeps the pharmacies saved (or throws while
/// [failSaving] is true) and counts sign-outs.
class TestAccountRepository implements AccountRepository {
  TestAccountRepository({
    this.account,
    this.fail = false,
    this.failSaving = false,
  });

  PharmacyAccount? account;
  bool fail;
  bool failSaving;
  int signOutCount = 0;
  final List<Pharmacy> saved = [];

  @override
  Future<PharmacyAccount> load() async {
    if (fail) throw Exception('load failed');
    return account ?? await const FakeAccountRepository().load();
  }

  @override
  Future<void> updatePharmacy(Pharmacy pharmacy) async {
    if (failSaving) throw Exception('save failed');
    saved.add(pharmacy);
  }

  @override
  Future<void> signOut() async => signOutCount++;
}

/// The sample account, signed in as a pharmacist instead of the owner.
Future<PharmacyAccount> pharmacistAccount() async {
  final sample = await const FakeAccountRepository().load();
  return PharmacyAccount(
    pharmacy: sample.pharmacy,
    user: sample.staff.firstWhere((member) => !member.isOwner),
    staff: sample.staff,
    categories: sample.categories,
  );
}

/// Pumps the whole app on a phone-sized screen (360 x 800 logical pixels
/// in portrait by default) and opens [location], the Settings tab unless
/// told otherwise. Returns the saved preferences so tests can check what
/// was stored.
Future<SharedPreferences> pumpSettings(
  WidgetTester tester, {
  AccountRepository? accountRepository,
  String location = RoutePaths.settings,
  Size physicalSize = const Size(1080, 2400),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final GoRouter router = createAppRouter();

  await tester.pumpWidget(
    PharmacyApp(
      router: router,
      settingsRepository: SharedPrefsSettingsRepository(prefs),
      accountRepository: accountRepository ?? TestAccountRepository(),
    ),
  );
  router.go(location);
  await tester.pumpAndSettle();
  return prefs;
}

/// Scrolls the current page until [finder] is on screen, then taps it.
Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    100,
    scrollable: find.byType(Scrollable).first,
  );
  // scrollUntilVisible stops as soon as the widget's edge appears, so
  // bring it fully into view before tapping its centre.
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
