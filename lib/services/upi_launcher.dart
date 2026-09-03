import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Attempts to launch a UPI payment app via the `upi://` deep link.
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
  // UPI deep links only work on mobile. On web/desktop, attempting
  // to open `upi://` results in a blank tab.
  if (kIsWeb) return false;

  final params = <String, String>{
    if (vpa != null && vpa.isNotEmpty) 'pa': vpa,
    if (payeeName != null && payeeName.isNotEmpty) 'pn': payeeName,
    'am': amount.toStringAsFixed(2),
    'cu': currency,
    if (note != null && note.isNotEmpty) 'tn': note,
  };
  final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
  final uri = Uri.parse('upi://pay?$query');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
