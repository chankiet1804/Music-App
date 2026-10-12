/// App-side view of a signed-in user, so UI and tests stay off Firebase types.
class AppUser {
  const AppUser({required this.uid, this.email, this.emailVerified = false});

  final String uid;
  final String? email;
  final bool emailVerified;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser &&
          uid == other.uid &&
          email == other.email &&
          emailVerified == other.emailVerified;

  @override
  int get hashCode => Object.hash(uid, email, emailVerified);

  @override
  String toString() =>
      'AppUser{uid: $uid, email: $email, emailVerified: $emailVerified}';
}
