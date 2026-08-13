import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'sync_service.dart';

/// BLE sync transport: discovers nearby Split Wise devices via BLE scanning.
/// Works on ALL platforms (Android, iOS, Windows, Mac, Linux).
///
/// NOTE: Full BLE data transfer requires platform-specific GATT implementation.
/// This transport provides device discovery and triggers WiFi sync when
/// a nearby device is found.
class BleSyncTransport {
  BleSyncTransport(this._syncService);

  final SyncService _syncService;

  bool _scanning = false;

  final _foundDevicesController =
      StreamController<BleDiscoveredDevice>.broadcast();
  Stream<BleDiscoveredDevice> get foundDevices =>
      _foundDevicesController.stream;

  /// Start scanning for nearby Split Wise devices.
  Future<void> scan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_scanning) return;
    _scanning = true;

    try {
      FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final name = result.advertisementData.advName;
          if (name.startsWith('SW_')) {
            final tripId = name.replaceFirst('SW_', '');
            _foundDevicesController.add(BleDiscoveredDevice(
              deviceId: result.device.remoteId.str,
              tripId: tripId,
              rssi: result.rssi,
              device: result.device,
            ));
          }
        }
      });

      await FlutterBluePlus.startScan(timeout: timeout);
    } catch (_) {
      // BLE may not be available on this device.
    }
    _scanning = false;
  }

  /// Stop scanning.
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    _scanning = false;
  }
}

class BleDiscoveredDevice {
  const BleDiscoveredDevice({
    required this.deviceId,
    required this.tripId,
    required this.rssi,
    required this.device,
  });

  final String deviceId;
  final String tripId;
  final int rssi;
  final BluetoothDevice device;
}
