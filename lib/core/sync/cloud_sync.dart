import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import 'sync_service.dart';

/// Cloud sync transport using Firebase Realtime Database.
/// Works on ANY network — same WiFi, mobile data, different countries.
///
/// Firebase RTDB structure:
///   trips/{tripId}/meta    — trip name, currency, inviteCode
///   trips/{tripId}/members — member list
///   trips/{tripId}/ops     — CRDT op-log (all mutations)
///   invite_codes/{code}    — maps invite code → tripId (for lookup)
class CloudSyncService {
  CloudSyncService(this._syncService, this._deviceId, [this._userId]);

  final SyncService _syncService;
  final String _deviceId;
  final String? _userId;

  final _db = FirebaseDatabase.instance;
  final _statusController = StreamController<CloudSyncStatus>.broadcast();
  Stream<CloudSyncStatus> get status => _statusController.stream;

  // ---------------------------------------------------------------------------
  // Push: upload local ops to cloud
  // ---------------------------------------------------------------------------

  /// Push all local ops for [tripId] to Firebase.
  Future<int> pushTripOps(String tripId) async {
    final payload = await _syncService.buildPayload(tripId);
    if (payload.ops.isEmpty) return 0;

    final opsRef = _db.ref('trips/$tripId/ops');
    var pushed = 0;

    for (final op in payload.ops) {
      await opsRef.child(op.id).set(op.toJson());
      pushed++;
    }

    _statusController.add(CloudSyncStatus(
      tripId: tripId,
      lastSync: DateTime.now(),
      opsPushed: pushed,
    ));

    return pushed;
  }

  /// Push trip metadata to cloud (called on create).
  Future<void> pushTripMeta({
    required String tripId,
    required String name,
    required String baseCurrency,
    required String inviteCode,
    required DateTime createdAt,
    String driveFolderId = '',
    String driveFolderLink = '',
    String whatsappGroupLink = '',
  }) async {
    final metaRef = _db.ref('trips/$tripId/meta');
    await metaRef.set({
      'id': tripId,
      'name': name,
      'baseCurrency': baseCurrency,
      'inviteCode': inviteCode,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': _deviceId,
      if (driveFolderId.isNotEmpty) 'driveFolderId': driveFolderId,
      if (driveFolderLink.isNotEmpty) 'driveFolderLink': driveFolderLink,
      if (whatsappGroupLink.isNotEmpty) 'whatsappGroupLink': whatsappGroupLink,
    });

    // Index invite code → tripId for lookup.
    final codeRef = _db.ref('invite_codes/$inviteCode');
    await codeRef.set({'tripId': tripId});
  }

  /// Update trip metadata (e.g., after Drive folder is created).
  Future<void> updateTripMeta({
    required String tripId,
    Map<String, dynamic> updates = const {},
  }) async {
    final metaRef = _db.ref('trips/$tripId/meta');
    await metaRef.update(updates);
  }

  /// Pull trip metadata from cloud.
  Future<Map<String, dynamic>?> pullTripMeta(String tripId) async {
    final metaRef = _db.ref('trips/$tripId/meta');
    final snapshot = await metaRef.get();
    if (!snapshot.exists || snapshot.value == null) return null;
    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  /// Push member info to cloud (called on join).
  Future<void> pushMember({
    required String tripId,
    required String memberId,
    required String name,
    required String deviceId,
    required DateTime joinedAt,
  }) async {
    final memberRef = _db.ref('trips/$tripId/members/$memberId');
    await memberRef.set({
      'id': memberId,
      'tripId': tripId,
      'name': name,
      'deviceId': deviceId,
      'joinedAt': joinedAt.toIso8601String(),
    });

    if (_userId != null) {
      await _db.ref('users/$_userId/trips/$tripId').set(true);
    }
    await _db.ref('devices/$_deviceId/trips/$tripId').set(true);
  }

  /// Restores all trips this user/device is a member of.
  Future<int> restoreTrips() async {
    final refs = <String>[];
    if (_userId != null) refs.add('users/$_userId/trips');
    refs.add('devices/$_deviceId/trips');

    int restored = 0;
    for (final r in refs) {
      final snap = await _db.ref(r).get();
      if (snap.exists && snap.value != null) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        for (final tripId in map.keys) {
          final count = await pullAllOps(tripId);
          if (count > 0) restored++;
        }
      }
    }
    return restored;
  }

  // ---------------------------------------------------------------------------
  // Pull: download remote ops from cloud
  // ---------------------------------------------------------------------------

  /// Look up tripId by invite code.
  Future<String?> lookupTripByCode(String code) async {
    final codeRef = _db.ref('invite_codes/${code.toUpperCase()}');
    final snapshot = await codeRef.get();
    if (!snapshot.exists || snapshot.value == null) return null;
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    return data['tripId'] as String?;
  }

  /// Pull full trip state from cloud by invite code.
  /// Returns the trip ID if found, null otherwise.
  /// After pulling, all remote ops are applied to local DB.
  Future<String?> pullTripByCode(String inviteCode) async {
    final code = inviteCode.toUpperCase().trim();
    final tripId = await lookupTripByCode(code);
    if (tripId == null) return null;

    await pullAllOps(tripId);
    return tripId;
  }

  /// Pull all ops for [tripId] from cloud and apply locally.
  Future<int> pullAllOps(String tripId) async {
    final opsRef = _db.ref('trips/$tripId/ops');
    final snapshot = await opsRef.get();
    if (!snapshot.exists || snapshot.value == null) return 0;

    final opsData = Map<String, dynamic>.from(snapshot.value as Map);
    var applied = 0;

    for (final entry in opsData.entries) {
      final opData = Map<String, dynamic>.from(entry.value as Map);
      final op = _parseOp(opData);
      if (op == null) continue;

      final payload = SyncPayload(
        tripId: tripId,
        deviceId: op.authorDevice,
        ops: [op],
        timestamp: op.createdAt,
      );
      final count = await _syncService.processPayload(payload);
      applied += count;
    }

    if (applied > 0) {
      _statusController.add(CloudSyncStatus(
        tripId: tripId,
        lastSync: DateTime.now(),
        opsPulled: applied,
      ));
    }

    return applied;
  }

  /// Pull only ops newer than [afterTs] for incremental sync.
  Future<int> pullNewOps(String tripId, {int afterTs = 0}) async {
    final opsRef = _db.ref('trips/$tripId/ops');
    final snapshot = await opsRef.get();
    if (!snapshot.exists || snapshot.value == null) return 0;

    final opsData = Map<String, dynamic>.from(snapshot.value as Map);
    var applied = 0;

    for (final entry in opsData.entries) {
      final opData = Map<String, dynamic>.from(entry.value as Map);
      final lamportTs = opData['lamportTs'] as int? ?? 0;
      if (lamportTs <= afterTs) continue;

      final op = _parseOp(opData);
      if (op == null) continue;

      final payload = SyncPayload(
        tripId: tripId,
        deviceId: op.authorDevice,
        ops: [op],
        timestamp: op.createdAt,
      );
      final count = await _syncService.processPayload(payload);
      applied += count;
    }

    return applied;
  }

  SyncOp? _parseOp(Map<String, dynamic> data) {
    try {
      return SyncOp.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Listen: real-time updates from cloud
  // ---------------------------------------------------------------------------

  /// Listen for new ops on a trip (real-time via Firebase).
  Stream<SyncEvent> listenForOps(String tripId) {
    final controller = StreamController<SyncEvent>.broadcast();
    final opsRef = _db.ref('trips/$tripId/ops');

    opsRef.onChildAdded.listen((event) {
      if (event.snapshot.value == null) return;
      final opData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final op = _parseOp(opData);
      if (op == null) return;

      // Skip ops from this device (we already have them).
      if (op.authorDevice == _deviceId) return;

      final payload = SyncPayload(
        tripId: tripId,
        deviceId: op.authorDevice,
        ops: [op],
        timestamp: op.createdAt,
      );

      _syncService.processPayload(payload).then((count) {
        if (count > 0) {
          controller.add(SyncEvent(
            type: SyncEventType.synced,
            tripId: tripId,
            opsApplied: count,
          ));
        }
      });
    });

    return controller.stream;
  }

  // ---------------------------------------------------------------------------
  // Full sync: push + pull
  // ---------------------------------------------------------------------------

  /// Full bidirectional sync for a trip.
  Future<CloudSyncResult> fullSync(String tripId) async {
    try {
      final pushed = await pushTripOps(tripId);
      final pulled = await pullAllOps(tripId);

      return CloudSyncResult(
        success: true,
        tripId: tripId,
        opsPushed: pushed,
        opsPulled: pulled,
      );
    } catch (e) {
      return CloudSyncResult(
        success: false,
        tripId: tripId,
        error: e.toString(),
      );
    }
  }

  void dispose() {
    _statusController.close();
  }
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class CloudSyncStatus {
  const CloudSyncStatus({
    required this.tripId,
    required this.lastSync,
    this.opsPushed = 0,
    this.opsPulled = 0,
  });

  final String tripId;
  final DateTime lastSync;
  final int opsPushed;
  final int opsPulled;
}

class CloudSyncResult {
  const CloudSyncResult({
    required this.success,
    required this.tripId,
    this.opsPushed = 0,
    this.opsPulled = 0,
    this.error,
  });

  final bool success;
  final String tripId;
  final int opsPushed;
  final int opsPulled;
  final String? error;
}
