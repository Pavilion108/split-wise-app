import 'package:web/web.dart' as web;

/// Web implementation — creates an anchor element with download attribute
/// to force the browser to download the file instead of opening it.
/// For cross-origin URLs (like GitHub), opens in new tab since download
/// attribute doesn't work cross-origin.
Future<bool> platformDownload(String url, {String fileName = 'download'}) async {
  try {
    // Check if same-origin (download attribute works).
    final currentOrigin = web.window.location.origin;
    final isSameOrigin = url.startsWith(currentOrigin);

    if (isSameOrigin) {
      // Same-origin: use download attribute to force download.
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download = fileName
        ..target = '_blank'
        ..rel = 'noopener noreferrer';

      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();
      return true;
    } else {
      // Cross-origin: open in new tab (download attribute won't work).
      web.window.open(url, '_blank');
      return true;
    }
  } catch (_) {
    return false;
  }
}
