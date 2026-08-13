import 'package:url_launcher/url_launcher.dart';

Future<bool> launchUpi({
  String? vpa,
  String? payeeName,
  required double amount,
  String? note,
  String currency = 'INR',
}) async {
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
