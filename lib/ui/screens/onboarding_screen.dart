import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import '../../core/platform/platform_detect.dart';
import '../../core/platform/web_download.dart';
import '../../providers/app_provider.dart';
import '../widgets/sign_in_button.dart';
import '../widgets/video_background.dart';
import '../widgets/model_3d_overlay.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _videoDone = false;
  Timer? _fallbackTimer;
  StreamSubscription<web.Event>? _downloadSub;
  StreamSubscription<web.Event>? _webSub;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_videoDone) setState(() => _videoDone = true);
    });
    _listenForButtons();
  }

  Future<void> _checkAuth() async {
    final auth = ref.read(authServiceProvider);
    await auth.checkSignIn();
    if (auth.isSignedIn && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      return;
    }
  }

  void _listenForButtons() {
    web.document.addEventListener(
      'spliti5-download',
      ((JSAny? e) {
        _downloadApk();
      }).toJS,
    );
    web.document.addEventListener(
      'spliti5-web',
      ((JSAny? e) {
        _openWebSignIn();
      }).toJS,
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _downloadSub?.cancel();
    _webSub?.cancel();
    super.dispose();
  }

  void _openWebSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _GoogleSignInPage()),
    );
  }

  Future<void> _downloadApk() async {
    final ok = await downloadFile(
      PlatformDetect.apkDownloadUrl,
      fileName: 'split-wise.apk',
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start download')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoBackground(
        duration: const Duration(seconds: 10),
        onLoopComplete: () {
          if (mounted) setState(() => _videoDone = true);
        },
        child: Stack(
          children: [
            // 3D Model overlay (HTML) — shows after video freezes
            Model3DOverlay(show: _videoDone),
            // Bottom gradient for readability
            if (_videoDone)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 260,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Google sign-in page — clean, single purpose.
class _GoogleSignInPage extends ConsumerWidget {
  const _GoogleSignInPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);

    if (auth.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a1a),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0f0c29), Color(0xFF1a1a3e), Color(0xFF0a0a1a)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Spliti5',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(blurRadius: 16, color: const Color(0xFF667eea).withValues(alpha: 0.4)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Sign in to continue',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Google account is used for:\n'
                      '• Syncing expenses across devices\n'
                      '• Storing trip photos in Google Drive\n'
                      '• Same account on web & app',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (!auth.isSignedIn) const SignInButton(),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Back',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
