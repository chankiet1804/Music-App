import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_app/data/model/app_user.dart';
import 'package:music_app/data/service/auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

// Override in tests with a fake.
final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(ref.watch(firebaseAuthProvider)),
);

// Emits on listener registration, sign-in and sign-out.
final authStateProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);
