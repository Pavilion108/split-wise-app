import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';

/// Orchestrates sync across all transports: WiFi, BLE, QR.
/// Each transport calls [processSyncPayload] when it receives data.
class SyncService {
  SyncService(this._db, this._deviceId);

  final AppDatabase _db;
  final String _deviceId;

  final _syncControllers = <String, StreamController<SyncEvent>>{};
  final _statusController = StreamController<SyncStatus>.broadcast();

  Stream<SyncStatus> get status => _statusController.stream;

  /// Get or create a sync event stream for a trip.
  Stream<SyncEvent> eventsFor(String tripId) {
    return _syncControllers
        .putIfAbsent(tripId, () => StreamController<SyncEvent>.broadcast())
        .stream;
  }

  /// Build a sync payload: all ops after [afterTs] for [tripId].
  Future<SyncPayload> buildPayload(
    String tripId, {
    int afterTs = 0,
  }) async {
    final ops = await (_db.select(_db.opLogs)
          ..where((o) =>
              o.tripId.equals(tripId) & o.lamportTs.isBiggerOrEqualValue(afterTs))
          ..orderBy([
            (o) => OrderingTerm.asc(o.lamportTs),
            (o) => OrderingTerm.asc(o.deviceCounter),
          ]))
        .get();

    return SyncPayload(
      tripId: tripId,
      deviceId: _deviceId,
      ops: ops
          .map((o) => SyncOp(
                id: o.id,
                opType: o.opType,
                entityId: o.entityId,
                payload: o.payload,
                authorDevice: o.authorDevice,
                lamportTs: o.lamportTs,
                deviceCounter: o.deviceCounter,
                createdAt: o.createdAt,
              ))
          .toList(),
      timestamp: DateTime.now(),
    );
  }

  /// Apply received sync payload to local database.
  /// Returns the number of new ops applied.
  Future<SyncResult> processPayload(SyncPayload payload) async {
    var applied = 0;
    var memberAdded = false;
    String? memberAddedTripId;

    await _db.transaction(() async {
      for (final op in payload.ops) {
        // Skip if we already have this op (idempotent).
        final existing = await (_db.select(_db.opLogs)
              ..where((o) => o.id.equals(op.id)))
            .getSingleOrNull();
        if (existing != null) continue;

        await _db.into(_db.opLogs).insert(OpLogsCompanion(
              id: Value(op.id),
              tripId: Value(payload.tripId),
              opType: Value(op.opType),
              entityId: Value(op.entityId),
              payload: Value(op.payload),
              authorDevice: Value(op.authorDevice),
              lamportTs: Value(op.lamportTs),
              deviceCounter: Value(op.deviceCounter),
              createdAt: Value(op.createdAt),
            ));

        // Apply the operation to the actual table.
        await _applyOp(payload.tripId, op);
        applied++;

        if (op.opType == 'member') {
          memberAdded = true;
          memberAddedTripId = payload.tripId;
        }
      }
    });

    if (applied > 0) {
      _statusController.add(SyncStatus(
        tripId: payload.tripId,
        lastSync: DateTime.now(),
        syncedOps: applied,
        remoteDevice: payload.deviceId,
      ));

      _syncControllers[payload.tripId]?.add(SyncEvent(
        type: SyncEventType.synced,
        tripId: payload.tripId,
        opsApplied: applied,
      ));
    }

    return SyncResult(opsApplied: applied, memberAdded: memberAdded, tripId: memberAddedTripId);
  }

  /// Build a compact summary for sync negotiation.
  Future<SyncSummary> buildSummary(String tripId) async {
    final maxTs = await (_db.selectOnly(_db.opLogs)
          ..addColumns([_db.opLogs.lamportTs.max()])
          ..where(_db.opLogs.tripId.equals(tripId)))
        .getSingleOrNull();
    final lastTs = maxTs?.read<int>(_db.opLogs.lamportTs.max()) ?? 0;

    final myCount = await (_db.selectOnly(_db.opLogs)
          ..addColumns([_db.opLogs.id.count()])
          ..where(_db.opLogs.tripId.equals(tripId) &
              _db.opLogs.authorDevice.equals(_deviceId)))
        .getSingleOrNull();
    final totalOps = myCount?.read<int>(_db.opLogs.id.count()) ?? 0;

    return SyncSummary(
      tripId: tripId,
      deviceId: _deviceId,
      maxLamportTs: lastTs,
      opCount: totalOps,
    );
  }

  Future<void> _applyOp(String tripId, SyncOp op) async {
    final payload = jsonDecode(op.payload) as Map<String, dynamic>;

    switch (op.opType) {
      case 'trip':
        await _applyTripOp(tripId, payload);
        break;
      case 'member':
        await _applyMemberOp(tripId, payload);
        break;
      case 'expense':
      case 'expense_corrected':
        await _applyExpenseOp(tripId, payload);
        break;
      case 'settlement':
        await _applySettlementOp(tripId, payload);
        break;
      case 'settlement_edited':
        await _applySettlementEditedOp(tripId, payload);
        break;
      case 'settlement_deleted':
        await _applyDeleteOp(op.opType, payload);
        break;
      case 'category':
        await _applyCategoryOp(tripId, payload);
        break;
      case 'trip_status':
        await _applyTripStatusOp(tripId, payload);
        break;
      case 'trip_meta':
        await _applyTripMetaOp(tripId, payload);
        break;
      case 'expense_deleted':
      case 'member_deleted':
      case 'trip_deleted':
        await _applyDeleteOp(op.opType, payload);
        break;
    }
  }

  Future<void> _applyTripOp(String tripId, Map<String, dynamic> p) async {
    final existing = await (_db.select(_db.trips)
          ..where((t) => t.id.equals(tripId)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.trips).insert(TripsCompanion(
            id: Value(tripId),
            name: Value(p['name'] ?? ''),
            baseCurrency: Value(p['baseCurrency'] ?? 'INR'),
            createdAt: Value(DateTime.parse(p['createdAt'])),
          ));
    }
  }

  Future<void> _applyMemberOp(String tripId, Map<String, dynamic> p) async {
    final id = p['id'] as String;
    final deleted = p['deleted'] == true;
    final googleId = p['googleId'] as String? ?? '';
    final emailLower = p['emailLower'] as String? ?? '';

    // Try to find existing member by id, googleId, or emailLower.
    var existing = await (_db.select(_db.members)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();

    if (existing == null && googleId.isNotEmpty) {
      existing = await (_db.select(_db.members)
            ..where((m) =>
                m.tripId.equals(tripId) &
                m.googleId.equals(googleId) &
                m.deleted.equals(false)))
          .getSingleOrNull();
    }
    if (existing == null && emailLower.isNotEmpty) {
      existing = await (_db.select(_db.members)
            ..where((m) =>
                m.tripId.equals(tripId) &
                m.emailLower.equals(emailLower) &
                m.deleted.equals(false)))
          .getSingleOrNull();
    }

    if (existing == null && !deleted) {
      await _db.into(_db.members).insert(MembersCompanion(
            id: Value(id),
            tripId: Value(tripId),
            name: Value(p['name'] ?? ''),
            deviceId: Value(p['deviceId'] ?? ''),
            avatarColor: Value(p['avatarColor'] ?? 0xFF1E88E5),
            avatarAsset: Value(p['avatarAsset'] ?? ''),
            googleId: Value(googleId),
            emailLower: Value(emailLower),
            joinedAt: Value(DateTime.parse(p['joinedAt'])),
          ));
    } else if (existing != null) {
      final existingId = existing.id;
      if (deleted) {
        await (_db.update(_db.members)..where((m) => m.id.equals(existingId)))
            .write(const MembersCompanion(deleted: Value(true)));
      } else {
        // update avatar / identity if changed
        await (_db.update(_db.members)..where((m) => m.id.equals(existingId))).write(
          MembersCompanion(
            avatarAsset: p['avatarAsset'] != null ? Value(p['avatarAsset'] as String) : const Value.absent(),
            googleId: googleId.isNotEmpty ? Value(googleId) : const Value.absent(),
            emailLower: emailLower.isNotEmpty ? Value(emailLower) : const Value.absent(),
            avatarColor: p['avatarColor'] != null ? Value(p['avatarColor'] as int) : const Value.absent(),
            name: p['name'] != null ? Value(p['name'] as String) : const Value.absent(),
          ),
        );
      }
    }
  }

  Future<void> _applyExpenseOp(String tripId, Map<String, dynamic> p) async {
    final id = p['id'] as String;
    final existing = await (_db.select(_db.expenses)
          ..where((e) => e.id.equals(id)))
        .getSingleOrNull();

    if (existing == null) {
      // New expense — insert + splits atomically.
      await _db.transaction(() async {
        await _db.into(_db.expenses).insert(ExpensesCompanion(
              id: Value(id),
              tripId: Value(tripId),
              authorId: Value(p['authorId'] ?? ''),
              category: Value(p['category'] ?? ''),
              amount: Value((p['amount'] as num?)?.toDouble() ?? 0),
              currency: Value(p['currency'] ?? 'INR'),
              convertedAmount:
                  Value((p['convertedAmount'] as num?)?.toDouble() ?? 0),
              rateUsed: Value((p['rateUsed'] as num?)?.toDouble() ?? 1),
              note: Value(p['note'] ?? ''),
              splitType: Value(p['splitType'] ?? 'equal'),
              createdAt: Value(DateTime.parse(p['createdAt'])),
            ));

        // Apply split rows from the payload.
        final splitsRaw = p['splits'] as List?;
        if (splitsRaw != null && splitsRaw.isNotEmpty) {
          for (final s in splitsRaw) {
            final sm = Map<String, dynamic>.from(s as Map);
            await _db.into(_db.splitRows).insert(SplitRowsCompanion.insert(
                  id: const Uuid().v4(),
                  expenseId: id,
                  memberId: sm['memberId'] as String,
                  shareAmount: (sm['shareAmount'] as num?)?.toDouble() ?? 0,
                  shareConverted:
                      (sm['shareConverted'] as num?)?.toDouble() ?? 0,
                ));
          }
        }
      });
    } else {
      // Existing expense — update atomically within a transaction
      // so the balance engine doesn't recompute with stale splits.
      await _db.transaction(() async {
        await (_db.update(_db.expenses)..where((e) => e.id.equals(id))).write(
          ExpensesCompanion(
            amount: p['amount'] != null ? Value((p['amount'] as num).toDouble()) : const Value.absent(),
            currency: p['currency'] != null ? Value(p['currency'] as String) : const Value.absent(),
            convertedAmount: p['convertedAmount'] != null ? Value((p['convertedAmount'] as num).toDouble()) : const Value.absent(),
            rateUsed: p['rateUsed'] != null ? Value((p['rateUsed'] as num).toDouble()) : const Value.absent(),
            note: p['note'] != null ? Value(p['note'] as String) : const Value.absent(),
            splitType: p['splitType'] != null ? Value(p['splitType'] as String) : const Value.absent(),
            category: p['category'] != null ? Value(p['category'] as String) : const Value.absent(),
            editedAt: Value(DateTime.now()),
          ),
        );

        // Apply split rows inside the same transaction.
        final splitsRaw = p['splits'] as List?;
        if (splitsRaw != null && splitsRaw.isNotEmpty) {
          await (_db.splitRows.delete()..where((s) => s.expenseId.equals(id))).go();
          for (final s in splitsRaw) {
            final sm = Map<String, dynamic>.from(s as Map);
            await _db.into(_db.splitRows).insert(SplitRowsCompanion.insert(
                  id: const Uuid().v4(),
                  expenseId: id,
                  memberId: sm['memberId'] as String,
                  shareAmount: (sm['shareAmount'] as num?)?.toDouble() ?? 0,
                  shareConverted:
                      (sm['shareConverted'] as num?)?.toDouble() ?? 0,
                ));
          }
        }
      });
    }
  }

  Future<void> _applySettlementOp(
      String tripId, Map<String, dynamic> p) async {
    final id = p['id'] as String;
    final existing = await (_db.select(_db.settlements)
          ..where((s) => s.id.equals(id)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.settlements).insert(SettlementsCompanion(
            id: Value(id),
            tripId: Value(tripId),
            fromMemberId: Value(p['fromMemberId'] ?? ''),
            toMemberId: Value(p['toMemberId'] ?? ''),
            amount: Value((p['amount'] as num?)?.toDouble() ?? 0),
            paidAt: Value(DateTime.parse(p['paidAt'])),
          ));
    }
  }

  Future<void> _applyCategoryOp(String tripId, Map<String, dynamic> p) async {
    final id = p['id'] as String;
    final existing = await (_db.select(_db.categories)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.categories).insert(CategoriesCompanion(
            id: Value(id),
            name: Value(p['name'] ?? ''),
            tripId: Value(p['tripId'] as String?),
            isDefault: Value(p['isDefault'] == true),
          ));
    }
  }

  Future<void> _applyTripStatusOp(String tripId, Map<String, dynamic> p) async {
    final status = p['status'] as String? ?? 'active';
    final completedAtStr = p['completedAt'] as String?;
    await (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(
        status: Value(status),
        completedAt: completedAtStr != null
            ? Value(DateTime.parse(completedAtStr))
            : const Value.absent(),
      ),
    );
  }

  Future<void> _applyTripMetaOp(String tripId, Map<String, dynamic> p) async {
    await (_db.update(_db.trips)..where((t) => t.id.equals(tripId))).write(
      TripsCompanion(
        whatsappGroupLink: p['whatsappGroupLink'] != null
            ? Value(p['whatsappGroupLink'] as String)
            : const Value.absent(),
        driveFolderId: p['driveFolderId'] != null
            ? Value(p['driveFolderId'] as String)
            : const Value.absent(),
        driveFolderLink: p['driveFolderLink'] != null
            ? Value(p['driveFolderLink'] as String)
            : const Value.absent(),
      ),
    );
  }

  Future<void> _applyDeleteOp(String opType, Map<String, dynamic> p) async {
    final id = p['id'] as String?;
    if (id == null) return;

    if (opType == 'expense_deleted') {
      await (_db.update(_db.expenses)..where((e) => e.id.equals(id)))
          .write(const ExpensesCompanion(deleted: Value(true)));
    } else if (opType == 'member_deleted') {
      await (_db.update(_db.members)..where((m) => m.id.equals(id)))
          .write(const MembersCompanion(deleted: Value(true)));
    } else if (opType == 'trip_deleted') {
      await (_db.update(_db.trips)..where((t) => t.id.equals(id)))
          .write(const TripsCompanion(deleted: Value(true)));
    } else if (opType == 'settlement_deleted') {
      await (_db.update(_db.settlements)..where((s) => s.id.equals(id)))
          .write(const SettlementsCompanion(deleted: Value(true)));
    }
  }

  Future<void> _applySettlementEditedOp(String tripId, Map<String, dynamic> p) async {
    final id = p['id'] as String;
    await (_db.update(_db.settlements)..where((s) => s.id.equals(id))).write(
      SettlementsCompanion(
        fromMemberId: p['fromMemberId'] != null ? Value(p['fromMemberId'] as String) : const Value.absent(),
        toMemberId: p['toMemberId'] != null ? Value(p['toMemberId'] as String) : const Value.absent(),
        amount: p['amount'] != null ? Value((p['amount'] as num).toDouble()) : const Value.absent(),
        method: p['method'] != null ? Value(p['method'] as String) : const Value.absent(),
        note: p['note'] != null ? Value(p['note'] as String) : const Value.absent(),
      ),
    );
  }

  void dispose() {
    for (final c in _syncControllers.values) {
      c.close();
    }
    _statusController.close();
  }
}

/// Result of processing a sync payload.
class SyncResult {
  const SyncResult({
    required this.opsApplied,
    required this.memberAdded,
    this.tripId,
  });
  final int opsApplied;
  final bool memberAdded;
  final String? tripId;
}

class SyncPayload {
  const SyncPayload({
    required this.tripId,
    required this.deviceId,
    required this.ops,
    required this.timestamp,
  });

  final String tripId;
  final String deviceId;
  final List<SyncOp> ops;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'deviceId': deviceId,
        'ops': ops.map((o) => o.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
      };

  factory SyncPayload.fromJson(Map<String, dynamic> json) => SyncPayload(
        tripId: json['tripId'] as String,
        deviceId: json['deviceId'] as String,
        ops: (json['ops'] as List).map((o) => SyncOp.fromJson(o)).toList(),
        timestamp: DateTime.parse(json['timestamp']),
      );

  String encode() => jsonEncode(toJson());
  static SyncPayload decode(String data) =>
      SyncPayload.fromJson(jsonDecode(data));
}

class SyncOp {
  const SyncOp({
    required this.id,
    required this.opType,
    required this.entityId,
    required this.payload,
    required this.authorDevice,
    required this.lamportTs,
    required this.deviceCounter,
    required this.createdAt,
  });

  final String id;
  final String opType;
  final String entityId;
  final String payload;
  final String authorDevice;
  final int lamportTs;
  final int deviceCounter;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'opType': opType,
        'entityId': entityId,
        'payload': payload,
        'authorDevice': authorDevice,
        'lamportTs': lamportTs,
        'deviceCounter': deviceCounter,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SyncOp.fromJson(Map<String, dynamic> json) => SyncOp(
        id: json['id'],
        opType: json['opType'],
        entityId: json['entityId'],
        payload: json['payload'],
        authorDevice: json['authorDevice'],
        lamportTs: json['lamportTs'],
        deviceCounter: json['deviceCounter'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class SyncSummary {
  const SyncSummary({
    required this.tripId,
    required this.deviceId,
    required this.maxLamportTs,
    required this.opCount,
  });

  final String tripId;
  final String deviceId;
  final int maxLamportTs;
  final int opCount;

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'deviceId': deviceId,
        'maxLamportTs': maxLamportTs,
        'opCount': opCount,
      };

  factory SyncSummary.fromJson(Map<String, dynamic> json) => SyncSummary(
        tripId: json['tripId'],
        deviceId: json['deviceId'],
        maxLamportTs: json['maxLamportTs'],
        opCount: json['opCount'],
      );
}

class SyncEvent {
  const SyncEvent({
    required this.type,
    required this.tripId,
    this.opsApplied = 0,
  });

  final SyncEventType type;
  final String tripId;
  final int opsApplied;
}

enum SyncEventType { discovered, syncing, synced, error }

class SyncStatus {
  const SyncStatus({
    required this.tripId,
    required this.lastSync,
    required this.syncedOps,
    required this.remoteDevice,
  });

  final String tripId;
  final DateTime lastSync;
  final int syncedOps;
  final String remoteDevice;
}
