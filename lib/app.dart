import 'package:flutter/foundation.dart' show kIsWeb;
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
  String? _pendingJoinCode;

  @override
  void initState() {
    super.initState();
    _initAuth();
    _extractJoinCodeFromUrl();
  }

  void _extractJoinCodeFromUrl() {
    if (!kIsWeb) return;
    try {
      final uri = Uri.base;
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty && pathSegments.first == 'join' && pathSegments.length >= 2) {
        _pendingJoinCode = pathSegments[1].toUpperCase();
      }
      // Also check query parameter as fallback
      if (_pendingJoinCode == null && uri.queryParameters.containsKey('code')) {
        _pendingJoinCode = uri.queryParameters['code']!.toUpperCase();
      }
    } catch (_) {
      // URL parsing failed — proceed without join code.
    }
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
    final settings = ref.watch(settingsServiceProvider);

    return MaterialApp(
      title: 'Split Wise',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: settings.themeMode,
      home: _checking
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : auth.isSignedIn
              ? HomeScreen(initialJoinCode: _pendingJoinCode)
              : const OnboardingScreen(),
    );
  }
}
