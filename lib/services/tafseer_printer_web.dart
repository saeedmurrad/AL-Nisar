import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool get canPrintTafseer => true;

/// Prints [html] from an offscreen same-origin iframe.
///
/// An iframe rather than a popup window: popups are blocked unless the click
/// handler is synchronous, and loading the surah's rukus first makes this
/// handler async. It also keeps the print stylesheet sealed inside its own
/// document, so nothing from the app's own CSS can leak into the page.
Future<void> printTafseerDocument(String html) async {
  final iframe = web.document.createElement('iframe') as web.HTMLIFrameElement
    ..setAttribute('aria-hidden', 'true')
    ..setAttribute('tabindex', '-1')
    ..style.position = 'fixed'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.width = '0'
    ..style.height = '0'
    ..style.border = '0'
    ..style.opacity = '0';

  final loaded = Completer<void>();
  iframe.addEventListener(
    'load',
    ((web.Event _) {
      if (!loaded.isCompleted) loaded.complete();
    }).toJS,
  );

  iframe.srcdoc = html.toJS;
  web.document.body!.appendChild(iframe);

  try {
    await loaded.future.timeout(const Duration(seconds: 20));

    // Nastaliq arrives over the network. Printing before it lands gives a
    // naskh fallback — the wrong script for this content — so wait for the
    // document's own fonts, but never block the dialog forever on a slow or
    // offline font host.
    final fonts = iframe.contentDocument?.fonts;
    if (fonts != null) {
      await fonts.ready.toDart.timeout(
        const Duration(seconds: 10),
        onTimeout: () => fonts,
      );
    }

    final frameWindow = iframe.contentWindow;
    if (frameWindow == null) {
      throw StateError('The print frame was detached before it could print.');
    }
    frameWindow.focus();
    frameWindow.print();
  } finally {
    // Safari resolves print() before the sheet is actually dismissed; give it
    // a beat so the frame is not pulled out from under the dialog.
    Timer(const Duration(seconds: 1), () => iframe.remove());
  }
}
