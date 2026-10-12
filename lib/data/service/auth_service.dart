import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:music_app/data/model/app_user.dart';
import 'package:music_app/data/model/auth_failure.dart';

/// Every method throws [AuthFailure] on error.
abstract interface class AuthService {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  /// Creates the account (which also signs in) and sends a verification email.
  Future<void> signUp({required String email, required String password});

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_toApp);

  @override
  AppUser? get currentUser => _toApp(_auth.currentUser);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<void> signUp({required String email, required String password}) =>
      _guard(() async {
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        // Sign-up already succeeded; a failed verification email is not fatal.
        try {
          await credential.user?.sendEmailVerification();
        } on FirebaseAuthException catch (e) {
          debugPrint('Verification email failed: ${e.code}');
        }
      });

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  static AppUser? _toApp(User? user) => user == null
      ? null
      : AppUser(
          uid: user.uid,
          email: user.email,
          emailVerified: user.emailVerified,
        );

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(e.code);
    }
  }
}
