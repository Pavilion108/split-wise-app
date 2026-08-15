import 'web_download_stub.dart'
    if (dart.library.js_interop) 'web_download_web.dart';

/// Triggers a file download on web.
/// On mobile/desktop, falls back to url_launcher.
Future<bool> downloadFile(String url, {String fileName = 'download'}) {
  return platformDownload(url, fileName: fileName);
}
