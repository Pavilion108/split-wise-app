import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_provider.dart';

Widget buildSignInButton(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  return FilledButton.icon(
    onPressed: () async {
      final auth = ProviderScope.containerOf(context).read(authServiceProvider);
      final result = await auth.signIn();
      if (context.mounted && !result.success && result.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Google Play Services unavailable on this device.\nUse "Demo / Reviewer Account" below to enter.',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    },
    icon: const Icon(Icons.login_rounded),
    label: const Text('Sign in with Google'),
    style: FilledButton.styleFrom(
      backgroundColor: cs.primary,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    ),
  );
}
