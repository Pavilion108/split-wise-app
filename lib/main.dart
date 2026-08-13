import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/sync/device_identity.dart';
import 'providers/app_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final device = await DeviceIdentity.init();

  runApp(
    ProviderScope(
      overrides: [deviceIdentityProvider.overrideWithValue(device)],
      child: const SplitWiseApp(),
    ),
  );
}
