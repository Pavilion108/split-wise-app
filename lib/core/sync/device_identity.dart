import 'package:uuid/uuid.dart';

class DeviceIdentity {
  DeviceIdentity._(this._rawId);
  String _rawId;
  String get id => _rawId;

  static final DeviceIdentity _instance = DeviceIdentity._('');

  static Future<DeviceIdentity> init() async {
    if (_instance._rawId.isNotEmpty) return _instance;
    _instance._rawId = const Uuid().v4();
    return _instance;
  }

  static DeviceIdentity forTesting(String id) => DeviceIdentity._(id);
}
