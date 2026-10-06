bool get canPrintTafseer => false;

Future<void> printTafseerDocument(String html) async {
  throw UnsupportedError('Printing is only available on the web build.');
}
