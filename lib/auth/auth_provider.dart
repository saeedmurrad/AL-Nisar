import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_role.dart';
import 'auth_service.dart';
import 'user_profile_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? service}) : _service = service ?? AuthService() {
    _sub = _service.authState.listen(_onAuthChanged);
  }

  final AuthService _service;
  StreamSubscription<User?>? _sub;
  StreamSubscription<UserProfileModel?>? _profileSub;

  User? _user;
  UserProfileModel? _profile;
  bool _loadingProfile = false;

  User? get user => _user;
  UserProfileModel? get profile => _profile;
  bool get isAuthenticated => _user != null;
  bool get isLoadingProfile => _loadingProfile;
  AppRole get role => _profile?.role ?? AppRole.user;
  bool get isAdminOrHigher => role.isAdminOrHigher;
  bool get isSuperAdmin => role.isSuperAdmin;

  Future<void> signInWithGoogle() => _service.signInWithGoogle();
  Future<void> signInWithEmail(String email, String password) =>
      _service.signInWithEmail(email, password);
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) =>
      _service.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
  Future<void> sendPasswordResetEmail(String email) =>
      _service.sendPasswordResetEmail(email);
  Future<void> signOut() => _service.signOut();
  Future<void> updateDisplayName(String displayName) =>
      _service.updateDisplayName(displayName);

  void _onAuthChanged(User? u) {
    _user = u;
    _profile = null;
    _loadingProfile = u != null;
    _profileSub?.cancel();
    if (u != null) {
      _profileSub = _service.profileStream(u.uid).listen((p) {
        _profile = p;
        _loadingProfile = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

