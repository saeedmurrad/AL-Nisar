import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/irshad_firestore_model.dart';

class IrshadatService {
  IrshadatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  Stream<List<IrshadFirestoreModel>> streamIrshadat(IrshadatLanguage language) {
    if (!_firebaseReady) return Stream.value(const []);
    return _firestore.collection(language.firestoreCollection).snapshots().map((
      snap,
    ) {
      final list = snap.docs
          .map((d) => IrshadFirestoreModel.fromFirestore(d))
          .where((d) => d.isActive)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
