import 'package:flutter/material.dart';

/// Page frame shared by every auth screen.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.showBack = false});

  final Widget child;

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: showBack ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}