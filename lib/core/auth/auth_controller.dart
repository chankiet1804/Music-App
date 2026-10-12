import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/core/auth/auth_providers.dart';
import 'package:music_app/data/service/auth_service.dart';

// Not autoDispose: sign-up navigates away while the call is still running.
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);

/// Runs auth actions and exposes their loading / error state to the UI.
/// Navigation is not handled here: the router reacts to auth state changes.
class AuthController extends AsyncNotifier<void> {
  AuthService get _service => ref.read(authServiceProvider);

  // Sync so the initial state is AsyncData, not a first-frame AsyncLoading.
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) =>
      _run(() => _service.signIn(email: email, password: password));

  Future<void> signUp(String email, String password) =>
      _run(() => _service.signUp(email: email, password: password));

  Future<void> resetPassword(String email) =>
      _run(() => _service.sendPasswordResetEmail(email));

  Future<void> signOut() => _run(_service.signOut);

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    if (ref.mounted) state = result;
  }
}
