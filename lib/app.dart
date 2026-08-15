import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'providers/app_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding_screen.dart';

class SplitWiseApp extends ConsumerStatefulWidget {
  const SplitWiseApp({super.key});

  @override
  ConsumerState<SplitWiseApp> createState() => _SplitWiseAppState();
}

class _SplitWiseAppState extends ConsumerState<SplitWiseApp> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final auth = ref.read(authServiceProvider);
      await auth.checkSignIn().timeout(const Duration(seconds: 8));
    } catch (_) {
      // Auth check failed or timed out — proceed to onboarding.
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);

    return MaterialApp(
      title: 'Split Wise',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: _checking
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : auth.isSignedIn
              ? const HomeScreen()
              : const OnboardingScreen(),
    );
  }
}
