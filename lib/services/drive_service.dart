import 'dart:async';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Google Drive service for creating trip folders and storing photos/videos.
/// Each trip gets a folder in the user's Drive for storing trip media.
class DriveService {
  DriveService(this._authService);

  final AuthService _authService;

  /// Root folder ID for all Split Wise trip folders.
  String? _rootFolderId;

  /// Authenticated HTTP client for Drive API calls.
  http.Client? _client;

  /// Get Drive API with authenticated client.
  Future<drive.DriveApi?> _getDriveApi() async {
    final token = await _authService.getAccessToken();
    if (token == null) return null;

    _client?.close();
    _client = _AuthHttpClient(token);
    return drive.DriveApi(_client!);
  }

  /// Create or get the root "Split Wise" folder in user's Drive.
  Future<String> _ensureRootFolder(drive.DriveApi api) async {
    if (_rootFolderId != null) return _rootFolderId!;

    // Search for existing root folder.
    final query = await api.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and name = 'Split Wise' and trashed = false",
      $fields: 'files(id, name)',
    );
    if (query.files != null && query.files!.isNotEmpty) {
      _rootFolderId = query.files!.first.id!;
      return _rootFolderId!;
    }

    // Create root folder.
    final folder = drive.File()
      ..name = 'Split Wise'
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await api.files.create(folder);
    _rootFolderId = created.id!;
    return _rootFolderId!;
  }

  /// Create a trip folder inside "Split Wise" root.
  Future<TripFolder> createTripFolder({
    required String tripName,
    required String tripId,
  }) async {
    final api = await _getDriveApi();
    if (api == null) throw DriveException('Not signed in');

    final rootId = await _ensureRootFolder(api);

    // Check if folder already exists.
    final existing = await api.files.list(
      q: "mimeType = 'application/vnd.google-apps.folder' and name = '$tripName' and '$rootId' in parents and trashed = false",
      $fields: 'files(id, name, webViewLink)',
    );
    if (existing.files != null && existing.files!.isNotEmpty) {
      final file = existing.files!.first;
      return TripFolder(
        folderId: file.id!,
        name: file.name!,
        link: file.webViewLink ?? '',
      );
    }

    // Create trip folder.
    final folder = drive.File()
      ..name = tripName
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [rootId]
      ..description = 'Split Wise trip: $tripId';

    final created =
        await api.files.create(folder, $fields: 'id, name, webViewLink');

    var link = created.webViewLink ?? '';

    // With the `drive.file` scope, webViewLink is often null until the file is
    // shared. Share it with the signed-in user so a viewable link is generated.
    final email = _authService.userEmail;
    if (email != null) {
      try {
        await shareFolderWith(folderId: created.id!, email: email);
        final f = await api.files.get(created.id!,
            $fields: 'webViewLink') as drive.File;
        link = f.webViewLink ?? link;
      } catch (_) {
        // Link stays empty; the folder still exists for the owner.
      }
    }

    return TripFolder(
      folderId: created.id!,
      name: tripName,
      link: link,
    );
  }

  /// Create sub-folders inside trip folder.
  Future<void> createTripSubFolders(String tripFolderId) async {
    final api = await _getDriveApi();
    if (api == null) return;

    final subFolders = ['Photos', 'Videos', 'Receipts', 'Documents'];
    for (final name in subFolders) {
      final folder = drive.File()
        ..name = name
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = [tripFolderId];
      await api.files.create(folder, $fields: 'id');
    }
  }

  /// Upload a file to a folder.
  Future<DriveFile> uploadFile({
    required String folderId,
    required String fileName,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final api = await _getDriveApi();
    if (api == null) throw DriveException('Not signed in');

    final stream = Stream.fromIterable([bytes]);
    final media = drive.Media(stream, bytes.length, contentType: mimeType);

    final file = drive.File()
      ..name = fileName
      ..parents = [folderId];

    final created = await api.files.create(file, uploadMedia: media);

    return DriveFile(
      fileId: created.id!,
      name: fileName,
      link: created.webViewLink ?? '',
      mimeType: mimeType,
    );
  }

  /// Share a folder with an email address.
  Future<void> shareFolderWith({
    required String folderId,
    required String email,
    String role = 'reader',
  }) async {
    final api = await _getDriveApi();
    if (api == null) return;

    final permission = drive.Permission()
      ..type = 'user'
      ..role = role
      ..emailAddress = email;

    await api.permissions.create(
      permission,
      folderId,
      sendNotificationEmail: false,
    );
  }

  /// Get a shareable link for a folder.
  Future<String> getShareableLink(String folderId) async {
    final api = await _getDriveApi();
    if (api == null) return '';

    final file = await api.files.get(
      folderId,
      $fields: 'webViewLink',
    ) as drive.File;
    return file.webViewLink ?? '';
  }

  /// List files in a folder.
  Future<List<DriveFile>> listFiles(String folderId) async {
    final api = await _getDriveApi();
    if (api == null) return [];

    final result = await api.files.list(
      q: "'$folderId' in parents and trashed = false",
      $fields: 'files(id, name, webViewLink, mimeType, size)',
    );

    return (result.files ?? [])
        .map((f) => DriveFile(
              fileId: f.id!,
              name: f.name!,
              link: f.webViewLink ?? '',
              mimeType: f.mimeType ?? '',
              size: int.tryParse(f.size ?? '0') ?? 0,
            ))
        .toList();
  }

  void dispose() {
    _client?.close();
  }
}

/// HTTP client that attaches OAuth2 bearer token to requests.
class _AuthHttpClient extends http.BaseClient {
  _AuthHttpClient(this._token);

  final String _token;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

// --- Models ---

class TripFolder {
  const TripFolder({
    required this.folderId,
    required this.name,
    required this.link,
  });

  final String folderId;
  final String name;
  final String link;
}

class DriveFile {
  const DriveFile({
    required this.fileId,
    required this.name,
    required this.link,
    required this.mimeType,
    this.size = 0,
  });

  final String fileId;
  final String name;
  final String link;
  final String mimeType;
  final int size;
}

class DriveException implements Exception {
  const DriveException(this.message);
  final String message;

  @override
  String toString() => 'DriveException: $message';
}
