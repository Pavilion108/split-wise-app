import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/sync/device_identity.dart';
import 'firebase_options.dart';
import 'providers/app_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final device = await DeviceIdentity.init();

  runApp(
    ProviderScope(
      overrides: [deviceIdentityProvider.overrideWithValue(device)],
      child: const SplitWiseApp(),
    ),
  );
}
