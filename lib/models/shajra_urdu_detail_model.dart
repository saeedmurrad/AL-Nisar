import 'package:cloud_firestore/cloud_firestore.dart';

class ShajraUrduDetailModel {
  const ShajraUrduDetailModel({
    required this.number,
    required this.titleUrdu,
    required this.storagePath,
    required this.updatedAt,
    required this.isActive,
  });

  final int number;
  final String titleUrdu;

  /// Firebase Storage path (e.g. `shajra_urdu/12.pdf`)
  final String storagePath;
  final DateTime updatedAt;
  final bool isActive;

  String get id => number.toString();

  Map<String, dynamic> toMap() => {
    'number': number,
    'titleUrdu': titleUrdu,
    'storagePath': storagePath,
    'updatedAt': Timestamp.fromDate(updatedAt),
    'isActive': isActive,
  };

  factory ShajraUrduDetailModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const <String, dynamic>{};
    final ts = d['updatedAt'];
    return ShajraUrduDetailModel(
      number: (d['number'] as num?)?.toInt() ?? int.tryParse(doc.id) ?? 0,
      titleUrdu: (d['titleUrdu'] as String?) ?? '',
      storagePath: (d['storagePath'] as String?) ?? '',
      updatedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      isActive: (d['isActive'] as bool?) ?? true,
    );
  }
}
