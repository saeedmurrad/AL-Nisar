import 'package:flutter_test/flutter_test.dart';
import 'package:spiritual_learning_app/models/gallery_folder.dart';
import 'package:spiritual_learning_app/models/gallery_image_model.dart';
import 'package:spiritual_learning_app/services/gallery_service.dart';

void main() {
  test('irshad imports appear in Irshad Pak album', () {
    final img = GalleryImageModel(
      id: 'irshad_abc',
      storagePath: 'gallery_images/irshad_abc.jpg',
      downloadUrl: 'https://example.com/a.jpg',
      uploadedAt: DateTime(2026, 1, 1),
      isActive: true,
      folder: 'irshadat',
    );
    expect(img.showInGallery, isTrue);
    expect(img.folderInfo, GalleryFolder.irshadat);
  });

  test('groupByFolder buckets visible albums only', () {
    final images = [
      GalleryImageModel(
        id: '1',
        storagePath: '',
        downloadUrl: 'https://example.com/1.jpg',
        uploadedAt: DateTime(2026, 1, 2),
        isActive: true,
        folder: GalleryFolder.saeenG.id,
      ),
      GalleryImageModel(
        id: '2',
        storagePath: '',
        downloadUrl: 'https://example.com/2.jpg',
        uploadedAt: DateTime(2026, 1, 1),
        isActive: true,
        folder: GalleryFolder.banner.id,
      ),
    ];

    final grouped = GalleryService.groupByFolder(images);
    expect(grouped[GalleryFolder.saeenG]!.length, 1);
    expect(grouped[GalleryFolder.banner]!.length, 1);
    expect(grouped[GalleryFolder.saeenG]!.first.id, '1');
  });
}
