// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_dao.dart';

// ignore_for_file: type=lint
mixin _$ExpenseDaoMixin on DatabaseAccessor<AppDatabase> {
  $TripsTable get trips => attachedDatabase.trips;
  $MembersTable get members => attachedDatabase.members;
  $ExpensesTable get expenses => attachedDatabase.expenses;
  $SplitRowsTable get splitRows => attachedDatabase.splitRows;
  $SettlementsTable get settlements => attachedDatabase.settlements;
  ExpenseDaoManager get managers => ExpenseDaoManager(this);
}

class ExpenseDaoManager {
  final _$ExpenseDaoMixin _db;
  ExpenseDaoManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db.attachedDatabase, _db.trips);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db.attachedDatabase, _db.expenses);
  $$SplitRowsTableTableManager get splitRows =>
      $$SplitRowsTableTableManager(_db.attachedDatabase, _db.splitRows);
  $$SettlementsTableTableManager get settlements =>
      $$SettlementsTableTableManager(_db.attachedDatabase, _db.settlements);
}
