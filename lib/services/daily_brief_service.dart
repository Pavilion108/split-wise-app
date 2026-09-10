import 'dart:async';

import '../models/models.dart';
import '../repositories/expense_repository.dart';
import '../repositories/trip_repository.dart';
import '../services/balance_engine.dart';
import 'whatsapp_service.dart';

/// Generates daily brief summaries for trips.
/// Collects today's expenses and current balances, formats them for WhatsApp.
class DailyBriefService {
  DailyBriefService(
    this._expenseRepo,
    this._tripRepo,
    this._whatsapp,
  );

  final ExpenseRepository _expenseRepo;
  final TripRepository _tripRepo;
  final WhatsAppService _whatsapp;

  /// Generate and share daily brief for a trip.
  Future<bool> shareDailyBrief(String tripId) async {
    final trip = await _tripRepo.getTrip(tripId);
    if (trip == null) return false;

    final members = await _tripRepo.watchMembers(tripId).first;
    final expenses = await _expenseRepo.watchExpenses(tripId).first;
    final splits = await _expenseRepo.watchSplits(tripId).first;
    final settlements = await _expenseRepo.watchSettlements(tripId).first;

    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    // Filter today's expenses.
    final todayExpenses = expenses
        .where((e) => e.createdAt.isAfter(todayStart) && !e.deleted)
        .toList();

    // Compute current balance.
    final balance = computeBalance(
      expenses: expenses,
      splits: splits,
      settlements: settlements,
      members: members,
    );

    // Build member lookup.
    final memberMap = {for (final m in members) m.id: m};

    // Build expense summaries for today.
    final expenseSummaries = todayExpenses.map((e) {
      final payer = memberMap[e.authorId];
      return ExpenseSummary(
        payerName: payer?.name ?? 'Unknown',
        amount: e.convertedAmount > 0 ? e.convertedAmount : e.amount,
        category: e.category.isNotEmpty ? e.category : 'General',
      );
    }).toList();

    // Build balance map.
    final balanceMap = <String, double>{};
    for (final m in members) {
      final b = balance.forMember(m.id);
      balanceMap[m.name] = b?.net ?? 0;
    }

    // Generate the brief message.
    final message = _whatsapp.buildDailyBrief(
      tripName: trip.name,
      expenses: expenseSummaries,
      balances: balanceMap,
      baseCurrency: trip.baseCurrency,
    );

    // Open WhatsApp to send.
    return _whatsapp.sendDailyBrief(
      tripName: trip.name,
      summary: message,
    );
  }

  /// Generate a brief without sending (for display in-app).
  String generateBriefText({
    required String tripName,
    required String baseCurrency,
    required List<Expense> todayExpenses,
    required TripBalance balance,
    required List<Member> members,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📊 Daily Brief: $tripName');
    buffer.writeln('─' * 30);
    buffer.writeln();

    final memberMap = {for (final m in members) m.id: m};

    // Today's expenses.
    if (todayExpenses.isEmpty) {
      buffer.writeln('No expenses today.');
    } else {
      buffer.writeln('Today\'s Expenses:');
      for (final e in todayExpenses) {
        final payer = memberMap[e.authorId];
        buffer.writeln(
            '  • ${payer?.name ?? '?'}: $baseCurrency ${e.amount.toStringAsFixed(2)} (${e.category})');
      }
    }
    buffer.writeln();

    // Balances.
    buffer.writeln('Balances:');
    for (final m in members) {
      final b = balance.forMember(m.id);
      final net = b?.net ?? 0;
      if (net.abs() > 0.01) {
        final status = net > 0 ? 'receives' : 'owes';
        buffer.writeln(
            '  • ${m.name}: $status $baseCurrency ${net.abs().toStringAsFixed(2)}');
      } else {
        buffer.writeln('  • ${m.name}: settled up');
      }
    }
    buffer.writeln();
    buffer.writeln('— Spliti5');

    return buffer.toString();
  }
}
