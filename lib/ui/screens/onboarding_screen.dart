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

  @override
  void initState() {
    super.initState();
    _checkAuth();
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: VideoBackground(
        duration: const Duration(seconds: 10),
        onLoopComplete: () {
          if (mounted) setState(() => _videoDone = true);
        },
        child: _videoDone ? _buildButtonsOverlay() : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildButtonsOverlay() {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                // Brand name
                Text(
                  'Spliti5',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(blurRadius: 24, color: const Color(0xFF667eea).withValues(alpha: 0.6)),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 700.ms).scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                  curve: Curves.easeOutBack,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fair splits, zero awkwardness.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),
                const Spacer(flex: 2),

                // Download App button
                _ActionCard(
                  onTap: _downloadApk,
                  icon: Icons.phone_android_rounded,
                  iconColor: const Color(0xFF667eea),
                  title: 'Download the App',
                  subtitle: 'Best experience — offline, notifications, camera',
                ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 12),

                // Continue on Web button
                _ActionCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const _GoogleSignInPage()),
                  ),
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF764ba2),
                  title: 'Continue on Web',
                  subtitle: 'No install needed — works in any browser',
                ).animate().fadeIn(delay: 1000.ms, duration: 600.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 16),
                Text(
                  'Both versions share the same account & data',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
                ).animate().fadeIn(delay: 1200.ms, duration: 500.ms),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
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

/// Clean Google sign-in page — single purpose, no wizard.
class _GoogleSignInPage extends ConsumerWidget {
  const _GoogleSignInPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);

    // Already signed in — go to home
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
                    // Brand
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

/// Action card button for the overlay.
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
