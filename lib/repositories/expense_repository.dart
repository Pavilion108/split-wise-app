import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../core/sync/cloud_sync.dart';
import '../core/sync/op_log_service.dart';
import '../models/models.dart';
import '../services/currency_service.dart';
import '../services/split_calculator.dart';

class ExpenseRepository {
  ExpenseRepository(this._db, this._opLog, this._currency, this._cloudSync);

  final AppDatabase _db;
  final OpLogService _opLog;
  final CurrencyService _currency;
  final CloudSyncService? _cloudSync;

  static const _uuid = Uuid();

  // --- Streams ---

  Stream<List<Expense>> watchExpenses(String tripId) {
    return (_db.select(_db.expenses)
          ..where((e) => e.tripId.equals(tripId) & e.deleted.equals(false))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .watch()
        .map((rows) => rows.map(Expense.fromRow).toList());
  }

  Stream<List<Split>> watchSplits(String tripId) {
    final subquery = _db.selectOnly(_db.expenses)
      ..addColumns([_db.expenses.id])
      ..where(_db.expenses.tripId.equals(tripId));
    return (_db.select(_db.splitRows)
          ..where((s) => s.expenseId.isInQuery(subquery)))
        .watch()
        .map((rows) => rows.map(Split.fromRow).toList());
  }

  Stream<List<Settlement>> watchSettlements(String tripId) {
    return (_db.select(_db.settlements)
          ..where((s) => s.tripId.equals(tripId) & s.deleted.equals(false))
          ..orderBy([(s) => OrderingTerm.desc(s.paidAt)]))
        .watch()
        .map((rows) => rows.map(Settlement.fromRow).toList());
  }

  // --- Mutations ---

  Future<Expense> addExpense({
    required String tripId,
    required String authorId,
    required String category,
    required double amount,
    required String currency,
    required String baseCurrency,
    required String splitType,
    required List<String> allMemberIds,
    List<String>? subsetIds,
    String note = '',
    double? rate,
    String rateSource = 'manual',
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    if (rate != null && currency != baseCurrency) {
      await _currency.setRate(
        baseCurrency: baseCurrency,
        currency: currency,
        rate: rate,
        source: rateSource,
      );
    }

    final converted = await _currency.convert(
      amount: amount,
      fromCurrency: currency,
      toBase: baseCurrency,
    );
    final usedRate = rate ??
        await _currency.getRate(
          fromCurrency: currency,
          toBase: baseCurrency,
        ) ??
        1;
    final splits = computeSplits(
      amount: amount,
      type: splitType,
      allMemberIds: allMemberIds,
      subsetIds: subsetIds,
    );

    await _db.transaction(() async {
      await _db.into(_db.expenses).insert(ExpensesCompanion.insert(
            id: id,
            tripId: tripId,
            authorId: authorId,
            category: category,
            amount: amount,
            currency: currency,
            convertedAmount: converted,
            rateUsed: usedRate,
            note: Value(note),
            splitType: Value(splitType),
            createdAt: now,
          ));

      for (final s in splits) {
        final shareConverted = await _currency.convert(
          amount: s.amount,
          fromCurrency: currency,
          toBase: baseCurrency,
        );
        await _db.into(_db.splitRows).insert(SplitRowsCompanion.insert(
              id: _uuid.v4(),
              expenseId: id,
              memberId: s.memberId,
              shareAmount: s.amount,
              shareConverted: shareConverted,
            ));
      }

      await _opLog.append(
        tripId: tripId,
        opType: 'expense',
        entityId: id,
        payload: {
          'id': id,
          'authorId': authorId,
          'category': category,
          'amount': amount,
          'currency': currency,
          'splitType': splitType,
          'createdAt': now.toIso8601String(),
        },
      );
    });

    // Push to cloud.
    if (_cloudSync != null) {
      await _cloudSync.pushTripOps(tripId);
    }

    final row = await (_db.select(_db.expenses)
          ..where((e) => e.id.equals(id)))
        .getSingleOrNull();
    return Expense.fromRow(row!);
  }

  Future<void> editExpense({
    required Expense original,
    required String category,
    required double amount,
    required String currency,
    required String baseCurrency,
    required String splitType,
    required List<String> allMemberIds,
    List<String>? subsetIds,
    String note = '',
    double? rate,
    String rateSource = 'manual',
  }) async {
    final now = DateTime.now();

    if (rate != null && currency != baseCurrency) {
      await _currency.setRate(
        baseCurrency: baseCurrency,
        currency: currency,
        rate: rate,
        source: rateSource,
      );
    }

    final converted = await _currency.convert(
      amount: amount,
      fromCurrency: currency,
      toBase: baseCurrency,
    );
    final usedRate = rate ??
        await _currency.getRate(
          fromCurrency: currency,
          toBase: baseCurrency,
        ) ??
        1;
    final splits = computeSplits(
      amount: amount,
      type: splitType,
      allMemberIds: allMemberIds,
      subsetIds: subsetIds,
    );

    await _db.transaction(() async {
      await (_db.update(_db.expenses)
            ..where((e) => e.id.equals(original.id)))
          .write(ExpensesCompanion(
        category: Value(category),
        amount: Value(amount),
        currency: Value(currency),
        convertedAmount: Value(converted),
        rateUsed: Value(usedRate),
        note: Value(note),
        splitType: Value(splitType),
        editedAt: Value(now),
      ));

      await (_db.delete(_db.splitRows)
            ..where((s) => s.expenseId.equals(original.id)))
          .go();

      for (final s in splits) {
        final shareConverted = await _currency.convert(
          amount: s.amount,
          fromCurrency: currency,
          toBase: baseCurrency,
        );
        await _db.into(_db.splitRows).insert(SplitRowsCompanion.insert(
              id: _uuid.v4(),
              expenseId: original.id,
              memberId: s.memberId,
              shareAmount: s.amount,
              shareConverted: shareConverted,
            ));
      }

      await _opLog.append(
        tripId: original.tripId,
        opType: 'expense_corrected',
        entityId: original.id,
        payload: {
          'id': original.id,
          'category': category,
          'amount': amount,
          'currency': currency,
          'editedAt': now.toIso8601String(),
        },
      );
    });

    // Push to cloud.
    if (_cloudSync != null) {
      await _cloudSync.pushTripOps(original.tripId);
    }
  }

  Future<void> deleteExpense(Expense expense) async {
    await _db.transaction(() async {
      await (_db.update(_db.expenses)
            ..where((e) => e.id.equals(expense.id)))
          .write(const ExpensesCompanion(deleted: Value(true)));
      await _opLog.append(
        tripId: expense.tripId,
        opType: 'expense_deleted',
        entityId: expense.id,
        payload: {'id': expense.id, 'deleted': true},
      );
    });

    // Push to cloud.
    if (_cloudSync != null) {
      await _cloudSync.pushTripOps(expense.tripId);
    }
  }

  Future<Settlement> addSettlement({
    required String tripId,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    double? partialRemaining,
    String note = '',
    String method = '',
    String transactionRef = '',
    String status = 'paid',
    DateTime? verifiedAt,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.settlements).insert(SettlementsCompanion.insert(
            id: id,
            tripId: tripId,
            fromMemberId: fromMemberId,
            toMemberId: toMemberId,
            amount: amount,
            partialRemaining: Value(partialRemaining),
            method: Value(method),
            transactionRef: Value(transactionRef),
            status: Value(status),
            verifiedAt: Value(verifiedAt),
            note: Value(note),
            paidAt: now,
          ));
      await _opLog.append(
        tripId: tripId,
        opType: 'settlement',
        entityId: id,
        payload: {
          'id': id,
          'fromMemberId': fromMemberId,
          'toMemberId': toMemberId,
          'amount': amount,
          'paidAt': now.toIso8601String(),
        },
      );
    });

    // Push to cloud.
    if (_cloudSync != null) {
      await _cloudSync.pushTripOps(tripId);
    }

    final row = await (_db.select(_db.settlements)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    return Settlement.fromRow(row!);
  }
}
