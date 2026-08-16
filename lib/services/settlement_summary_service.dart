import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/models.dart';
import '../repositories/expense_repository.dart';
import '../repositories/trip_repository.dart';
import '../services/balance_engine.dart';
import '../services/whatsapp_service.dart';
import '../core/constants.dart';

/// Builds a final settlement summary for a completed trip and exports it
/// to WhatsApp (text) or as a downloadable PDF.
class SettlementSummaryService {
  SettlementSummaryService(
    this._tripRepo,
    this._expenseRepo,
    this._whatsapp,
  );

  final TripRepository _tripRepo;
  final ExpenseRepository _expenseRepo;
  final WhatsAppService _whatsapp;

  /// Collect all data needed for the summary.
  Future<_SettlementData> _collect(String tripId) async {
    final trip = await _tripRepo.getTrip(tripId);
    final members = await _tripRepo.watchMembers(tripId).first;
    final expenses = await _expenseRepo.watchExpenses(tripId).first;
    final splits = await _expenseRepo.watchSplits(tripId).first;
    final settlements = await _expenseRepo.watchSettlements(tripId).first;

    final activeExpenses = expenses.where((e) => !e.deleted).toList();
    final balance = computeBalance(
      expenses: activeExpenses,
      splits: splits,
      settlements: settlements.where((s) => !s.deleted).toList(),
      members: members,
    );
    final transfers = suggestSettlements(balance);

    return _SettlementData(
      trip: trip,
      members: members,
      expenses: activeExpenses,
      balance: balance,
      transfers: transfers,
    );
  }

  /// Plain-text summary suitable for WhatsApp.
  Future<String> buildSummaryText(String tripId) async {
    final d = await _collect(tripId);
    if (d.trip == null) return '';
    final memberMap = {for (final m in d.members) m.id: m};
    final cur = d.trip!.baseCurrency;
    final b = StringBuffer();

    b.writeln('✅ Trip Settled: ${d.trip!.name}');
    b.writeln('${'─' * 32}');
    b.writeln();
    b.writeln('Total Expense: ${formatMoney(d.balance.totalExpense, cur)}');
    b.writeln();

    b.writeln('Per Person:');
    for (final m in d.members) {
      final bal = d.balance.forMember(m.id);
      final paid = bal?.paid ?? 0;
      final share = bal?.share ?? 0;
      final net = bal?.net ?? 0;
      final status = net > 0.01
          ? 'receives ${formatMoney(net, cur)}'
          : net < -0.01
              ? 'owes ${formatMoney(net.abs(), cur)}'
              : 'settled up';
      b.writeln('  • ${m.name}: paid ${formatMoney(paid, cur)} / '
          'share ${formatMoney(share, cur)} → $status');
    }
    b.writeln();

    b.writeln('Who pays whom:');
    if (d.transfers.isEmpty) {
      b.writeln('  • All settled — nothing left to pay!');
    } else {
      for (final t in d.transfers) {
        final from = memberMap[t.from]?.name ?? '?';
        final to = memberMap[t.to]?.name ?? '?';
        b.writeln('  • $from → $to: ${formatMoney(t.amount, cur)}');
      }
    }
    b.writeln();
    b.writeln('— Settled via Split Wise');

    return b.toString();
  }

  /// Open WhatsApp with the pre-filled summary.
  Future<bool> shareToWhatsApp(String tripId) async {
    final text = await buildSummaryText(tripId);
    if (text.isEmpty) return false;
    return _whatsapp.sendDailyBrief(tripName: 'Settlement', summary: text);
  }

  /// Build a PDF document of the summary and return its bytes.
  Future<Uint8List> buildPdf(String tripId) async {
    final d = await _collect(tripId);
    final cur = d.trip?.baseCurrency ?? 'INR';
    final memberMap = {for (final m in d.members) m.id: m};
    final pdf = pw.Document(title: '${d.trip?.name ?? 'Trip'} — Settlement');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('${d.trip?.name ?? 'Trip'} — Settlement Summary',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(color: PdfColors.grey),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Total Expense: ${formatMoney(d.balance.totalExpense, cur)}',
            style: pw.TextStyle(
                fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Per Person',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            context: context,
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle:
                pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            headers: const ['Member', 'Paid', 'Share', 'Balance'],
            data: [
              for (final m in d.members)
                _memberRow(m, d.balance.forMember(m.id), cur),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Who pays whom',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          if (d.transfers.isEmpty)
            pw.Text('All settled — nothing left to pay!')
          else
            pw.Table.fromTextArray(
              context: context,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
              headers: const ['From', 'To', 'Amount'],
              data: [
                for (final t in d.transfers)
                  [
                    memberMap[t.from]?.name ?? '?',
                    memberMap[t.to]?.name ?? '?',
                    formatMoney(t.amount, cur),
                  ],
              ],
            ),
          pw.SizedBox(height: 24),
          pw.Center(
            child: pw.Text('— Settled via Split Wise —',
                style: const pw.TextStyle(color: PdfColors.grey)),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  List<String> _memberRow(Member m, Balance? bal, String cur) {
    final net = bal?.net ?? 0;
    final netStr = net.abs() < 0.01
        ? 'settled'
        : '${net > 0 ? '+' : '-'}${formatMoney(net.abs(), cur)}';
    return [
      m.name,
      formatMoney(bal?.paid ?? 0, cur),
      formatMoney(bal?.share ?? 0, cur),
      netStr,
    ];
  }
}

class _SettlementData {
  _SettlementData({
    required this.trip,
    required this.members,
    required this.expenses,
    required this.balance,
    required this.transfers,
  });

  final Trip? trip;
  final List<Member> members;
  final List<Expense> expenses;
  final TripBalance balance;
  final List<SuggestedTransfer> transfers;
}
