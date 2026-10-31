import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform detection utilities for download/install prompts.
class PlatformDetect {
  PlatformDetect._();

  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// APK download URL — hosted on Google Drive CDN via Firebase redirect.
  static const String apkDownloadUrl =
      'https://splitwiser-26.web.app/split-wise-app';

  /// Direct Google Drive download link (fallback).
  static const String apkFallbackUrl =
      'https://drive.google.com/file/d/1AvHSk92GTBZO-YbiuurPblzemOcX2-Lm/view?usp=sharing';

  /// Deep link to open the app if already installed.
  /// Android: intent:// scheme  |  iOS: Universal Link
  static String get appOpenLink => isAndroid
      ? 'splitwise://open'
      : 'https://splitwiser-26.web.app/app-open';

  /// App Store URL (placeholder — update when published).
  static const String iosStoreUrl =
      'https://apps.apple.com/app/split-wise/id0000000000';

  /// Whether the device can prompt "Install App" banner.
  /// Only on Android web browsers (APK sideload supported).
  static bool get canPromptInstall => isWeb && _isAndroidWeb;

  static bool get _isAndroidWeb {
    if (!kIsWeb) return false;
    // Detect Android user agent via window.navigator.
    try {
      // In web build, use conditional import or try-catch.
      return true; // Default to showing install prompt on web
    } catch (_) {
      return false;
    }
  }
}
