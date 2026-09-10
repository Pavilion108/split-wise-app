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

  /// Callback invoked when a remote member add is detected.
  /// The app layer provides this to recompute splits.
  void Function(String tripId)? onMemberAdded;

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
    String avatarAsset = '',
    String googleId = '',
    String emailLower = '',
    int avatarColor = 0xFF1E88E5,
  }) async {
    final memberRef = _db.ref('trips/$tripId/members/$memberId');
    await memberRef.set({
      'id': memberId,
      'tripId': tripId,
      'name': name,
      'deviceId': deviceId,
      'joinedAt': joinedAt.toIso8601String(),
      if (avatarAsset.isNotEmpty) 'avatarAsset': avatarAsset,
      if (googleId.isNotEmpty) 'googleId': googleId,
      if (emailLower.isNotEmpty) 'emailLower': emailLower,
      'avatarColor': avatarColor,
    });

    if (_userId != null) {
      await _db.ref('users/$_userId/trips/$tripId').set(true);
    }
    await _db.ref('devices/$_deviceId/trips/$tripId').set(true);
  }

  // --- User directory (Option 2) ---

  Future<void> upsertUserProfile({
    required String googleId,
    required String email,
    required String displayName,
    String photoUrl = '',
    String avatarAsset = '',
    bool searchable = true,
  }) async {
    final lower = email.toLowerCase().trim();
    final usernameLower = displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '').trim();
    await _db.ref('users/$googleId/profile').set({
      'googleId': googleId,
      'email': email,
      'emailLower': lower,
      'displayName': displayName,
      'usernameLower': usernameLower,
      'photoUrl': photoUrl,
      'avatarAsset': avatarAsset,
      'searchable': searchable,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    if (searchable) {
      await _db.ref('directory/$googleId').set({
        'googleId': googleId,
        'displayName': displayName,
        'usernameLower': usernameLower,
        'emailLower': lower,
        'avatarAsset': avatarAsset,
        'photoUrl': photoUrl,
      });
    } else {
      await _db.ref('directory/$googleId').remove();
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query, {int limit = 10}) async {
    final q = query.toLowerCase().trim();
    if (q.length < 2) return [];
    final snap = await _db.ref('directory').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final results = <Map<String, dynamic>>[];
    for (final e in map.entries) {
      final v = Map<String, dynamic>.from(e.value as Map);
      final uname = (v['usernameLower'] ?? '') as String;
      final emailL = (v['emailLower'] ?? '') as String;
      final display = (v['displayName'] ?? '').toString().toLowerCase();
      final emailMatch = emailL.contains(q) || emailL.startsWith(q);
      final nameMatch = uname.startsWith(q) || uname.contains(q) || display.startsWith(q) || display.contains(q);
      if (emailMatch || nameMatch) {
        // mask email for privacy
        final email = v['emailLower'] as String? ?? '';
        v['emailMasked'] = email.isNotEmpty ? email.replaceRange(1, email.indexOf('@'), '*' * 3) : '';
        results.add(v);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  Future<void> sendInvite({
    required String tripId,
    required String invitedGoogleId,
    required String invitedEmail,
    required String tripName,
    String memberName = '',
    String memberId = '',
  }) async {
    // 1. Write invite notification (so the user sees it in their inbox).
    if (invitedGoogleId.isNotEmpty) {
      await _db.ref('invites/$invitedGoogleId/$tripId').set({
        'tripId': tripId,
        'tripName': tripName,
        'fromDevice': _deviceId,
        'fromUser': _userId,
        'invitedEmail': invitedEmail,
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      });

      // 2. Register this trip under the invited user's path so restoreTrips()
      //    picks it up when they log in — even before they accept the invite.
      await _db.ref('users/$invitedGoogleId/trips/$tripId').set(true);
    }

    // 3. Also register under email path so users added by email can find the trip.
    if (invitedEmail.isNotEmpty) {
      final emailKey = invitedEmail.toLowerCase().replaceAll('.', '_dot_').replaceAll('@', '_at_');
      await _db.ref('email_trips/$emailKey/$tripId').set(true);
    }
  }

  Stream<Map<String, dynamic>> watchInvites(String googleId) {
    return _db.ref('invites/$googleId').onValue.map((e) {
      if (e.snapshot.value == null) return <String, dynamic>{};
      return Map<String, dynamic>.from(e.snapshot.value as Map);
    });
  }

  Future<void> respondInvite({required String googleId, required String tripId, required bool accept}) async {
    await _db.ref('invites/$googleId/$tripId/status').set(accept ? 'accepted' : 'declined');
    if (!accept) {
      await Future.delayed(const Duration(seconds: 1));
      await _db.ref('invites/$googleId/$tripId').remove();
    }
  }

  /// Restores all trips this user/device is a member of.
  Future<int> restoreTrips() async {
    final refs = <String>[];
    if (_userId != null) refs.add('users/$_userId/trips');
    refs.add('devices/$_deviceId/trips');

    final tripIds = <String>{};
    for (final r in refs) {
      final snap = await _db.ref(r).get();
      if (snap.exists && snap.value != null) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        tripIds.addAll(map.keys);
      }
    }

    // Also check email_trips path for users added by email.
    if (_userId != null) {
      // Try to find email from the user's profile in the directory.
      final profileSnap = await _db.ref('users/$_userId/profile').get();
      if (profileSnap.exists && profileSnap.value != null) {
        final profile = Map<String, dynamic>.from(profileSnap.value as Map);
        final email = (profile['email'] ?? '') as String;
        if (email.isNotEmpty) {
          final emailKey = email.toLowerCase().replaceAll('.', '_dot_').replaceAll('@', '_at_');
          final emailSnap = await _db.ref('email_trips/$emailKey').get();
          if (emailSnap.exists && emailSnap.value != null) {
            final map = Map<String, dynamic>.from(emailSnap.value as Map);
            tripIds.addAll(map.keys);
          }
        }
      }
    }

    // Also scan all trips for members matching this device or user identity.
    // This covers the case where another user added us as a member but we
    // haven't pulled the trip yet (e.g., they added us by email).
    final allTripsSnap = await _db.ref('trips').get();
    if (allTripsSnap.exists && allTripsSnap.value != null) {
      final allTrips = Map<String, dynamic>.from(allTripsSnap.value as Map);
      for (final tripEntry in allTrips.entries) {
        final tripId = tripEntry.key;
        if (tripIds.contains(tripId)) continue;
        final membersSnap = await _db.ref('trips/$tripId/members').get();
        if (!membersSnap.exists || membersSnap.value == null) continue;
        final members = Map<String, dynamic>.from(membersSnap.value as Map);
        for (final mEntry in members.entries) {
          final m = Map<String, dynamic>.from(mEntry.value as Map);
          final mDevice = m['deviceId'] as String? ?? '';
          final mEmail = m['emailLower'] as String? ?? '';
          final mGoogleId = m['googleId'] as String? ?? '';
          if (mDevice == _deviceId ||
              (_userId != null && mGoogleId == _userId) ||
              (_userId != null && mEmail == _userId)) {
            tripIds.add(tripId);
            break;
          }
        }
      }
    }

    int restored = 0;
    for (final tripId in tripIds) {
      final count = await pullAllOps(tripId);
      if (count > 0) restored++;
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
    var memberAdded = false;

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
      final result = await _syncService.processPayload(payload);
      applied += result.opsApplied;
      if (result.memberAdded) memberAdded = true;
    }

    if (applied > 0) {
      _statusController.add(CloudSyncStatus(
        tripId: tripId,
        lastSync: DateTime.now(),
        opsPulled: applied,
      ));
      if (memberAdded && onMemberAdded != null) {
        onMemberAdded!(tripId);
      }
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
      final result = await _syncService.processPayload(payload);
      applied += result.opsApplied;
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

      _syncService.processPayload(payload).then((result) {
        if (result.opsApplied > 0) {
          controller.add(SyncEvent(
            type: SyncEventType.synced,
            tripId: tripId,
            opsApplied: result.opsApplied,
          ));
          if (result.memberAdded && onMemberAdded != null) {
            onMemberAdded!(tripId);
          }
        }
      });
    });

    return controller.stream;
  }

  final _activeListeners = <String, StreamSubscription>{};

  /// Start listening for real-time updates on [tripId].
  /// Idempotent — calling again for the same trip is a no-op.
  void startListening(String tripId) {
    if (_activeListeners.containsKey(tripId)) return;
    final sub = listenForOps(tripId).listen((_) {});
    _activeListeners[tripId] = sub;
  }

  /// Stop listening for real-time updates on [tripId].
  void stopListening(String tripId) {
    _activeListeners.remove(tripId)?.cancel();
  }

  /// Stop all active listeners.
  void stopAllListeners() {
    for (final sub in _activeListeners.values) {
      sub.cancel();
    }
    _activeListeners.clear();
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
