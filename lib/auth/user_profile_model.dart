import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_role.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.address,
    required this.photoUrl,
    required this.role,
    required this.createdAt,
    required this.lastLoginAt,
  });

  final String uid;
  final String email;
  final String displayName;
  /// Member mailing or location line from Firestore (`address`); optional.
  final String address;
  final String photoUrl;
  final AppRole role;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  factory UserProfileModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    DateTime dt(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return UserProfileModel(
      uid: doc.id,
      email: (data['email'] as String?) ?? '',
      displayName: (data['displayName'] as String?) ?? '',
      address: (data['address'] as String?) ?? '',
      photoUrl: (data['photoUrl'] as String?) ?? '',
      role: AppRole.fromString(data['role'] as String?),
      createdAt: dt(data['createdAt']),
      lastLoginAt: dt(data['lastLoginAt']),
    );
  }
}

