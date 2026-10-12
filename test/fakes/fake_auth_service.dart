import 'dart:async';

import 'package:music_app/data/model/app_user.dart';
import 'package:music_app/data/model/auth_failure.dart';
import 'package:music_app/data/service/auth_service.dart';

class FakeAuthService implements AuthService {
  final _controller = StreamController<AppUser?>.broadcast();
  AppUser? _user;

  /// When set, the next call throws it instead of succeeding.
  AuthFailure? failure;

  /// When set, calls wait on it before completing.
  Completer<void>? gate;

  final List<String> calls = [];

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Future<void> signIn({required String email, required String password}) =>
      _call(
        'signIn:$email:$password',
        () => _emit(AppUser(uid: 'u1', email: email)),
      );

  @override
  Future<void> signUp({required String email, required String password}) =>
      _call(
        'signUp:$email:$password',
        () => _emit(AppUser(uid: 'u1', email: email)),
      );

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _call('reset:$email', () {});

  @override
  Future<void> signOut() => _call('signOut', () => _emit(null));

  void _emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  Future<void> _call(String name, void Function() onSuccess) async {
    calls.add(name);
    await gate?.future;
    final error = failure;
    if (error != null) {
      failure = null;
      throw error;
    }
    onSuccess();
  }

  // Not awaited: a paused provider subscription would never see the done event.
  void dispose() {
    _controller.close();
  }
}
