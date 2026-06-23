/// Gallery album folders shown in the app.
class GalleryFolder {
  const GalleryFolder({
    required this.id,
    required this.label,
    required this.sortOrder,
    this.showInGallery = true,
  });

  final String id;
  final String label;
  final int sortOrder;

  /// False for internal-only albums (e.g. Irshad imports).
  final bool showInGallery;

  static const saeenG = GalleryFolder(
    id: 'saeen_g',
    label: 'Saeen G',
    sortOrder: 1,
  );

  static const blessedFamily = GalleryFolder(
    id: 'blessed_family',
    label: 'Blessed Family',
    sortOrder: 2,
  );

  static const banner = GalleryFolder(
    id: 'banner',
    label: 'Banner',
    sortOrder: 3,
  );

  static const general = GalleryFolder(
    id: 'general',
    label: 'General',
    sortOrder: 99,
  );

  /// Images copied from Irshadat posts — shown as its own Gallery album.
  static const irshadat = GalleryFolder(
    id: 'irshadat',
    label: 'Irshad Pak',
    sortOrder: 4,
  );

  static const all = [
    saeenG,
    blessedFamily,
    banner,
    general,
    irshadat,
  ];

  static const visibleInGallery = [
    saeenG,
    blessedFamily,
    banner,
    irshadat,
    general,
  ];

  static GalleryFolder fromId(String? id) {
    final key = (id ?? '').trim();
    for (final f in all) {
      if (f.id == key) return f;
    }
    return general;
  }

  static String normalizeId(String? id) => fromId(id).id;
}
