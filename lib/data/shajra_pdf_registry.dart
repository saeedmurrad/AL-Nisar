import '../models/shajra_entry_model.dart';

/// Maps Shajra personalities to PDFs that ship with the app.
///
/// Convention used here (you can change it anytime):
/// - `assets/pdfs/shajra/english/<number>.pdf`
/// - `assets/pdfs/shajra/urdu/<number>.pdf`
///
/// If a PDF is not available for a given entry, return null.
class ShajraPdfRegistry {
  const ShajraPdfRegistry();

  String? assetFor(ShajraEntryModel entry) {
    // PDFs are only used for the Urdu Shajra section.
    if (entry.language != ShajraEntryModel.urdu) return null;

    final n = entry.number;
    if (n <= 0) return null;

    return 'assets/pdfs/shajra/urdu/$n.pdf';
  }
}

