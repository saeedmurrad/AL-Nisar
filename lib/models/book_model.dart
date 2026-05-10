import 'package:cloud_firestore/cloud_firestore.dart';

/// Book metadata from Firestore `books` collection; PDF bytes live in Storage at [storagePath].
class BookModel {
  const BookModel({
    required this.id,
    required this.title,
    required this.titleUrdu,
    required this.author,
    required this.category,
    required this.description,
    required this.storagePath,
    required this.coverImageUrl,
    required this.totalPages,
    required this.uploadedAt,
    required this.isActive,
  });

  final String id;
  final String title;
  final String titleUrdu;
  final String author;
  final String category;
  final String description;
  final String storagePath;
  final String coverImageUrl;
  final int totalPages;
  final DateTime uploadedAt;
  final bool isActive;

  factory BookModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final uploaded = data['uploadedAt'];
    DateTime uploadedAt = DateTime.now();
    if (uploaded is Timestamp) {
      uploadedAt = uploaded.toDate();
    }
    return BookModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      titleUrdu: data['titleUrdu'] as String? ?? '',
      author: data['author'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      coverImageUrl: data['coverImageUrl'] as String? ?? '',
      totalPages: (data['totalPages'] as num?)?.toInt() ?? 0,
      uploadedAt: uploadedAt,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'titleUrdu': titleUrdu,
      'author': author,
      'category': category,
      'description': description,
      'storagePath': storagePath,
      'coverImageUrl': coverImageUrl,
      'totalPages': totalPages,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'isActive': isActive,
    };
  }
}
