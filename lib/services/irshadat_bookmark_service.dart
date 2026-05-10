import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/irshadat_bookmark_model.dart';
import '../models/irshad_firestore_model.dart';

class IrshadatBookmarkService {
  IrshadatBookmarkService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const _prefsKey = 'al_nisar_irshadat_bookmarks_v1';

  String _prefsKeyForUser(String? uid) =>
      uid == null || uid.isEmpty ? _prefsKey : '${_prefsKey}_$uid';

  CollectionReference<Map<String, dynamic>>? get _userRef {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) return null;
    return _firestore.collection('users').doc(uid).collection('irshadat_bookmarks');
  }

  String _idKey(IrshadatLanguage language, String irshadId) =>
      '${language.name}_$irshadId';

  Future<List<IrshadatBookmarkModel>> getAllBookmarks() async {
    final ref = _userRef;
    if (ref != null) {
      final snap = await ref.orderBy('savedAt', descending: true).get();
      return snap.docs
          .map((d) => IrshadatBookmarkModel.fromFirestore(d.id, d.data()))
          .toList();
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyForUser(_auth.currentUser?.uid));
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map(
            (e) => IrshadatBookmarkModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return [];
    }
  }

  Future<bool> isBookmarked(IrshadatLanguage language, String irshadId) async {
    final key = _idKey(language, irshadId);
    final ref = _userRef;
    if (ref != null) {
      final doc = await ref.doc(key).get();
      return doc.exists;
    }
    final all = await getAllBookmarks();
    return all.any((b) => b.id == key);
  }

  Future<void> add({
    required IrshadatLanguage language,
    required IrshadFirestoreModel item,
  }) async {
    final key = _idKey(language, item.id);
    final ref = _userRef;
    if (ref != null) {
      await ref.doc(key).set({
        'language': language.name,
        'irshadId': item.id,
        'dateLabel': item.dateLabel,
        'text': item.text,
        'imageUrl': item.imageUrl,
        'savedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllBookmarks();
    all.removeWhere((b) => b.id == key);
    all.add(
      IrshadatBookmarkModel(
        language: language,
        irshadId: item.id,
        dateLabel: item.dateLabel,
        text: item.text,
        imageUrl: item.imageUrl,
        savedAt: DateTime.now(),
      ),
    );
    await prefs.setString(
      _prefsKeyForUser(_auth.currentUser?.uid),
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> remove(IrshadatLanguage language, String irshadId) async {
    final key = _idKey(language, irshadId);
    final ref = _userRef;
    if (ref != null) {
      await ref.doc(key).delete();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final all = await getAllBookmarks();
    all.removeWhere((b) => b.id == key);
    await prefs.setString(
      _prefsKeyForUser(_auth.currentUser?.uid),
      jsonEncode(all.map((e) => e.toJson()).toList()),
    );
  }

  Future<int> getCount() async => (await getAllBookmarks()).length;

  Future<({int total, int urdu, int english})> getStats() async {
    final all = await getAllBookmarks();
    final urdu = all.where((e) => e.language == IrshadatLanguage.urdu).length;
    final english = all.where((e) => e.language == IrshadatLanguage.english).length;
    return (total: all.length, urdu: urdu, english: english);
  }
}

