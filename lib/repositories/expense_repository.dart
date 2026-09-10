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
      ..where(
          _db.expenses.tripId.equals(tripId) & _db.expenses.deleted.equals(false));
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

      // Distribute the converted total across members to guarantee
      // sum(shareConverted) == convertedAmount (no rounding drift).
      final baseShares = _distributeBaseCurrency(
        convertedTotal: converted,
        originalSplits: splits,
        currency: currency,
        baseCurrency: baseCurrency,
        rate: usedRate,
      );

      for (var i = 0; i < splits.length; i++) {
        await _db.into(_db.splitRows).insert(SplitRowsCompanion.insert(
              id: _uuid.v4(),
              expenseId: id,
              memberId: splits[i].memberId,
              shareAmount: splits[i].amount,
              shareConverted: baseShares[i],
            ));
      }

      // Fetch back the splits we just inserted so we can include them
      // in the op payload — the remote device needs them to compute balances.
      final splitRows = await (_db.select(_db.splitRows)
            ..where((s) => s.expenseId.equals(id)))
          .get();

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
          'convertedAmount': converted,
          'rateUsed': usedRate,
          'note': note,
          'splitType': splitType,
          'createdAt': now.toIso8601String(),
          'splits': splitRows
              .map((sr) => {
                    'memberId': sr.memberId,
                    'shareAmount': sr.shareAmount,
                    'shareConverted': sr.shareConverted,
                  })
              .toList(),
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

      // Distribute the converted total across members to guarantee
      // sum(shareConverted) == convertedAmount (no rounding drift).
      final baseShares = _distributeBaseCurrency(
        convertedTotal: converted,
        originalSplits: splits,
        currency: currency,
        baseCurrency: baseCurrency,
        rate: usedRate,
      );

      for (var i = 0; i < splits.length; i++) {
        await _db.into(_db.splitRows).insert(SplitRowsCompanion.insert(
              id: _uuid.v4(),
              expenseId: original.id,
              memberId: splits[i].memberId,
              shareAmount: splits[i].amount,
              shareConverted: baseShares[i],
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
          'convertedAmount': converted,
          'rateUsed': usedRate,
          'note': note,
          'splitType': splitType,
          'createdAt': original.createdAt.toIso8601String(),
          'editedAt': now.toIso8601String(),
          'splits': splits
              .map((sp) => {
                    'memberId': sp.memberId,
                    'shareAmount': sp.amount,
                    'shareConverted': baseShares[splits.indexOf(sp)],
                  })
              .toList(),
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

  Future<void> editSettlement({
    required Settlement settlement,
    required String fromMemberId,
    required String toMemberId,
    required double amount,
    String method = '',
    String note = '',
  }) async {
    await _db.transaction(() async {
      await (_db.update(_db.settlements)
            ..where((s) => s.id.equals(settlement.id)))
          .write(SettlementsCompanion(
        fromMemberId: Value(fromMemberId),
        toMemberId: Value(toMemberId),
        amount: Value(amount),
        method: Value(method),
        note: Value(note),
      ));
      await _opLog.append(
        tripId: settlement.tripId,
        opType: 'settlement_edited',
        entityId: settlement.id,
        payload: {
          'id': settlement.id,
          'fromMemberId': fromMemberId,
          'toMemberId': toMemberId,
          'amount': amount,
          'method': method,
          'note': note,
        },
      );
    });
    if (_cloudSync != null) {
      await _cloudSync.pushTripOps(settlement.tripId);
    }
  }

  Future<void> deleteSettlement(Settlement settlement) async {
    await _db.transaction(() async {
      await (_db.update(_db.settlements)
            ..where((s) => s.id.equals(settlement.id)))
          .write(const SettlementsCompanion(deleted: Value(true)));
      await _opLog.append(
        tripId: settlement.tripId,
        opType: 'settlement_deleted',
        entityId: settlement.id,
        payload: {'id': settlement.id, 'deleted': true},
      );
    });
    if (_cloudSync != null) {
      await _cloudSync.pushTripOps(settlement.tripId);
    }
  }

  /// Distributes [convertedTotal] across [originalSplits] members so that
  /// sum(result) == convertedTotal exactly. For same-currency expenses the
  /// distribution is trivial (shares already sum correctly). For foreign-
  /// currency expenses, each member's share is computed proportionally in
  /// the base currency and the last member absorbs any rounding remainder.
  List<double> _distributeBaseCurrency({
    required double convertedTotal,
    required List<SplitInput> originalSplits,
    required String currency,
    required String baseCurrency,
    required double rate,
  }) {
    final n = originalSplits.length;
    if (n == 0) return const [];

    // Same currency: split in base directly (no conversion drift).
    if (currency == baseCurrency) {
      return [for (final s in originalSplits) _r2(s.amount)];
    }

    // Foreign currency: compute each member's share in base currency,
    // then adjust the last member so the total is exact.
    final shares = <double>[];
    var remaining = _r2(convertedTotal);
    for (var i = 0; i < n - 1; i++) {
      final share = _r2(originalSplits[i].amount * rate);
      shares.add(share);
      remaining = _r2(remaining - share);
    }
    // Last member gets whatever is left (absorbs rounding).
    shares.add(_r2(remaining));
    return shares;
  }

  /// Recompute splits for all equal-split expenses when a member is added
  /// or removed. Ensures every equal-split expense includes all active members.
  Future<void> recomputeEqualSplits(String tripId) async {
    // Get trip's base currency.
    final tripRow = await (_db.select(_db.trips)
          ..where((t) => t.id.equals(tripId)))
        .getSingleOrNull();
    final baseCurrency = tripRow?.baseCurrency ?? 'INR';

    // Get all active members.
    final memberRows = await (_db.select(_db.members)
          ..where((m) => m.tripId.equals(tripId) & m.deleted.equals(false)))
        .get();
    final allMemberIds = memberRows.map((m) => m.id).toList();
    if (allMemberIds.isEmpty) return;

    // Get all non-deleted equal-split expenses.
    final expenses = await (_db.select(_db.expenses)
          ..where((e) =>
              e.tripId.equals(tripId) &
              e.deleted.equals(false) &
              e.splitType.equals('equal')))
        .get();

    for (final exp in expenses) {
      // Delete old splits for this expense.
      await (_db.splitRows.delete()
            ..where((s) => s.expenseId.equals(exp.id)))
          .go();

      // Recompute splits with all current members.
      final newSplits = computeSplits(
        amount: exp.amount,
        type: 'equal',
        allMemberIds: allMemberIds,
      );

      // Re-distribute converted amount proportionally.
      final baseShares = _distributeBaseCurrency(
        convertedTotal: exp.convertedAmount,
        originalSplits: newSplits,
        currency: exp.currency,
        baseCurrency: baseCurrency,
        rate: exp.rateUsed,
      );

      for (var i = 0; i < newSplits.length; i++) {
        await _db.into(_db.splitRows).insert(SplitRowsCompanion.insert(
              id: _uuid.v4(),
              expenseId: exp.id,
              memberId: newSplits[i].memberId,
              shareAmount: newSplits[i].amount,
              shareConverted: baseShares[i],
            ));
      }

      // Log the split recomputation as an op so other devices pick it up.
      await _opLog.append(
        tripId: tripId,
        opType: 'expense_corrected',
        entityId: exp.id,
        payload: {
          'id': exp.id,
          'recomputed': true,
        },
      );
    }

    // Push changes to cloud.
    if (_cloudSync != null && expenses.isNotEmpty) {
      await _cloudSync.pushTripOps(tripId);
    }
  }

  static double _r2(double v) => (v * 100).roundToDouble() / 100;
}
