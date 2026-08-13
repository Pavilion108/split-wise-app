import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'providers/app_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';

class SplitWiseApp extends ConsumerWidget {
  const SplitWiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Split Wise',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: authState.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => const HomeScreen(),
        data: (state) {
          if (state.isSignedIn) {
            return const HomeScreen();
          }
          return const OnboardingScreen();
        },
      ),
    );
  }
}
