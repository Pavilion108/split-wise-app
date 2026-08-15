import 'package:url_launcher/url_launcher.dart';

/// Stub for non-web platforms — uses url_launcher.
Future<bool> platformDownload(String url, {String fileName = 'download'}) async {
  final uri = Uri.parse(url);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
