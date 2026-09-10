import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDirectoryService {
  final _db = FirebaseDatabase.instance;
  static const _searchableKey = 'user_searchable';
  static const _avatarKey = 'user_avatar_asset';

  Future<bool> get searchable async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_searchableKey) ?? true;
  }

  Future<void> setSearchable(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_searchableKey, v);
  }

  Future<String> get avatarAsset async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_avatarKey) ?? '';
  }

  Future<void> setAvatarAsset(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_avatarKey, id);
  }

  Future<void> upsertProfile({
    required String googleId,
    required String email,
    required String displayName,
    String photoUrl = '',
    String avatarAsset = '',
    bool? searchableOverride,
  }) async {
    final searchableVal = searchableOverride ?? await searchable;
    final lower = email.toLowerCase().trim();
    final usernameLower = displayName.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    await _db.ref('users/$googleId/profile').set({
      'googleId': googleId,
      'email': email,
      'emailLower': lower,
      'displayName': displayName,
      'usernameLower': usernameLower,
      'photoUrl': photoUrl,
      'avatarAsset': avatarAsset,
      'searchable': searchableVal,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    if (searchableVal) {
      await _db.ref('directory/$googleId').set({
        'googleId': googleId,
        'displayName': displayName,
        'usernameLower': usernameLower,
        'emailLower': lower,
        'email': email,
        'avatarAsset': avatarAsset,
        'photoUrl': photoUrl,
      });
    } else {
      await _db.ref('directory/$googleId').remove();
    }
  }

  Future<List<Map<String, dynamic>>> search(String query, {int limit = 10}) async {
    final q = query.toLowerCase().trim();
    if (q.length < 2) return [];
    final snap = await _db.ref('directory').get();
    if (!snap.exists || snap.value == null) return [];
    final map = Map<String, dynamic>.from(snap.value as Map);
    final out = <Map<String, dynamic>>[];
    for (final e in map.entries) {
      final v = Map<String, dynamic>.from(e.value as Map);
      final uname = (v['usernameLower'] ?? '') as String;
      final emailL = (v['emailLower'] ?? '') as String;
      final display = (v['displayName'] ?? '').toString().toLowerCase();
      // Match: username starts with, email contains, display name contains
      final emailMatch = emailL.contains(q) || emailL.startsWith(q);
      final nameMatch = uname.startsWith(q) || uname.contains(q) || display.startsWith(q) || display.contains(q);
      if (emailMatch || nameMatch) {
        final email = v['email'] as String? ?? v['emailLower'] as String? ?? '';
        v['emailMasked'] = email.contains('@') ? email.replaceRange(1, email.indexOf('@'), '*' * 3) : email;
        out.add(v);
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}
