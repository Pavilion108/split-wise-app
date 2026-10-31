import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/platform_detect.dart';
import '../../core/platform/web_action_bridge.dart';
import '../../core/platform/web_download.dart';
import '../../services/auth_service.dart';
import '../../providers/app_provider.dart';
import '../widgets/sign_in_button.dart';
import '../widgets/video_background.dart';
import '../widgets/model_3d_overlay.dart';

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
  WebActionBridge? _actionBridge;

  @override
  void initState() {
    super.initState();
    _createActionChannel();
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_videoDone) _onVideoDone();
    });
  }

  void _createActionChannel() {
    _actionBridge = WebActionBridge.create()
      ..init((action) {
        if (!mounted) return;
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
    _actionBridge?.dispose();
    _actionBridge = null;
    super.dispose();
  }

  void _openWebSignIn() {
    if (!mounted) return;
    if (kIsWeb) {
      _showWebSignInDialog();
    } else {
      _signInNative();
    }
  }

  Future<void> _signInNative() async {
    final auth = ref.read(authServiceProvider);
    final result = await auth.signIn();
    if (!result.success && result.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: ${result.error}')),
      );
    }
  }

  void _showWebSignInDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: const Color(0xFF16162a),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                ),
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 18),
              const Text(
                'Spliti5 Web',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in with Google to continue to your trips in your browser',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  children: [
                    _featureRow(Icons.sync_rounded, 'Real-time multi-device sync'),
                    const SizedBox(height: 8),
                    _featureRow(Icons.cloud_outlined, 'Trip backup & cloud restore'),
                    const SizedBox(height: 8),
                    _featureRow(Icons.devices_rounded, 'Same account on web and mobile app'),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                height: 48,
                child: Center(child: SignInButton()),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Dismiss',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF667eea), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
      ],
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
    ref.listen<AuthService>(authServiceProvider, (prev, next) {
      if (next.isSignedIn && mounted) {
        Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
      }
    });

    if (!kIsWeb) {
      return _buildNativeOnboarding(context);
    }

    return _buildWebOnboarding(context);
  }

  Widget _buildNativeOnboarding(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF1E1B4B),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Spliti5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Smart group expense splitting for travel & life',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      _featureRow(Icons.wifi_off_rounded, '100% Offline-first local database'),
                      const SizedBox(height: 14),
                      _featureRow(Icons.calculate_rounded, 'Real-time who owes whom calculations'),
                      const SizedBox(height: 14),
                      _featureRow(Icons.currency_exchange_rounded, 'Multi-currency & UPI settlements'),
                      const SizedBox(height: 14),
                      _featureRow(Icons.sync_rounded, 'Instant cloud sync across all devices'),
                    ],
                  ),
                ),
                const Spacer(flex: 3),
                const SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Center(child: SignInButton()),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign in with Google to sync your trips across devices',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebOnboarding(BuildContext context) {
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
                  child: const SignInButton(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
