import 'package:firebase_auth/firebase_auth.dart';

import 'admin_config.dart';

class AdminAuthService {
  AdminAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authState => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isAdminSignedIn {
    final u = currentUser;
    return u != null && AdminConfig.isAllowedEmail(u.email);
  }

  Future<void> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final u = cred.user;
    if (u == null || !AdminConfig.isAllowedEmail(u.email)) {
      await _auth.signOut();
      throw Exception('not_admin');
    }
  }

  Future<void> signOut() => _auth.signOut();
}
