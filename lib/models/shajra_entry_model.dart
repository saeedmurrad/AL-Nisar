import '../services/shajra_scrape_client.dart';

/// One row in the Shajra Pak chain (English from web or Urdu dummy).
///
/// [detailUrl] is for HTTP only — never show in UI, tooltips, or share text.
class ShajraEntryModel {
  const ShajraEntryModel({
    required this.number,
    required this.fullTitle,
    required this.shortName,
    required this.detailUrl,
    required this.language,
  });

  final int number;
  final String fullTitle;
  final String shortName;

  /// Internal fetch URL only. Never displayed to the user.
  final String detailUrl;
  final String language;

  static const String english = 'english';
  static const String urdu = 'urdu';

  /// Short label for list rows (never the full alqabat line).
  String get listDisplayName {
    final full = fullTitle.trim();
    return language == urdu
        ? ShajraScrapeClient.listLabelUrdu(full, number)
        : ShajraScrapeClient.listLabelEnglish(full, number);
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'fullTitle': fullTitle,
        'shortName': shortName,
        'detailUrl': detailUrl,
        'language': language,
      };

  factory ShajraEntryModel.fromJson(Map<String, dynamic> json) {
    return ShajraEntryModel(
      number: json['number'] as int,
      fullTitle: json['fullTitle'] as String,
      shortName: json['shortName'] as String,
      detailUrl: json['detailUrl'] as String? ?? '',
      language: json['language'] as String? ?? english,
    );
  }
}

/// Arguments for the Shajra PDF viewer screen.
class ShajraPdfRouteArgs {
  const ShajraPdfRouteArgs({
    required this.entry,
    required this.assetPath,
  });

  final ShajraEntryModel entry;
  final String assetPath;
}

/// Arguments for admin upload of Urdu Shajra detail PDF.
class AdminShajraUrduUploadArgs {
  const AdminShajraUrduUploadArgs({required this.entry});

  final ShajraEntryModel entry;
}

/// Arguments for opening an Urdu Shajra PDF from Firebase Storage.
class ShajraUrduPdfArgs {
  const ShajraUrduPdfArgs({
    required this.number,
    required this.titleUrdu,
    required this.storagePath,
  });

  final int number;
  final String titleUrdu;
  final String storagePath;
}

/// Arguments for [ShajraDetailScreen] (in-memory navigation only).
class ShajraDetailRouteArgs {
  const ShajraDetailRouteArgs({
    required this.entry,
    required this.allEntries,
  });

  final ShajraEntryModel entry;
  final List<ShajraEntryModel> allEntries;
}
