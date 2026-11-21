import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';

class AuthStatusListenable extends ChangeNotifier {
  AuthStatusListenable(AuthBloc bloc) : _status = bloc.state.status {
    _subscription = bloc.stream.listen((state) {
      if (state.status == _status) return;
      _status = state.status;
      notifyListeners();
    });
  }

  AuthStatus _status;
  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
