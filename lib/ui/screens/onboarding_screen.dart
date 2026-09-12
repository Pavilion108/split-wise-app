import 'dart:async';
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
  bool _popupVisible = false;
  Timer? _fallbackTimer;
  Timer? _popupDelayTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _createActionChannel();
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_videoDone) _onVideoDone();
    });
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

  /// Create a hidden div as a communication bridge.
  /// HTML onclick handlers write action names into this div.
  /// Flutter polls it every 100ms to detect button presses.
  void _createActionChannel() {
    final channel = web.HTMLDivElement()
      ..id = 'spliti5-action'
      ..style.cssText = 'display:none;';
    web.document.body?.appendChild(channel);

    _pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      final ch = web.document.getElementById('spliti5-action');
      if (ch == null) return;
      final action = ch.textContent ?? '';
      if (action.isEmpty) return;
      ch.textContent = '';
      if (action == 'download') _downloadApk();
      if (action == 'web') _openWebSignIn();
    });
  }

  void _onVideoDone() {
    if (!mounted || _videoDone) return;
    setState(() => _videoDone = true);
    _popupDelayTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _popupVisible = true);
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _popupDelayTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  void _openWebSignIn() {
    web.window.location.href = web.window.location.href;
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
        onLoopComplete: () => _onVideoDone(),
        child: Stack(
          children: [
            if (_videoDone)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 340,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: _popupVisible ? 1.0 : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
             Model3DOverlay(show: _popupVisible),
            if (_popupVisible)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SignInButton(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}




