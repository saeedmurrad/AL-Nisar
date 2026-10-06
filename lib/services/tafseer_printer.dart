import 'tafseer_printer_stub.dart'
    if (dart.library.js_interop) 'tafseer_printer_web.dart'
    as impl;

/// Whether this platform can hand an HTML document to a print dialog.
///
/// True on the web build only. There is no mobile equivalent worth shipping:
/// the Dart PDF writers available to us do not shape Nastaliq, so an Android
/// "print" would emit broken Urdu rather than the page the reader sees.
bool get canPrintTafseer => impl.canPrintTafseer;

/// Opens the browser's print dialog on [html], a complete standalone document.
///
/// Returns once the dialog has been dismissed.
Future<void> printTafseerDocument(String html) =>
    impl.printTafseerDocument(html);
