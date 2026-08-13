import 'package:drift/drift.dart';

import '../app_database.dart';

part 'trip_dao.g.dart';

@DriftAccessor(tables: [Trips, Members, Categories])
class TripDao extends DatabaseAccessor<AppDatabase> with _$TripDaoMixin {
  TripDao(super.db);

  Stream<List<TripRow>> watchAllTrips() {
    return (select(trips)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<TripRow?> getTrip(String id) async {
    return (select(trips)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<TripRow?> watchTrip(String id) {
    return (select(trips)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<void> insertTrip(TripsCompanion trip) => into(trips).insert(trip);

  Future<void> softDeleteTrip(String id) {
    return (update(trips)..where((t) => t.id.equals(id)))
        .write(const TripsCompanion(deleted: Value(true)));
  }

  Stream<List<MemberRow>> watchMembers(String tripId) {
    return (select(members)
          ..where((m) => m.tripId.equals(tripId) & m.deleted.equals(false))
          ..orderBy([(m) => OrderingTerm.asc(m.joinedAt)]))
        .watch();
  }

  Future<MemberRow?> getMember(String id) async {
    return (select(members)..where((m) => m.id.equals(id))).getSingleOrNull();
  }

  Future<void> insertMember(MembersCompanion member) =>
      into(members).insert(member);

  Future<void> softDeleteMember(String id) {
    return (update(members)..where((m) => m.id.equals(id)))
        .write(const MembersCompanion(deleted: Value(true)));
  }

  Future<MemberRow?> memberByDevice(String tripId, String deviceId) {
    return (select(members)
          ..where((m) =>
              m.tripId.equals(tripId) &
              m.deviceId.equals(deviceId) &
              m.deleted.equals(false)))
        .getSingleOrNull();
  }

  Stream<List<CategoryRow>> watchCategories(String tripId) {
    return (select(categories)
          ..where((c) =>
              c.deleted.equals(false) &
              (c.tripId.equals(tripId) | c.isDefault.equals(true)))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch();
  }

  Future<CategoryRow?> findCategory(String tripId, String name) {
    return (select(categories)
          ..where((c) =>
              c.name.lower().equals(name.toLowerCase()) &
              c.deleted.equals(false) &
              (c.tripId.equals(tripId) | c.isDefault.equals(true))))
        .getSingleOrNull();
  }

  Future<void> insertCategory(CategoriesCompanion cat) =>
      into(categories).insert(cat);
}
