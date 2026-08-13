import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../core/sync/op_log_service.dart';
import '../models/models.dart';

class TripRepository {
  TripRepository(this._db, this._opLog);

  final AppDatabase _db;
  final OpLogService _opLog;

  static const _uuid = Uuid();

  // --- Trips ---

  Stream<List<Trip>> watchTrips() {
    return (_db.select(_db.trips)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(Trip.fromRow).toList());
  }

  Future<Trip?> getTrip(String id) async {
    final row = await (_db.select(_db.trips)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : Trip.fromRow(row);
  }

  Stream<Trip?> watchTrip(String id) {
    return (_db.select(_db.trips)
          ..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((r) => r == null ? null : Trip.fromRow(r));
  }

  // --- Members ---

  Stream<List<Member>> watchMembers(String tripId) {
    return (_db.select(_db.members)
          ..where((m) => m.tripId.equals(tripId) & m.deleted.equals(false))
          ..orderBy([(m) => OrderingTerm.asc(m.joinedAt)]))
        .watch()
        .map((rows) => rows.map(Member.fromRow).toList());
  }

  Future<Member?> getMember(String id) async {
    final row = await (_db.select(_db.members)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : Member.fromRow(row);
  }

  // --- Categories ---

  Stream<List<Category>> watchCategories(String tripId) {
    return (_db.select(_db.categories)
          ..where((c) =>
              c.deleted.equals(false) &
              (c.tripId.equals(tripId) | c.isDefault.equals(true)))
          ..orderBy([(c) => OrderingTerm.asc(c.name)]))
        .watch()
        .map((rows) => rows.map(Category.fromRow).toList());
  }

  // --- Mutations ---

  Future<Trip> createTrip({
    required String name,
    required String baseCurrency,
    required String memberName,
    required String deviceId,
  }) async {
    final tripId = _uuid.v4();
    final memberId = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.trips).insert(TripsCompanion.insert(
            id: tripId,
            name: name,
            baseCurrency: Value(baseCurrency),
            createdAt: now,
          ));

      await _db.into(_db.members).insert(MembersCompanion.insert(
            id: memberId,
            tripId: tripId,
            name: memberName,
            deviceId: deviceId,
            joinedAt: now,
          ));

      await _opLog.append(
        tripId: tripId,
        opType: 'trip',
        entityId: tripId,
        payload: {
          'id': tripId,
          'name': name,
          'baseCurrency': baseCurrency,
          'createdAt': now.toIso8601String(),
        },
      );
      await _opLog.append(
        tripId: tripId,
        opType: 'member',
        entityId: memberId,
        payload: {
          'id': memberId,
          'tripId': tripId,
          'name': memberName,
          'deviceId': deviceId,
          'joinedAt': now.toIso8601String(),
        },
      );
    });

    return (await getTrip(tripId))!;
  }

  Future<Member> addMember({
    required String tripId,
    required String name,
    required String deviceId,
    int avatarColor = 0xFF43A047,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.members).insert(MembersCompanion.insert(
            id: id,
            tripId: tripId,
            name: name,
            deviceId: deviceId,
            avatarColor: Value(avatarColor),
            joinedAt: now,
          ));
      await _opLog.append(
        tripId: tripId,
        opType: 'member',
        entityId: id,
        payload: {
          'id': id,
          'tripId': tripId,
          'name': name,
          'deviceId': deviceId,
          'avatarColor': avatarColor,
          'joinedAt': now.toIso8601String(),
        },
      );
    });

    return (await getMember(id))!;
  }

  Future<void> removeMember(String memberId) async {
    final member = await getMember(memberId);
    if (member == null) return;
    await _db.transaction(() async {
      await (_db.update(_db.members)..where((m) => m.id.equals(memberId)))
          .write(const MembersCompanion(deleted: Value(true)));
      await _opLog.append(
        tripId: member.tripId,
        opType: 'member',
        entityId: memberId,
        payload: {'id': memberId, 'deleted': true},
      );
    });
  }

  Future<Category> rememberCategory(String tripId, String name) async {
    final existing = await (_db.select(_db.categories)
          ..where((c) =>
              c.name.lower().equals(name.toLowerCase()) &
              c.deleted.equals(false) &
              (c.tripId.equals(tripId) | c.isDefault.equals(true))))
        .getSingleOrNull();

    if (existing != null) return Category.fromRow(existing);

    final id = _uuid.v4();
    await _db.transaction(() async {
      await _db.into(_db.categories).insert(CategoriesCompanion.insert(
            id: id,
            name: name,
            tripId: Value(tripId),
          ));
      await _opLog.append(
        tripId: tripId,
        opType: 'category',
        entityId: id,
        payload: {
          'id': id,
          'tripId': tripId,
          'name': name,
          'isDefault': false,
        },
      );
    });

    final row = await (_db.select(_db.categories)
          ..where((c) =>
              c.name.lower().equals(name.toLowerCase()) &
              c.tripId.equals(tripId)))
        .getSingleOrNull();
    return Category.fromRow(row!);
  }
}
