import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'features/auth/data/auth_backed_account_repository.dart';
import 'features/auth/data/firebase_auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/notifications/data/shared_prefs_seen_alerts_repository.dart';
import 'features/settings/data/fake_account_repository.dart';
import 'features/settings/data/shared_prefs_settings_repository.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();

  // Created before the app so the router can follow the sign-in status
  // from the first frame. AuthStarted begins listening to Firebase, which
  // reports the saved session (if any) and moves the app off Splash.
  final authRepository = FirebaseAuthRepository();
  final authBloc = AuthBloc(authRepository)..add(const AuthStarted());

  runApp(
    PharmacyApp(
      router: createAppRouter(authBloc: authBloc),
      settingsRepository: SharedPrefsSettingsRepository(prefs),
      seenAlertsRepository: SharedPrefsSeenAlertsRepository(prefs),
      authBloc: authBloc,
      accountRepository: AuthBackedAccountRepository(
        details: const FakeAccountRepository(),
        auth: authRepository,
      ),
    ),
  );
}
