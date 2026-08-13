import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'sync_service.dart';

/// QR/Share sync transport: export/import sync bundles via WhatsApp/Gmail.
/// Works on ANY device with share capabilities.
///
/// Flow:
/// 1. Export: Build compressed sync bundle → save as file → share via WhatsApp/Gmail
/// 2. Import: Receive file → read → decode → apply to local DB
class QrSyncTransport {
  QrSyncTransport(this._syncService);

  final SyncService _syncService;

  /// Export trip sync bundle as a shareable file.
  Future<ShareResult> exportTrip({
    required String tripId,
    required String tripName,
  }) async {
    final payload = await _syncService.buildPayload(tripId);

    // Encode as compact JSON.
    final json = jsonEncode(payload.toJson());
    final bytes = Uint8List.fromList(utf8.encode(json));

    // Save to temp directory.
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
        '${dir.path}${Platform.pathSeparator}splitwise_${tripName}_$timestamp.json');
    await file.writeAsBytes(bytes, flush: true);

    // Share via system share sheet (WhatsApp, Gmail, etc.).
    final result = await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Split Wise Sync: $tripName',
      text: 'Sync data for trip "$tripName". Import this file in Split Wise to sync.',
    );

    return ShareResult(
      filePath: file.path,
      shared: result.status == ShareResultStatus.success,
    );
  }

  /// Import trip sync bundle from a file.
  Future<ImportResult> importTrip(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(success: false, error: 'File not found');
      }

      final bytes = await file.readAsBytes();
      final json = utf8.decode(bytes);
      final payload = SyncPayload.decode(json);

      final applied = await _syncService.processPayload(payload);

      return ImportResult(
        success: true,
        tripId: payload.tripId,
        opsApplied: applied,
      );
    } catch (e) {
      return ImportResult(success: false, error: e.toString());
    }
  }

  /// Generate a compact text representation for QR code.
  /// This is for small payloads (e.g., trip invite + recent expenses).
  Future<String> generateQrText({
    required String tripId,
    required String code,
    required String tripName,
    required String baseCurrency,
  }) async {
    final payload = await _syncService.buildPayload(tripId);

    // Compact format: code|tripId|baseCurrency|opsCount|lastTs
    return '$code|$tripId|$baseCurrency|${payload.ops.length}|${DateTime.now().millisecondsSinceEpoch}';
  }
}

class ShareResult {
  const ShareResult({required this.filePath, required this.shared});

  final String filePath;
  final bool shared;
}

class ImportResult {
  const ImportResult({
    required this.success,
    this.tripId,
    this.opsApplied = 0,
    this.error,
  });

  final bool success;
  final String? tripId;
  final int opsApplied;
  final String? error;
}
