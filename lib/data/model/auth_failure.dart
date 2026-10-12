/// Auth error carrying the Firebase error code and a user-facing message.
class AuthFailure implements Exception {
  const AuthFailure(this.code);

  final String code;

  String get message => switch (code) {
    // Email enumeration protection merges these into invalid-credential.
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' => 'Incorrect email or password.',
    'email-already-in-use' => 'An account already exists for this email.',
    'weak-password' => 'Password is too weak. Use at least 6 characters.',
    'invalid-email' => 'Email address is not valid.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'Network error. Check your connection.',
    'operation-not-allowed' => 'Email/password sign-in is not enabled.',
    _ => 'Something went wrong. Please try again.',
  };

  @override
  String toString() => 'AuthFailure($code)';
}
