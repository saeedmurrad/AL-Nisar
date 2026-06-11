import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_role.dart';
import 'user_profile_model.dart';

class AuthService {
  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _google = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _google;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Stream<UserProfileModel?> profileStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc);
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final u = cred.user;
    if (u == null) throw Exception('no_user');
    await _upsertUserProfile(u);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final u = cred.user;
    if (u == null) throw Exception('no_user');

    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await u.updateDisplayName(name);
      await u.reload();
    }

    await _upsertUserProfile(_auth.currentUser ?? u);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) {
      throw Exception('cancelled');
    }
    final auth = await account.authentication;
    final cred = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    final res = await _auth.signInWithCredential(cred);
    final u = res.user;
    if (u == null) throw Exception('no_user');

    await _upsertUserProfile(u);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }

  /// Persists display name to Firestore and Firebase Auth so it survives sign-out/sign-in.
  Future<void> updateDisplayName(String displayName) async {
    final u = _auth.currentUser;
    if (u == null) throw StateError('not_signed_in');
    final name = displayName.trim();
    if (name.isEmpty) throw StateError('empty_name');
    await u.updateDisplayName(name);
    await u.reload();
    await _firestore.collection('users').doc(u.uid).set(
      {'displayName': name},
      SetOptions(merge: true),
    );
  }

  Future<void> _upsertUserProfile(User u) async {
    final ref = _firestore.collection('users').doc(u.uid);
    final snap = await ref.get();
    final now = DateTime.now();

    // If doc exists, keep role. Otherwise create as default 'user'.
    String role = AppRole.user.firestoreValue;
    DateTime createdAt = now;
    if (snap.exists) {
      final data = snap.data() ?? {};
      role = (data['role'] as String?) ?? role;
      final ts = data['createdAt'];
      if (ts is Timestamp) createdAt = ts.toDate();
    }

    await ref.set(
      {
        'email': (u.email ?? '').trim().toLowerCase(),
        'displayName': u.displayName ?? '',
        'photoUrl': u.photoURL ?? '',
        'role': AppRole.fromString(role).firestoreValue,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt': Timestamp.fromDate(now),
      },
      SetOptions(merge: true),
    );
  }
}

