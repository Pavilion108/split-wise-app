import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentity {
  DeviceIdentity._(this._rawId);
  String _rawId;
  String get id => _rawId;

  static final DeviceIdentity _instance = DeviceIdentity._('');

  static Future<DeviceIdentity> init() async {
    if (_instance._rawId.isNotEmpty) return _instance;
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}${Platform.pathSeparator}device_id');
      if (await file.exists()) {
        final stored = (await file.readAsString()).trim();
        if (stored.isNotEmpty) {
          _instance._rawId = stored;
          return _instance;
        }
      }
      final fresh = const Uuid().v4();
      await file.writeAsString(fresh, flush: true);
      _instance._rawId = fresh;
    } catch (_) {
      _instance._rawId = const Uuid().v4();
    }
    return _instance;
  }

  static DeviceIdentity forTesting(String id) => DeviceIdentity._(id);
}
