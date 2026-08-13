import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'sync_service.dart';

/// WiFi sync transport: runs a tiny HTTP server on each device.
/// Devices on the same network can discover each other via manual IP entry
/// or QR code sharing. This works on ALL platforms.
///
/// For automatic discovery, devices share their IP via invite code/QR.
class WifiSyncTransport {
  WifiSyncTransport(this._syncService, this._deviceId);

  final SyncService _syncService;
  final String _deviceId;

  HttpServer? _server;
  bool _running = false;
  bool get isRunning => _running;

  /// Get the local IP address for sharing.
  Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
      // Fallback: try any non-loopback address.
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Start the HTTP sync server.
  Future<int?> start() async {
    if (_running) return _server?.port;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      _server!.listen(_handleRequest);
      _running = true;
      return _server!.port;
    } catch (_) {
      return null;
    }
  }

  /// Stop the HTTP sync server.
  Future<void> stop() async {
    _running = false;
    await _server?.close();
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method == 'GET' && request.uri.path == '/ping') {
        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'deviceId': _deviceId, 'status': 'ok'}))
          ..close();
      } else if (request.method == 'POST' && request.uri.path == '/sync') {
        final body = await utf8.decoder.bind(request).join();
        final payload = SyncPayload.decode(body);

        final applied = await _syncService.processPayload(payload);

        final ourPayload = await _syncService.buildPayload(payload.tripId);

        request.response
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({
            'applied': applied,
            'returnPayload': ourPayload.toJson(),
          }))
          ..close();
      } else {
        request.response.statusCode = 404;
        request.response.close();
      }
    } catch (e) {
      request.response.statusCode = 500;
      request.response.close();
    }
  }

  /// Sync with a peer at the given host:port.
  Future<SyncResult> syncWithPeer(String host, int port, String tripId) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final payload = await _syncService.buildPayload(tripId);

      final request = await client.postUrl(
        Uri.parse('http://$host:$port/sync'),
      );
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload.toJson()));

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final body = await utf8.decoder.bind(response).join();
      final result = jsonDecode(body) as Map<String, dynamic>;

      if (result['returnPayload'] != null) {
        final returnPayload = SyncPayload.fromJson(
            result['returnPayload'] as Map<String, dynamic>);
        await _syncService.processPayload(returnPayload);
      }

      return SyncResult(
        success: true,
        opsSent: payload.ops.length,
        opsReceived: result['applied'] as int? ?? 0,
      );
    } catch (e) {
      return SyncResult(success: false, error: e.toString());
    }
  }
}

class SyncResult {
  const SyncResult({
    required this.success,
    this.opsSent = 0,
    this.opsReceived = 0,
    this.error,
  });

  final bool success;
  final int opsSent;
  final int opsReceived;
  final String? error;
}
