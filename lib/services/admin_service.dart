import 'package:firebase_database/firebase_database.dart';

/// Admin service for Spliti5 portal.
/// Provides full database-level controls and real-time activity monitoring.
class AdminService {
  AdminService._();
  static final instance = AdminService._();

  final _db = FirebaseDatabase.instance;

  /// Admin email — the only account with full forensic access.
  static const adminEmail = 'vighnesh.bagal99@gmail.com';

  /// Check if a user email is an admin.
  static bool isAdmin(String? email) {
    return email?.toLowerCase() == adminEmail;
  }

  // --- Database Operations ---

  /// Get full database snapshot for inspection.
  Future<Map<String, dynamic>> getFullDatabaseSnapshot() async {
    final snap = await _db.ref().get();
    if (!snap.exists || snap.value == null) return {};
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// Get all trips with metadata.
  Future<List<Map<String, dynamic>>> getAllTrips() async {
    final snap = await _db.ref('trips').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final trips = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      final tripData = Map<String, dynamic>.from(entry.value as Map);
      final meta = tripData['meta'] as Map?;
      final members = tripData['members'] as Map?;
      final ops = tripData['ops'] as Map?;

      // Count expenses and settlements from ops
      int expenseCount = 0;
      int settlementCount = 0;
      if (ops != null) {
        for (final opEntry in ops.entries) {
          final op = Map<String, dynamic>.from(opEntry.value as Map);
          final opType = op['opType'] ?? '';
          if (opType == 'expense' || opType == 'expense_corrected') expenseCount++;
          if (opType == 'settlement' || opType == 'settlement_edited') settlementCount++;
        }
      }

      trips.add({
        'id': entry.key,
        'name': meta?['name'] ?? 'Unknown',
        'baseCurrency': meta?['baseCurrency'] ?? 'INR',
        'inviteCode': meta?['inviteCode'] ?? '',
        'createdAt': meta?['createdAt'] ?? '',
        'createdBy': meta?['createdBy'] ?? '',
        'status': meta?['status'] ?? 'active',
        'driveFolderLink': meta?['driveFolderLink'] ?? '',
        'whatsappGroupLink': meta?['whatsappGroupLink'] ?? '',
        'memberCount': members?.length ?? 0,
        'opsCount': ops?.length ?? 0,
        'expenseCount': expenseCount,
        'settlementCount': settlementCount,
      });
    }
    return trips;
  }

  /// Get all members for a trip.
  Future<List<Map<String, dynamic>>> getTripMembers(String tripId) async {
    final snap = await _db.ref('trips/$tripId/members').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    return map.entries.map((e) {
      final m = Map<String, dynamic>.from(e.value as Map);
      return m;
    }).toList();
  }

  /// Get all ops for a trip (audit log).
  Future<List<Map<String, dynamic>>> getTripOps(String tripId) async {
    final snap = await _db.ref('trips/$tripId/ops').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    return map.entries.map((e) {
      final op = Map<String, dynamic>.from(e.value as Map);
      return op;
    }).toList()
      ..sort((a, b) => (a['lamportTs'] ?? 0).compareTo(b['lamportTs'] ?? 0));
  }

  /// Get all users from the directory with full profile info.
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _db.ref('directory').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final users = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      final u = Map<String, dynamic>.from(entry.value as Map);
      // Count trips this user belongs to
      int tripCount = 0;
      final tripsSnap = await _db.ref('users/${entry.key}/trips').get();
      if (tripsSnap.exists && tripsSnap.value != null) {
        tripCount = (tripsSnap.value as Map).length;
      }
      u['tripCount'] = tripCount;
      users.add(u);
    }
    return users;
  }

  /// Get all pending invites.
  Future<Map<String, dynamic>> getAllInvites() async {
    final snap = await _db.ref('invites').get();
    if (!snap.exists || snap.value == null) return {};
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// Get all invite code mappings.
  Future<Map<String, dynamic>> getAllInviteCodes() async {
    final snap = await _db.ref('invite_codes').get();
    if (!snap.exists || snap.value == null) return {};
    return Map<String, dynamic>.from(snap.value as Map);
  }

  /// Delete a trip and ALL its data permanently.
  /// Reads invite code BEFORE deletion to clean up invite_codes node.
  Future<void> deleteTripPermanently(String tripId) async {
    // Step 1: Read invite code BEFORE deleting the trip
    String inviteCode = '';
    final metaSnap = await _db.ref('trips/$tripId/meta').get();
    if (metaSnap.exists && metaSnap.value != null) {
      final meta = Map<String, dynamic>.from(metaSnap.value as Map);
      inviteCode = meta['inviteCode'] as String? ?? '';
    }

    // Step 2: Clean up invite_codes node
    if (inviteCode.isNotEmpty) {
      await _db.ref('invite_codes/$inviteCode').remove();
    }

    // Step 3: Clean up email_trips for all members
    final membersSnap = await _db.ref('trips/$tripId/members').get();
    if (membersSnap.exists && membersSnap.value != null) {
      final members = Map<String, dynamic>.from(membersSnap.value as Map);
      for (final mEntry in members.entries) {
        final m = Map<String, dynamic>.from(mEntry.value as Map);
        final email = m['emailLower'] as String? ?? '';
        if (email.isNotEmpty) {
          final emailKey = email.replaceAll('.', '_dot_').replaceAll('@', '_at_');
          await _db.ref('email_trips/$emailKey/$tripId').remove();
        }
        // Clean up user membership index
        final googleId = m['googleId'] as String? ?? '';
        if (googleId.isNotEmpty) {
          await _db.ref('users/$googleId/trips/$tripId').remove();
        }
        // Clean up device membership index
        final deviceId = m['deviceId'] as String? ?? '';
        if (deviceId.isNotEmpty) {
          await _db.ref('devices/$deviceId/trips/$tripId').remove();
        }
      }
    }

    // Step 4: Clean up invites referencing this trip
    final invitesSnap = await _db.ref('invites').get();
    if (invitesSnap.exists && invitesSnap.value != null) {
      final allInvites = Map<String, dynamic>.from(invitesSnap.value as Map);
      for (final userEntry in allInvites.entries) {
        final userTrips = Map<String, dynamic>.from(userEntry.value as Map);
        if (userTrips.containsKey(tripId)) {
          await _db.ref('invites/${userEntry.key}/$tripId').remove();
        }
      }
    }

    // Step 5: Finally delete the trip itself
    await _db.ref('trips/$tripId').remove();
  }

  /// Delete a member from a trip.
  Future<void> deleteMember(String tripId, String memberId) async {
    await _db.ref('trips/$tripId/members/$memberId').remove();
  }

  /// Delete an op from a trip.
  Future<void> deleteOp(String tripId, String opId) async {
    await _db.ref('trips/$tripId/ops/$opId').remove();
  }

  /// Delete a user from the directory.
  Future<void> deleteUser(String googleId) async {
    await _db.ref('directory/$googleId').remove();
    await _db.ref('users/$googleId').remove();
  }

  /// Delete an invite.
  Future<void> deleteInvite(String googleId, String tripId) async {
    await _db.ref('invites/$googleId/$tripId').remove();
  }

  /// Get database size estimate (count of top-level nodes).
  Future<Map<String, int>> getDatabaseStats() async {
    final stats = <String, int>{};
    for (final node in ['trips', 'users', 'directory', 'invites', 'invite_codes', 'email_trips', 'devices']) {
      final snap = await _db.ref(node).get();
      if (snap.exists && snap.value != null) {
        final map = Map<String, dynamic>.from(snap.value as Map);
        stats[node] = map.length;
      } else {
        stats[node] = 0;
      }
    }
    return stats;
  }

  /// Watch real-time ops for a trip (live activity feed).
  Stream<DatabaseEvent> watchTripOps(String tripId) {
    return _db.ref('trips/$tripId/ops').onChildAdded;
  }

  /// Watch real-time member changes.
  Stream<DatabaseEvent> watchTripMembers(String tripId) {
    return _db.ref('trips/$tripId/members').onChildChanged;
  }

  /// Set admin claim in the database.
  Future<void> setAdminClaim(String googleId, bool isAdmin) async {
    await _db.ref('admin/$googleId').set({
      'email': adminEmail,
      'isAdmin': isAdmin,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Generate full backup data as JSON for ZIP export.
  Future<Map<String, dynamic>> generateBackupData() async {
    final backup = <String, dynamic>{};

    // All trips
    final tripsSnap = await _db.ref('trips').get();
    backup['trips'] = tripsSnap.exists ? tripsSnap.value : {};

    // All directory entries
    final dirSnap = await _db.ref('directory').get();
    backup['directory'] = dirSnap.exists ? dirSnap.value : {};

    // All users
    final usersSnap = await _db.ref('users').get();
    backup['users'] = usersSnap.exists ? usersSnap.value : {};

    // All invite codes
    final codesSnap = await _db.ref('invite_codes').get();
    backup['invite_codes'] = codesSnap.exists ? codesSnap.value : {};

    // All invites
    final invitesSnap = await _db.ref('invites').get();
    backup['invites'] = invitesSnap.exists ? invitesSnap.value : {};

    // All email trips
    final emailTripsSnap = await _db.ref('email_trips').get();
    backup['email_trips'] = emailTripsSnap.exists ? emailTripsSnap.value : {};

    // All devices
    final devicesSnap = await _db.ref('devices').get();
    backup['devices'] = devicesSnap.exists ? devicesSnap.value : {};

    // Metadata
    backup['_metadata'] = {
      'exportedAt': DateTime.now().toIso8601String(),
      'exportedBy': 'Admin Dashboard',
      'version': '1.0.0',
    };

    return backup;
  }
}
