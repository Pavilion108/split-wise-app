// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_dao.dart';

// ignore_for_file: type=lint
mixin _$TripDaoMixin on DatabaseAccessor<AppDatabase> {
  $TripsTable get trips => attachedDatabase.trips;
  $MembersTable get members => attachedDatabase.members;
  $CategoriesTable get categories => attachedDatabase.categories;
  TripDaoManager get managers => TripDaoManager(this);
}

class TripDaoManager {
  final _$TripDaoMixin _db;
  TripDaoManager(this._db);
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db.attachedDatabase, _db.trips);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
}
