import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../core/sync/cloud_sync.dart';
import '../core/sync/invite_code.dart';
import '../core/sync/op_log_service.dart';
import '../models/models.dart';
import '../services/drive_service.dart';

class TripRepository {
  TripRepository(this._db, this._opLog, this._cloudSync, this._driveService);

  final AppDatabase _db;
  final OpLogService _opLog;
  final CloudSyncService? _cloudSync;
  final DriveService? _driveService;

  static const _uuid = Uuid();

  // --- Trips ---

  Stream<List<Trip>> watchTrips() {
    return (_db.select(_db.trips)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm.asc(t.status),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
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

  /// Mark a trip as completed. Updates local DB, records a sync op, and
  /// pushes the new status to the cloud so all devices see it.
  Future<void> markTripComplete(String tripId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.trips)..where((t) => t.id.equals(tripId)))
          .write(TripsCompanion(
        status: const Value('completed'),
        completedAt: Value(now),
      ));
      await _opLog.append(
        tripId: tripId,
        opType: 'trip_status',
        entityId: tripId,
        payload: {
          'id': tripId,
          'status': 'completed',
          'completedAt': now.toIso8601String(),
        },
      );
    });

    if (_cloudSync != null) {
      await _cloudSync.updateTripMeta(
        tripId: tripId,
        updates: {
          'status': 'completed',
          'completedAt': now.toIso8601String(),
        },
      );
      await _cloudSync.pushTripOps(tripId);
    }
  }

  /// Soft-delete a trip. Hides it from the home screen but preserves data.
  /// A sync op is recorded so other devices also hide the trip.
  Future<void> deleteTrip(String tripId) async {
    final now = DateTime.now();
    await _db.transaction(() async {
      await (_db.update(_db.trips)..where((t) => t.id.equals(tripId)))
          .write(TripsCompanion(
        deleted: const Value(true),
      ));
      await _opLog.append(
        tripId: tripId,
        opType: 'trip_deleted',
        entityId: tripId,
        payload: {
          'id': tripId,
          'deleted': true,
          'deletedAt': now.toIso8601String(),
        },
      );
    });

    if (_cloudSync != null) {
      await _cloudSync.pushTripOps(tripId);
    }
  }

  /// Delete ALL non-deleted trips (soft-delete). Used for one-time cleanup.
  Future<int> deleteAllTrips() async {
    final trips = await (_db.select(_db.trips)
          ..where((t) => t.deleted.equals(false)))
        .get();
    for (final trip in trips) {
      await deleteTrip(trip.id);
    }
    return trips.length;
  }

  /// Set or update the WhatsApp group invite link for a trip.
  /// Updates local DB, records a sync op, and pushes to the cloud so all
  /// members can see the "Join WhatsApp Group" button.
  Future<void> setWhatsAppLink(String tripId, String link) async {
    final trimmed = link.trim();
    await _db.transaction(() async {
      await (_db.update(_db.trips)..where((t) => t.id.equals(tripId)))
          .write(TripsCompanion(whatsappGroupLink: Value(trimmed)));
      await _opLog.append(
        tripId: tripId,
        opType: 'trip_meta',
        entityId: tripId,
        payload: {'id': tripId, 'whatsappGroupLink': trimmed},
      );
    });

    if (_cloudSync != null) {
      await _cloudSync.updateTripMeta(
        tripId: tripId,
        updates: {'whatsappGroupLink': trimmed},
      );
      await _cloudSync.pushTripOps(tripId);
    }
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
    String whatsappGroupLink = '',
  }) async {
    final tripId = _uuid.v4();
    final memberId = _uuid.v4();
    final inviteCode = InviteCode.generate();
    final now = DateTime.now();

    await _db.transaction(() async {
      await _db.into(_db.trips).insert(TripsCompanion.insert(
            id: tripId,
            name: name,
            baseCurrency: Value(baseCurrency),
            inviteCode: Value(inviteCode),
            whatsappGroupLink: Value(whatsappGroupLink),
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
          'inviteCode': inviteCode,
          'whatsappGroupLink': whatsappGroupLink,
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

    // Push to cloud so others can join via invite code.
    if (_cloudSync != null) {
      await _cloudSync.pushTripMeta(
        tripId: tripId,
        name: name,
        baseCurrency: baseCurrency,
        inviteCode: inviteCode,
        whatsappGroupLink: whatsappGroupLink,
        createdAt: now,
      );
      await _cloudSync.pushMember(
        tripId: tripId,
        memberId: memberId,
        name: memberName,
        deviceId: deviceId,
        joinedAt: now,
      );
      await _cloudSync.pushTripOps(tripId);
    }

    // Create Drive folder for trip (photos, videos, receipts).
    String driveFolderId = '';
    String driveFolderLink = '';
    final drive = _driveService;
    if (drive != null) {
      try {
        final tripFolder = await drive.createTripFolder(
          tripName: name,
          tripId: tripId,
        );
        await drive.createTripSubFolders(tripFolder.folderId);
        driveFolderId = tripFolder.folderId;
        driveFolderLink = tripFolder.link;

        // Update local DB with Drive folder info.
        await (_db.update(_db.trips)..where((t) => t.id.equals(tripId)))
            .write(TripsCompanion(
          driveFolderId: Value(driveFolderId),
          driveFolderLink: Value(driveFolderLink),
        ));

        // Update cloud metadata with Drive folder link.
        if (_cloudSync != null) {
          await _cloudSync.updateTripMeta(
            tripId: tripId,
            updates: {
              'driveFolderId': driveFolderId,
              'driveFolderLink': driveFolderLink,
            },
          );
        }
      } catch (e) {
        // Trip is still created even if Drive fails. Log so it's debuggable.
        // Common causes: Drive scope not granted in OAuth consent screen,
        // or the user denied Drive access during sign-in.
        print('Drive folder creation failed: $e');
      }
    }

    return (await getTrip(tripId))!;
  }

  /// Join an existing trip by invite code.
  /// First tries cloud lookup (works on any network), then falls back to local.
  /// [memberName] is the user's Google display name — used as the canonical
  /// name so every trip shows the same username for this person.
  Future<Trip?> joinTrip({
    required String inviteCode,
    required String memberName,
    required String deviceId,
    String googleId = '',
    String emailLower = '',
  }) async {
    final code = inviteCode.toUpperCase().trim();

    // --- Step 1: Try cloud lookup (works across any network) ---
    String? tripId;
    if (_cloudSync != null) {
      tripId = await _cloudSync.pullTripByCode(code);
    }

    // --- Step 2: Fallback to local DB ---
    if (tripId == null) {
      final trip = await (_db.select(_db.trips)
            ..where((t) =>
                t.inviteCode.equals(code) & t.deleted.equals(false)))
          .getSingleOrNull();
      tripId = trip?.id;
    }

    if (tripId == null) return null;

    final resolvedTripId = tripId;

    // Check if already a member — match by deviceId, googleId, or emailLower.
    MemberRow? existing;
    if (googleId.isNotEmpty) {
      existing = await (_db.select(_db.members)
            ..where((m) =>
                m.tripId.equals(resolvedTripId) &
                m.googleId.equals(googleId) &
                m.deleted.equals(false)))
          .getSingleOrNull();
    }
    if (existing == null && emailLower.isNotEmpty) {
      existing = await (_db.select(_db.members)
            ..where((m) =>
                m.tripId.equals(resolvedTripId) &
                m.emailLower.equals(emailLower) &
                m.deleted.equals(false)))
          .getSingleOrNull();
    }
    if (existing == null) {
      existing = await (_db.select(_db.members)
            ..where((m) =>
                m.tripId.equals(resolvedTripId) &
                m.deviceId.equals(deviceId) &
                m.deleted.equals(false)))
          .getSingleOrNull();
    }

    if (existing != null) {
      final existingId = existing.id;
      // Update the existing member row with the joining user's actual identity.
      // This is critical: the inviter may have created the member with deviceId=''
      // and a placeholder name. Now the real user joins — we update their deviceId,
      // googleId, emailLower, and name so all future lookups match correctly.
      await (_db.update(_db.members)..where((m) => m.id.equals(existingId))).write(
        MembersCompanion(
          deviceId: Value(deviceId),
          name: memberName.isNotEmpty ? Value(memberName) : const Value.absent(),
          googleId: googleId.isNotEmpty ? Value(googleId) : const Value.absent(),
          emailLower: emailLower.isNotEmpty ? Value(emailLower) : const Value.absent(),
        ),
      );
      await _opLog.append(
        tripId: resolvedTripId,
        opType: 'member',
        entityId: existingId,
        payload: {
          'id': existingId,
          'deviceId': deviceId,
          'name': memberName,
          'googleId': googleId,
          'emailLower': emailLower,
        },
      );
      if (_cloudSync != null) {
        await _cloudSync.pushMember(
          tripId: resolvedTripId,
          memberId: existingId,
          name: memberName,
          deviceId: deviceId,
          joinedAt: existing.joinedAt,
          googleId: googleId,
          emailLower: emailLower,
        );
        await _cloudSync.pushTripOps(resolvedTripId);
      }
      return getTrip(resolvedTripId);
    }

    // Add as member.
    final memberId = _uuid.v4();
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db.into(_db.members).insert(MembersCompanion.insert(
            id: memberId,
            tripId: resolvedTripId,
            name: memberName,
            deviceId: deviceId,
            joinedAt: now,
            googleId: Value(googleId),
            emailLower: Value(emailLower),
          ));
      await _opLog.append(
        tripId: resolvedTripId,
        opType: 'member',
        entityId: memberId,
        payload: {
          'id': memberId,
          'tripId': resolvedTripId,
          'name': memberName,
          'deviceId': deviceId,
          'googleId': googleId,
          'emailLower': emailLower,
          'joinedAt': now.toIso8601String(),
        },
      );
    });

    // Push new member to cloud.
    if (_cloudSync != null) {
      await _cloudSync.pushMember(
        tripId: resolvedTripId,
        memberId: memberId,
        name: memberName,
        deviceId: deviceId,
        joinedAt: now,
        googleId: googleId,
        emailLower: emailLower,
      );
      await _cloudSync.pushTripOps(resolvedTripId);
    }

    // Pull Drive folder info and inviteCode from cloud and update local DB.
    if (_cloudSync != null) {
      final meta = await _cloudSync.pullTripMeta(resolvedTripId);
      if (meta != null) {
        final folderId = meta['driveFolderId'] as String? ?? '';
        final folderLink = meta['driveFolderLink'] as String? ?? '';
        final waLink = meta['whatsappGroupLink'] as String? ?? '';
        final inviteCode = meta['inviteCode'] as String? ?? '';
        await (_db.update(_db.trips)..where((t) => t.id.equals(resolvedTripId)))
            .write(TripsCompanion(
          driveFolderId: folderId.isNotEmpty ? Value(folderId) : const Value.absent(),
          driveFolderLink: folderLink.isNotEmpty ? Value(folderLink) : const Value.absent(),
          whatsappGroupLink: waLink.isNotEmpty ? Value(waLink) : const Value.absent(),
          inviteCode: inviteCode.isNotEmpty ? Value(inviteCode) : const Value.absent(),
        ));
      }
    }

    return getTrip(resolvedTripId);
  }

  Future<Member> addMember({
    required String tripId,
    required String name,
    required String deviceId,
    int avatarColor = 0xFF43A047,
    String avatarAsset = '',
    String googleId = '',
    String emailLower = '',
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
            avatarAsset: Value(avatarAsset),
            googleId: Value(googleId),
            emailLower: Value(emailLower),
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
          'avatarAsset': avatarAsset,
          'googleId': googleId,
          'emailLower': emailLower,
          'joinedAt': now.toIso8601String(),
        },
      );
    });

    // Push to cloud.
    if (_cloudSync != null) {
      await _cloudSync.pushMember(
        tripId: tripId,
        memberId: id,
        name: name,
        deviceId: deviceId,
        joinedAt: now,
        avatarAsset: avatarAsset,
        googleId: googleId,
        emailLower: emailLower,
        avatarColor: avatarColor,
      );
      await _cloudSync.pushTripOps(tripId);
    }

    return (await getMember(id))!;
  }

  Future<void> updateMemberAvatar(String memberId, String avatarAsset) async {
    final member = await getMember(memberId);
    if (member == null) return;
    await _db.transaction(() async {
      await (_db.update(_db.members)..where((m) => m.id.equals(memberId)))
          .write(MembersCompanion(avatarAsset: Value(avatarAsset)));
      await _opLog.append(
        tripId: member.tripId,
        opType: 'member',
        entityId: memberId,
        payload: {'id': memberId, 'avatarAsset': avatarAsset},
      );
    });
    if (_cloudSync != null) await _cloudSync.pushTripOps(member.tripId);
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

    // Push to cloud.
    if (_cloudSync != null) {
      await _cloudSync.pushTripOps(member.tripId);
    }
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

    // Push to cloud.
    if (_cloudSync != null) {
      await _cloudSync.pushTripOps(tripId);
    }

    final row = await (_db.select(_db.categories)
          ..where((c) =>
              c.name.lower().equals(name.toLowerCase()) &
              c.tripId.equals(tripId)))
        .getSingleOrNull();
    return Category.fromRow(row!);
  }
}
