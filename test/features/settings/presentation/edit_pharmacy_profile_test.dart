import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team30_app/core/router/route_paths.dart';
import 'package:team30_app/features/settings/domain/entities/pharmacy_account.dart';
import 'package:team30_app/features/settings/presentation/cubit/account_cubit.dart';
import 'package:team30_app/features/settings/presentation/pages/edit_pharmacy_profile_page.dart';
import 'package:team30_app/features/settings/presentation/pages/pharmacy_profile_page.dart';
import 'package:team30_app/features/settings/presentation/pages/settings_page.dart';

import '../settings_test_helpers.dart';

final _edit = find.byTooltip('Edit pharmacy profile');
final _save = find.widgetWithText(FilledButton, 'Save');

Future<void> _openEditor(
  WidgetTester tester, {
  TestAccountRepository? repository,
  Size physicalSize = const Size(1080, 2400),
}) async {
  await pumpSettings(
    tester,
    location: RoutePaths.pharmacyProfile,
    accountRepository: repository,
    physicalSize: physicalSize,
  );
  await tester.tap(_edit);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  await tester.ensureVisible(_save);
  await tester.tap(_save);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the owner edits the profile, and Settings shows the new '
      'details', (tester) async {
    final repository = TestAccountRepository();
    await _openEditor(tester, repository: repository);

    expect(find.byType(EditPharmacyProfilePage), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('pharmacyNameField')),
      '  Amani Pharmacy Kimironko ',
    );
    await tester.enterText(find.byKey(const Key('districtField')), 'Gasabo');
    await tester.enterText(find.byKey(const Key('addressField')), '');
    await tester.enterText(
      find.byKey(const Key('phoneField')),
      '+250 788 111 222',
    );
    await _tapSave(tester);

    // Back on Pharmacy profile, with the saved details.
    expect(find.byType(PharmacyProfilePage), findsOneWidget);
    expect(find.text(EditPharmacyProfilePage.savedMessage), findsOneWidget);
    expect(find.text('Amani Pharmacy Kimironko'), findsOneWidget);
    expect(find.text('Gasabo'), findsOneWidget);
    expect(find.text('+250 788 111 222'), findsOneWidget);
    expect(find.text('KN 4 Ave'), findsNothing);

    expect(repository.saved, const [
      Pharmacy(
        id: 'ph1',
        name: 'Amani Pharmacy Kimironko',
        district: 'Gasabo',
        city: 'Kigali',
        phone: '+250 788 111 222',
      ),
    ]);

    // The Settings tab shows the new name too.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.textContaining('Amani Pharmacy Kimironko'), findsWidgets);
  });

  testWidgets('starts with the current details filled in', (tester) async {
    await _openEditor(tester);

    String text(String key) => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(Key(key)),
            matching: find.byType(TextField),
          ),
        )
        .controller!
        .text;

    expect(text('pharmacyNameField'), 'Amani Pharmacy');
    expect(text('districtField'), 'Nyarugenge');
    expect(text('cityField'), 'Kigali');
    expect(text('addressField'), 'KN 4 Ave');
    expect(text('phoneField'), '+250 788 000 000');
  });

  testWidgets('checks the fields before saving', (tester) async {
    final repository = TestAccountRepository();
    await _openEditor(tester, repository: repository);

    await tester.enterText(find.byKey(const Key('pharmacyNameField')), ' ');
    await tester.enterText(find.byKey(const Key('cityField')), '');
    await tester.enterText(find.byKey(const Key('phoneField')), '0788 ABC');
    await _tapSave(tester);

    expect(find.text('Enter the pharmacy name'), findsOneWidget);
    expect(find.text('Enter the city'), findsOneWidget);
    expect(
      find.text('Use digits only, with an optional + at the start'),
      findsOneWidget,
    );
    expect(find.byType(EditPharmacyProfilePage), findsOneWidget);
    expect(repository.saved, isEmpty);
  });

  testWidgets('stays on the form and says so when saving fails', (
    tester,
  ) async {
    await _openEditor(
      tester,
      repository: TestAccountRepository(failSaving: true),
    );

    await tester.enterText(
      find.byKey(const Key('pharmacyNameField')),
      'New name',
    );
    await _tapSave(tester);

    expect(find.byType(EditPharmacyProfilePage), findsOneWidget);
    expect(find.text(AccountCubit.saveFailedMessage), findsOneWidget);

    // Nothing changed behind it.
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Amani Pharmacy'), findsOneWidget);
  });

  testWidgets('pharmacists see the profile without an Edit button', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      location: RoutePaths.pharmacyProfile,
      accountRepository: TestAccountRepository(
        account: await pharmacistAccount(),
      ),
    );

    expect(find.text('Amani Pharmacy'), findsOneWidget);
    expect(_edit, findsNothing);
  });

  testWidgets('pharmacists who open the edit address are turned away', (
    tester,
  ) async {
    await pumpSettings(
      tester,
      location: RoutePaths.editPharmacyProfile,
      accountRepository: TestAccountRepository(
        account: await pharmacistAccount(),
      ),
    );

    expect(find.text(EditPharmacyProfilePage.ownerOnlyMessage), findsOneWidget);
    expect(_save, findsNothing);
  });

  testWidgets('fits in landscape without overflowing', (tester) async {
    final repository = TestAccountRepository();
    await _openEditor(
      tester,
      repository: repository,
      physicalSize: const Size(2400, 1080),
    );

    expect(tester.takeException(), isNull);
    await _tapSave(tester);

    expect(tester.takeException(), isNull);
    expect(repository.saved, hasLength(1));
  });
}
