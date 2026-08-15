import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/sync/device_identity.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  DeviceIdentity device;
  try {
    device = await DeviceIdentity.init();
  } catch (e) {
    debugPrint('DeviceIdentity init failed: $e');
    device = DeviceIdentity.forTesting('fallback_device');
  }

  runApp(
    ProviderScope(
      overrides: [deviceIdentityProvider.overrideWithValue(device)],
      child: const SplitWiseApp(),
    ),
  );
}
