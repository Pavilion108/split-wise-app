import 'package:drift/drift.dart';

import '../app_database.dart';

part 'expense_dao.g.dart';

@DriftAccessor(tables: [Expenses, SplitRows, Settlements])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  Stream<List<ExpenseRow>> watchExpenses(String tripId) {
    return (select(expenses)
          ..where((e) => e.tripId.equals(tripId) & e.deleted.equals(false))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .watch();
  }

  Future<ExpenseRow?> getExpense(String id) async {
    return (select(expenses)..where((e) => e.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> insertExpense(ExpensesCompanion expense) =>
      into(expenses).insert(expense);

  Future<void> updateExpense(String id, ExpensesCompanion data) {
    return (update(expenses)..where((e) => e.id.equals(id))).write(data);
  }

  Future<void> softDeleteExpense(String id) {
    return (update(expenses)..where((e) => e.id.equals(id)))
        .write(const ExpensesCompanion(deleted: Value(true)));
  }

  Future<void> deleteSplitsForExpense(String expenseId) {
    return (delete(splitRows)..where((s) => s.expenseId.equals(expenseId)))
        .go();
  }

  Future<void> insertSplits(List<SplitRowsCompanion> splits) async {
    await batch((b) {
      b.insertAll(splitRows, splits, mode: InsertMode.insertOrReplace);
    });
  }

  Stream<List<SplitRow>> watchSplitsForTrip(String tripId) {
    final subquery = selectOnly(expenses)
      ..addColumns([expenses.id])
      ..where(expenses.tripId.equals(tripId));
    return (select(splitRows)
          ..where((s) => s.expenseId.isInQuery(subquery)))
        .watch();
  }

  Future<List<SplitRow>> splitsForTrip(String tripId) async {
    final expenseIds = (await (select(expenses)
              ..where((e) =>
                  e.tripId.equals(tripId) & e.deleted.equals(false)))
            .get())
        .map((e) => e.id)
        .toList();
    if (expenseIds.isEmpty) return [];
    return (select(splitRows)
          ..where((s) => s.expenseId.isIn(expenseIds)))
        .get();
  }

  Stream<List<SettlementRow>> watchSettlements(String tripId) {
    return (select(settlements)
          ..where((s) => s.tripId.equals(tripId) & s.deleted.equals(false))
          ..orderBy([(s) => OrderingTerm.desc(s.paidAt)]))
        .watch();
  }

  Future<void> insertSettlement(SettlementsCompanion settlement) =>
      into(settlements).insert(settlement);

  Future<List<SettlementRow>> settlementsForTrip(String tripId) {
    return (select(settlements)
          ..where((s) => s.tripId.equals(tripId) & s.deleted.equals(false)))
        .get();
  }
}
