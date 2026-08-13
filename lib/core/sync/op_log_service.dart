import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'device_identity.dart';

class OpLogService {
  OpLogService(this._db, {String? deviceId})
      : deviceId = deviceId ?? DeviceIdentity.forTesting('test').id;

  final AppDatabase _db;
  final String deviceId;

  Future<void> append({
    required String tripId,
    required String opType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    final maxLamport = await (_db.selectOnly(_db.opLogs)
          ..addColumns([_db.opLogs.lamportTs.max()]))
        .getSingleOrNull();
    final currentMax = maxLamport?.read<int>(_db.opLogs.lamportTs.max()) ?? 0;

    final myCount = await (_db.selectOnly(_db.opLogs)
          ..addColumns([_db.opLogs.id.count()])
          ..where(_db.opLogs.authorDevice.equals(deviceId)))
        .getSingleOrNull();
    final currentCount = myCount?.read<int>(_db.opLogs.id.count()) ?? 0;

    await _db.into(_db.opLogs).insert(OpLogsCompanion.insert(
          id: const Uuid().v4(),
          tripId: tripId,
          opType: opType,
          entityId: entityId,
          payload: jsonEncode(payload),
          authorDevice: deviceId,
          lamportTs: currentMax + 1,
          deviceCounter: currentCount + 1,
          createdAt: DateTime.now(),
        ));
  }

  Stream<List<OpLogRow>> watchLog(String tripId) {
    return (_db.select(_db.opLogs)
          ..where((o) => o.tripId.equals(tripId))
          ..orderBy([
            (o) => OrderingTerm.asc(o.lamportTs),
            (o) => OrderingTerm.asc(o.deviceCounter),
          ]))
        .watch();
  }

  Future<List<OpLogRow>> logForTrip(String tripId) {
    return (_db.select(_db.opLogs)
          ..where((o) => o.tripId.equals(tripId))
          ..orderBy([
            (o) => OrderingTerm.asc(o.lamportTs),
            (o) => OrderingTerm.asc(o.deviceCounter),
          ]))
        .get();
  }
}
