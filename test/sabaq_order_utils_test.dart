import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/models/sabaq_pdf_model.dart';
import 'package:spiritual_learning_app/utils/sabaq_order_utils.dart';

SabaqPdfModel _model({
  required String id,
  required String titleEn,
  DateTime? uploadedAt,
  int? orderNumber,
}) {
  return SabaqPdfModel(
    id: id,
    titleEn: titleEn,
    titleUr: '',
    storagePath: 'path/$id.pdf',
    thumbnailUrl: '',
    uploadedAt: uploadedAt ?? DateTime(2026, 1, 1),
    isActive: true,
    orderNumber: orderNumber,
  );
}

void main() {
  test('parseSabaqOrderNumber reads Sabaq 05 title', () {
    expect(parseSabaqOrderNumber('Sabaq 05 — Ishq'), 5);
  });

  test('dedupeSabaqList keeps newest doc for same lesson number', () {
    final older = _model(
      id: 'old',
      titleEn: 'Sabaq 05 — Ishq',
      uploadedAt: DateTime(2026, 1, 1),
    );
    final newer = _model(
      id: 'new',
      titleEn: 'Sabaq 05 — Ishq (revised)',
      uploadedAt: DateTime(2026, 2, 1),
    );
    final out = dedupeSabaqList([
      _model(id: '1', titleEn: 'Sabaq 01 — A', orderNumber: 1),
      _model(id: '2', titleEn: 'Sabaq 02 — B', orderNumber: 2),
      _model(id: '3', titleEn: 'Sabaq 03 — C', orderNumber: 3),
      _model(id: '4', titleEn: 'Sabaq 04 — D', orderNumber: 4),
      older,
      newer,
    ]);
    expect(out.length, 5);
    expect(out.where((s) => s.titleEn.contains('05')).length, 1);
    expect(out.last.id, 'new');
  });

  test('first Sabaq is free; next requestable is the second', () {
    final ordered = dedupeSabaqList([
      _model(id: '1', titleEn: 'Sabaq 01 — A', orderNumber: 1),
      _model(id: '2', titleEn: 'Sabaq 02 — B', orderNumber: 2),
      _model(id: '3', titleEn: 'Sabaq 03 — C', orderNumber: 3),
    ]);
    expect(isFreeSabaqId(ordered, '1'), isTrue);
    expect(isFreeSabaqId(ordered, '2'), isFalse);
    expect(
      nextRequestableSabaqId(ordered: ordered, grantedIds: {}),
      '2',
    );
  });

  test('after grant, next requestable advances sequentially', () {
    final ordered = dedupeSabaqList([
      _model(id: '1', titleEn: 'Sabaq 01 — A', orderNumber: 1),
      _model(id: '2', titleEn: 'Sabaq 02 — B', orderNumber: 2),
      _model(id: '3', titleEn: 'Sabaq 03 — C', orderNumber: 3),
    ]);
    expect(
      nextRequestableSabaqId(ordered: ordered, grantedIds: {'2'}),
      '3',
    );
    expect(
      nextRequestableSabaqId(ordered: ordered, grantedIds: {'2', '3'}),
      isNull,
    );
  });

  test('memberHasSabaqAccess treats free first and grants', () {
    final ordered = dedupeSabaqList([
      _model(id: '1', titleEn: 'Sabaq 01 — A', orderNumber: 1),
      _model(id: '2', titleEn: 'Sabaq 02 — B', orderNumber: 2),
    ]);
    expect(
      memberHasSabaqAccess(ordered: ordered, grantedIds: {}, sabaqId: '1'),
      isTrue,
    );
    expect(
      memberHasSabaqAccess(ordered: ordered, grantedIds: {}, sabaqId: '2'),
      isFalse,
    );
    expect(
      memberHasSabaqAccess(ordered: ordered, grantedIds: {'2'}, sabaqId: '2'),
      isTrue,
    );
  });
}
