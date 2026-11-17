import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';

/// Root widget. The router is passed in so tests can build the app
/// without Firebase and with a fresh navigation state.
class PharmacyApp extends StatelessWidget {
  const PharmacyApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pharmacy Inventory & POS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
