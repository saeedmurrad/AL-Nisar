import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/social_links_config.dart';

class SocialLinksService {
  SocialLinksService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const _docPath = 'app_config/social';

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Stream<SocialLinksConfig> streamConfig() {
    if (!_firebaseReady) {
      return Stream.value(SocialLinksConfig.defaults);
    }
    return _firestore.doc(_docPath).snapshots().map((snap) {
      return SocialLinksConfig.fromMap(snap.data());
    });
  }

  Future<SocialLinksConfig> loadConfig() async {
    if (!_firebaseReady) return SocialLinksConfig.defaults;
    try {
      final snap = await _firestore.doc(_docPath).get();
      return SocialLinksConfig.fromMap(snap.data());
    } catch (_) {
      return SocialLinksConfig.defaults;
    }
  }

  Future<void> saveConfig(SocialLinksConfig config) async {
    if (!_firebaseReady) {
      throw StateError('Firebase is not initialized');
    }
    await _firestore.doc(_docPath).set(config.toMap(), SetOptions(merge: true));
  }
}
