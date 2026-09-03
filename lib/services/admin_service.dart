import 'package:firebase_database/firebase_database.dart';

/// Admin service for Split Wise portal.
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
      trips.add({
        'id': entry.key,
        'name': meta?['name'] ?? 'Unknown',
        'baseCurrency': meta?['baseCurrency'] ?? 'INR',
        'inviteCode': meta?['inviteCode'] ?? '',
        'createdAt': meta?['createdAt'] ?? '',
        'createdBy': meta?['createdBy'] ?? '',
        'memberCount': (tripData['members'] as Map?)?.length ?? 0,
        'opsCount': (tripData['ops'] as Map?)?.length ?? 0,
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

  /// Get all users from the directory.
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snap = await _db.ref('directory').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    return map.entries.map((e) {
      final u = Map<String, dynamic>.from(e.value as Map);
      return u;
    }).toList();
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

  /// Delete a trip and all its data (permanent).
  Future<void> deleteTripPermanently(String tripId) async {
    await _db.ref('trips/$tripId').remove();
    // Clean up invite code
    final metaSnap = await _db.ref('trips/$tripId/meta').get();
    if (metaSnap.exists && metaSnap.value != null) {
      final meta = Map<String, dynamic>.from(metaSnap.value as Map);
      final code = meta['inviteCode'] as String?;
      if (code != null && code.isNotEmpty) {
        await _db.ref('invite_codes/$code').remove();
      }
    }
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
}
