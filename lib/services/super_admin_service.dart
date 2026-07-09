import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/app_role.dart';
import '../auth/user_profile_model.dart';

class SuperAdminService {
  SuperAdminService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<UserProfileModel>> streamAllUsers() {
    return _firestore.collection('users').snapshots().map((snap) {
      final list = snap.docs.map(UserProfileModel.fromFirestore).toList();
      list.sort((a, b) => a.email.compareTo(b.email));
      return list;
    });
  }

  Future<void> setUserRole(String uid, AppRole role) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.firestoreValue,
    });
  }
}
