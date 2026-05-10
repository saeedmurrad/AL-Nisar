import 'package:cloud_firestore/cloud_firestore.dart';

import 'irshad_firestore_model.dart';

class IrshadatBookmarkModel {
  const IrshadatBookmarkModel({
    required this.language,
    required this.irshadId,
    required this.dateLabel,
    required this.text,
    required this.imageUrl,
    required this.savedAt,
  });

  final IrshadatLanguage language;
  final String irshadId;
  final String dateLabel;
  final String text;
  final String imageUrl;
  final DateTime savedAt;

  String get id => '${language.name}_$irshadId';

  Map<String, dynamic> toJson() => {
        'language': language.name,
        'irshadId': irshadId,
        'dateLabel': dateLabel,
        'text': text,
        'imageUrl': imageUrl,
        'savedAt': savedAt.toIso8601String(),
      };

  factory IrshadatBookmarkModel.fromJson(Map<String, dynamic> json) {
    final langRaw = (json['language'] as String? ?? 'urdu').toLowerCase();
    final language =
        langRaw == 'english' ? IrshadatLanguage.english : IrshadatLanguage.urdu;
    return IrshadatBookmarkModel(
      language: language,
      irshadId: json['irshadId'] as String? ?? '',
      dateLabel: json['dateLabel'] as String? ?? '',
      text: json['text'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  factory IrshadatBookmarkModel.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    final langRaw = (data['language'] as String? ?? 'urdu').toLowerCase();
    final language =
        langRaw == 'english' ? IrshadatLanguage.english : IrshadatLanguage.urdu;
    DateTime savedAt = DateTime.now();
    final v = data['savedAt'];
    if (v is Timestamp) savedAt = v.toDate();
    return IrshadatBookmarkModel(
      language: language,
      irshadId: data['irshadId'] as String? ?? docId,
      dateLabel: data['dateLabel'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      savedAt: savedAt,
    );
  }
}

