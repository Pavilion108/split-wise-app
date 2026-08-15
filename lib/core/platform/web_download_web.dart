import 'package:web/web.dart' as web;

/// Web implementation — creates an anchor element with download attribute
/// to force the browser to download the file instead of opening it.
Future<bool> platformDownload(String url, {String fileName = 'download'}) async {
  try {
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..target = '_blank'
      ..rel = 'noopener noreferrer';

    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    return true;
  } catch (_) {
    return false;
  }
}
