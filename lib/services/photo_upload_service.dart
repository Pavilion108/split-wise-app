import 'dart:typed_data';

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

/// Service for uploading profile photos to Firebase Storage.
class PhotoUploadService {
  PhotoUploadService._();
  static final instance = PhotoUploadService._();

  final _storage = FirebaseStorage.instance;
  final _db = FirebaseDatabase.instance;

  /// Pick an image file using the platform's native file picker.
  /// Works reliably on web, mobile, and desktop.
  Future<Uint8List?> pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result.isEmpty) return null;
      // readAsBytes works on all platforms including web
      return await result.first.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  /// Upload profile photo to Firebase Storage and update user profile.
  /// Returns the download URL of the uploaded image.
  Future<String?> uploadProfilePhoto({
    required String googleId,
    required Uint8List imageBytes,
  }) async {
    try {
      final ref = _storage.ref('profile_photos/$googleId.jpg');

      await ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await ref.getDownloadURL();

      // Update user profile in RTDB
      await _db.ref('users/$googleId/profile/photoUrl').set(downloadUrl);
      await _db.ref('directory/$googleId/photoUrl').set(downloadUrl);

      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  /// Delete profile photo from Firebase Storage.
  Future<void> deleteProfilePhoto(String googleId) async {
    try {
      final ref = _storage.ref('profile_photos/$googleId.jpg');
      await ref.delete();
    } catch (_) {}
  }
}
