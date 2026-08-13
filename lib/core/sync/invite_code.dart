import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Generates a6-character invite code from trip id + secret.
/// The code is deterministic: same trip always produces the same code.
/// The code is shareable via WhatsApp/Gmail and typed manually.
class InviteCode {
  InviteCode._();

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _rand = Random.secure();

  /// Generate a random6-char code for a new trip.
  static String generate() {
    return List.generate(6, (_) => _chars[_rand.nextInt(_chars.length)]).join();
  }

  /// Derive a deterministic code from trip id (for verification).
  static String derive(String tripId) {
    final bytes = utf8.encode(tripId);
    final hash = sha256.convert(bytes);
    final hex = hash.toString();
    final code = StringBuffer();
    for (var i = 0; i < 6; i++) {
      final idx = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16) %
          _chars.length;
      code.write(_chars[idx]);
    }
    return code.toString();
  }

  /// Validate a code format (6 alphanumeric chars).
  static bool isValid(String code) {
    return RegExp(r'^[A-Z0-9]{6}$').hasMatch(code.toUpperCase());
  }

  /// Build a deep link for sharing via WhatsApp/Gmail.
  static Uri buildJoinLink(String code, {String? tripName}) {
    return Uri(
      scheme: 'https',
      host: 'splitwise.app',
      path: '/join/$code',
      queryParameters: {
        if (tripName != null) 'name': tripName,
      },
    );
  }

  /// Build a WhatsApp share message.
  static String buildWhatsAppMessage({
    required String code,
    required String tripName,
    required String creatorName,
    required String baseCurrency,
  }) {
    final link = buildJoinLink(code, tripName: tripName);
    return 'Join my trip "$tripName" on Split Wise!\n\n'
        'Code: $code\n'
        'Currency: $baseCurrency\n'
        'Created by: $creatorName\n\n'
        'Open the link or enter the code in the app:\n$link';
  }

  /// Build a plain text message for Gmail/other sharing.
  static String buildShareMessage({
    required String code,
    required String tripName,
    required String creatorName,
    required String baseCurrency,
  }) {
    final link = buildJoinLink(code, tripName: tripName);
    return 'Split Wise Trip Invitation\n'
        '========================\n\n'
        'Trip: $tripName\n'
        'Code: $code\n'
        'Currency: $baseCurrency\n'
        'Created by: $creatorName\n\n'
        'To join:\n'
        '1. Install Split Wise app\n'
        '2. Tap "Join Trip"\n'
        '3. Enter code: $code\n\n'
        'Or click: $link';
  }
}
