import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VersionService {
  static const _lastSeenVersionKey = 'last_seen_app_version';

  /// Get current app version from pubspec.yaml
  static Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (_) {
      return '1.0.0';
    }
  }

  /// Get current build number
  static Future<String> getBuildNumber() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.buildNumber;
    } catch (_) {
      return '1';
    }
  }

  /// Check if user has seen this version before (for What's New)
  static Future<bool> isNewVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(_lastSeenVersionKey);
      final current = await getCurrentVersion();
      return lastSeen != current;
    } catch (_) {
      return false;
    }
  }

  /// Mark current version as seen
  static Future<void> markVersionSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getCurrentVersion();
      await prefs.setString(_lastSeenVersionKey, current);
    } catch (_) {}
  }

  /// Get What's New content for current version
  static String getWhatsNew() {
    return 'What\'s New in v1.0.0\n\n'
        '• Smart expense splitting with equal/custom splits\n'
        '• WhatsApp group integration\n'
        '• Dark mode support\n'
        '• UPI payment integration\n'
        '• Cloud sync across devices\n'
        '• Export data as PDF\n'
        '• Performance improvements and bug fixes';
  }
}
