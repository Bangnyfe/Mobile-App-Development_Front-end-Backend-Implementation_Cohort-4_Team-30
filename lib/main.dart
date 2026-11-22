import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/auth_backed_account_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/data/shared_prefs_pharmacy_draft_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/invites/data/firestore_invite_repository.dart';
import 'features/notifications/data/shared_prefs_seen_alerts_repository.dart';
import 'features/inventory/data/firestore_batch_repository.dart';
import 'features/inventory/data/firestore_product_repository.dart';
import 'features/pos/data/current_pharmacy_product_catalog.dart';
import 'features/pos/data/firestore_checkout_repository.dart';
import 'features/pos/data/inventory_product_catalog.dart';
import 'features/sales/data/current_pharmacy_sales_repository.dart';
import 'features/sales/data/firestore_sales_repository.dart';
import 'features/scanner/data/current_pharmacy_product_lookup_repository.dart';
import 'features/scanner/data/firestore_product_lookup_repository.dart';
import 'features/settings/data/fake_account_repository.dart';
import 'features/settings/data/shared_prefs_settings_repository.dart';
import 'firebase_options.dart';
import 'features/stock_removal/data/current_pharmacy_stock_removal_repository.dart';
import 'features/stock_removal/data/firestore_stock_removal_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();

  // Shared by auth (which saves the details typed on Register) and the
  // pharmacy setup step (which pre-fills them).
  final pharmacyDrafts = SharedPrefsPharmacyDraftRepository(prefs);

  // Created before the app so the router can follow the sign-in status
  // from the first frame. AuthStarted begins listening to Firebase, which
  // reports the saved session (if any) and moves the app off Splash.
  final authRepository = FirebaseAuthRepository(drafts: pharmacyDrafts);
  final authBloc = AuthBloc(authRepository)..add(const AuthStarted());

  runApp(
    PharmacyApp(
      // Confirmed sales are saved in the seller's pharmacy, lowering each
      // batch in the same transaction.
      router: createAppRouter(
        authBloc: authBloc,
        checkoutRepository: FirestoreCheckoutRepository(),
      ),
      settingsRepository: SharedPrefsSettingsRepository(prefs),
      seenAlertsRepository: SharedPrefsSeenAlertsRepository(prefs),
      authBloc: authBloc,
      inviteRepository: FirestoreInviteRepository(),
      // Sales saved by checkout, for the signed-in user's pharmacy.
      salesRepository: CurrentPharmacySalesRepository(
        pharmacyId: () => authBloc.state.user?.pharmacyId,
        forPharmacy: (id) => FirestoreSalesRepository(pharmacyId: id),
      ),
      // The Sell tab finds scanned barcodes among the signed-in
      // pharmacy's products.
      productLookupRepository: CurrentPharmacyProductLookupRepository(
        pharmacyId: () => authBloc.state.user?.pharmacyId,
        forPharmacy: (id) => FirestoreProductLookupRepository(pharmacyId: id),
      ),
      // ...and searches them by name, through the inventory repositories.
      productCatalog: CurrentPharmacyProductCatalog(
        pharmacyId: () => authBloc.state.user?.pharmacyId,
        forPharmacy: (id) => InventoryProductCatalog(
          products: FirestoreProductRepository(pharmacyId: id),
          batches: FirestoreBatchRepository(pharmacyId: id),
        ),
      ),
      // Remove stock reads and writes the signed-in user's pharmacy.
      stockRemovalRepository: CurrentPharmacyStockRemovalRepository(
        pharmacyId: () => authBloc.state.user?.pharmacyId,
        forPharmacy: (id) => FirestoreStockRemovalRepository(
          pharmacyId: id,
          removedBy: () => authBloc.state.user?.uid ?? '',
          removedByName: () => authBloc.state.user?.name ?? '',
        ),
      ),
      pharmacyDraftRepository: pharmacyDrafts,
      accountRepository: AuthBackedAccountRepository(
        details: const FakeAccountRepository(),
        auth: authRepository,
      ),
    ),
  );
}
