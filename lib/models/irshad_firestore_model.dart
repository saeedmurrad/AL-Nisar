import 'package:cloud_firestore/cloud_firestore.dart';

enum IrshadatLanguage { urdu, english }

extension IrshadatLanguageX on IrshadatLanguage {
  String get firestoreCollection =>
      this == IrshadatLanguage.english ? 'irshadat_en' : 'irshadat_ur';

  String get label => this == IrshadatLanguage.english ? 'English' : 'Urdu';

  bool get isRtl => this == IrshadatLanguage.urdu;
}

/// A single Irshad entry in one language.
///
/// Stored in one of the two collections:
/// - `irshadat_en` (English)
/// - `irshadat_ur` (Urdu)
class IrshadFirestoreModel {
  const IrshadFirestoreModel({
    required this.id,
    required this.dateLabel,
    required this.text,
    required this.imageUrl,
    required this.createdAt,
    required this.isActive,
  });

  final String id;
  final String dateLabel;
  final String text;
  final String imageUrl;
  final DateTime createdAt;
  final bool isActive;

  factory IrshadFirestoreModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (ts is Timestamp) createdAt = ts.toDate();
    return IrshadFirestoreModel(
      id: doc.id,
      dateLabel: data['dateLabel'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      createdAt: createdAt,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateLabel': dateLabel,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}

