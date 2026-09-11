import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform/platform_detect.dart';
import '../../core/platform/web_download.dart';
import '../../providers/app_provider.dart';
import '../widgets/sign_in_button.dart';
import '../widgets/video_background.dart';
import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _videoDone = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    // Fallback: show buttons after 5s even if video callback fails
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_videoDone) setState(() => _videoDone = true);
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

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
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
        child: _videoDone
            ? _ButtonsOverlay(onDownload: _downloadApk, onWeb: _openWebSignIn)
            : const SizedBox.shrink(),
      ),
    );
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
}

/// Buttons that appear at the bottom of the frozen video.
class _ButtonsOverlay extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onWeb;

  const _ButtonsOverlay({required this.onDownload, required this.onWeb});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 60),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.88),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionCard(
                  onTap: onDownload,
                  icon: Icons.phone_android_rounded,
                  iconColor: const Color(0xFF667eea),
                  title: 'Download the App',
                  subtitle: 'Best experience — offline, notifications, camera',
                ).animate().fadeIn(delay: 200.ms, duration: 700.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 10),
                _ActionCard(
                  onTap: onWeb,
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF764ba2),
                  title: 'Continue on Web',
                  subtitle: 'No install needed — works in any browser',
                ).animate().fadeIn(delay: 450.ms, duration: 700.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 10),
                Text(
                  'Both versions share the same account & data',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
              ],
            ),
          ),
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

/// Action card button.
class _ActionCard extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _ActionCard({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5), size: 20),
          ],
        ),
      ),
    );
  }
}
