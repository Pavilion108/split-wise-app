import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// WhatsApp integration service.
/// Uses deep linking to open WhatsApp for group creation and messaging.
/// WhatsApp does not provide a public API for group creation,
/// so we guide the user through the process via deep links.
class WhatsAppService {
  /// Check if WhatsApp is installed on the device.
  Future<bool> isWhatsAppInstalled() async {
    if (kIsWeb) return false; // Deep link check not applicable on web.
    final uri = Uri.parse('whatsapp://');
    return canLaunchUrl(uri);
  }

  /// Open WhatsApp to create a group with the trip name.
  /// Returns true if WhatsApp was opened successfully.
  Future<bool> createGroup({
    required String tripName,
    required String inviteCode,
  }) async {
    // WhatsApp doesn't support group creation via deep link.
    // We open WhatsApp and guide the user to create the group manually.
    // The app provides the group name for them to copy/paste.

    final message = _buildGroupCreationGuide(
      tripName: tripName,
      inviteCode: inviteCode,
    );

    // Open WhatsApp with a pre-filled message to self (for copy/paste).
    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/',
      queryParameters: {
        'text': message,
      },
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Send an expense notification to WhatsApp.
  /// Opens WhatsApp with pre-filled message for the user to send.
  Future<bool> sendExpenseNotification({
    required String tripName,
    required String payerName,
    required double amount,
    required String currency,
    required String category,
    required String note,
  }) async {
    final message = _buildExpenseMessage(
      tripName: tripName,
      payerName: payerName,
      amount: amount,
      currency: currency,
      category: category,
      note: note,
    );

    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/',
      queryParameters: {
        'text': message,
      },
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Send daily brief to WhatsApp.
  /// Opens WhatsApp with pre-filled summary message.
  Future<bool> sendDailyBrief({
    required String tripName,
    required String summary,
  }) async {
    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/',
      queryParameters: {
        'text': summary,
      },
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Share trip details via WhatsApp.
  Future<bool> shareTripDetails({
    required String tripName,
    required String inviteCode,
    required String driveLink,
  }) async {
    final message = _buildTripShareMessage(
      tripName: tripName,
      inviteCode: inviteCode,
      driveLink: driveLink,
    );

    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: '/',
      queryParameters: {
        'text': message,
      },
    );

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // --- Message Builders ---

  String _buildGroupCreationGuide({
    required String tripName,
    required String inviteCode,
  }) {
    return '🎉 Create WhatsApp Group: "$tripName"\n\n'
        'Steps:\n'
        '1. Open WhatsApp → New Group\n'
        '2. Add members from your trip\n'
        '3. Group name: $tripName\n'
        '4. Share invite code: $inviteCode\n\n'
        'Split Wise will send expense updates here.';
  }

  String _buildExpenseMessage({
    required String tripName,
    required String payerName,
    required double amount,
    required String currency,
    required String category,
    required String note,
  }) {
    return '💰 New Expense in "$tripName"\n\n'
        '👤 Paid by: $payerName\n'
        '💵 Amount: $currency ${amount.toStringAsFixed(2)}\n'
        '📂 Category: $category\n'
        '${note.isNotEmpty ? '📝 Note: $note\n' : ''}'
        '\nOpened from Split Wise';
  }

  String _buildTripShareMessage({
    required String tripName,
    required String inviteCode,
    required String driveLink,
  }) {
    return '✈️ Trip: $tripName\n\n'
        '📋 Invite Code: $inviteCode\n'
        '📁 Drive Folder: $driveLink\n\n'
        'Join on Split Wise app to track expenses together!';
  }

  /// Build a daily brief message from trip balance data.
  String buildDailyBrief({
    required String tripName,
    required List<ExpenseSummary> expenses,
    required Map<String, double> balances,
    required String baseCurrency,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Daily Brief: $tripName');
    buffer.writeln('${'─' * 30}');
    buffer.writeln();

    // Today's expenses.
    buffer.writeln('Today\'s Expenses:');
    for (final e in expenses) {
      buffer.writeln('  • ${e.payerName}: $baseCurrency ${e.amount.toStringAsFixed(2)} (${e.category})');
    }
    buffer.writeln();

    // Balances.
    buffer.writeln('Balances:');
    for (final entry in balances.entries) {
      final status = entry.value > 0 ? 'receives' : 'owes';
      final amount = entry.value.abs();
      buffer.writeln('  • ${entry.key}: $status $baseCurrency ${amount.toStringAsFixed(2)}');
    }
    buffer.writeln();
    buffer.writeln('— Sent via Split Wise');

    return buffer.toString();
  }
}

// --- Models ---

class ExpenseSummary {
  const ExpenseSummary({
    required this.payerName,
    required this.amount,
    required this.category,
  });

  final String payerName;
  final double amount;
  final String category;
}
