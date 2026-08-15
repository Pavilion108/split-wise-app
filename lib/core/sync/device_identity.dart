import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
class DeviceIdentity {
  DeviceIdentity._(this._rawId);
  String _rawId;
  String get id => _rawId;

  static final DeviceIdentity _instance = DeviceIdentity._('');

  static Future<DeviceIdentity> init() async {
    if (_instance._rawId.isNotEmpty) return _instance;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('device_id');
    if (stored != null && stored.isNotEmpty) {
      _instance._rawId = stored;
      return _instance;
    }
    final fresh = const Uuid().v4();
    await prefs.setString('device_id', fresh);
    _instance._rawId = fresh;
    return _instance;
  }

  static DeviceIdentity forTesting(String id) => DeviceIdentity._(id);
}
