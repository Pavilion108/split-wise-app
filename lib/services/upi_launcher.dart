import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Attempts to launch a UPI payment app via the `upi://` deep link.
///
/// Uses `LaunchMode.platformDefault` so Android shows the native
/// "Open with" app picker instead of trying to force one app.
///
/// Returns `true` if the app was launched, `false` otherwise.
/// On web/desktop, always returns `false` — UPI deep links don't work
/// outside mobile apps.
Future<bool> launchUpi({
  String? vpa,
  String? payeeName,
  required double amount,
  String? note,
  String currency = 'INR',
}) async {
  if (kIsWeb) return false;

  final params = <String, String>{
    if (vpa != null && vpa.isNotEmpty) 'pa': vpa,
    if (payeeName != null && payeeName.isNotEmpty) 'pn': payeeName,
    if (amount > 0) 'am': amount.toStringAsFixed(2),
    'cu': currency,
    if (note != null && note.isNotEmpty) 'tn': note,
  };
  final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
  final uri = Uri.parse('upi://pay?$query');

  // platformDefault lets Android show the app chooser instead of
  // trying to force-open a specific app. On iOS it's a no-op since
  // UPI isn't available there anyway.
  return launchUrl(uri, mode: LaunchMode.platformDefault);
}
