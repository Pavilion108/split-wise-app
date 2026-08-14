import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_provider.dart';

Widget buildSignInButton(BuildContext context) {
  return Consumer(
    builder: (context, ref, child) {
      return FilledButton.icon(
        onPressed: () async {
          final result = await ref.read(authServiceProvider).signIn();
          if (result.error != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result.error!)),
            );
          }
        },
        icon: const Icon(Icons.g_mobiledata, size: 24),
        label: const Text('Sign in with Google'),
      );
    },
  );
}
