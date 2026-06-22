import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/shajra_urdu_detail_model.dart';
import 'shajra_bundled_service.dart';

class ShajraUrduDetailsService {
  ShajraUrduDetailsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('shajra_urdu_details');

  Stream<List<ShajraUrduDetailModel>> streamAllActive() {
    if (!_firebaseReady) return Stream.value(const <ShajraUrduDetailModel>[]);
    return _col.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ShajraUrduDetailModel.fromFirestore(d))
          .where((e) => e.isActive && e.number > 0 && e.number <= ShajraBundledService.maxEntryNumber && e.storagePath.isNotEmpty)
          .toList();
      list.sort((a, b) => a.number.compareTo(b.number));
      return list;
    });
  }

  Stream<Map<int, ShajraUrduDetailModel>> streamIndexByNumber() {
    return streamAllActive().map((list) {
      return {for (final e in list) e.number: e};
    });
  }
}

