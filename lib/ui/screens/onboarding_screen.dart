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
  int _step = 0;
  bool _whatsappLinked = false;

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
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: IndexedStack(
                alignment: Alignment.center,
                index: _step,
                children: [
                  _buildPlatformChoiceStep(),
                  _buildGoogleSignInStep(),
                  _buildWhatsAppStep(),
                  _buildCompleteStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlatformChoiceStep() {
    if (PlatformDetect.isWeb) {
      return _buildWebPlatformChoice();
    }
    return _buildAppWelcome();
  }

  Widget _buildWebPlatformChoice() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Brand text only — video is the visual
          Text(
            'Spliti5',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              shadows: [
                Shadow(blurRadius: 20, color: const Color(0xFF667eea).withValues(alpha: 0.5)),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 800.ms).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: 600.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 12),
          Text(
            'Track expenses with your group.\nFair splits, zero awkwardness.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
          const SizedBox(height: 48),

          // Download App card
          _GlassCard(
            onTap: () => _downloadApk(),
            icon: Icons.phone_android_rounded,
            iconColor: const Color(0xFF667eea),
            title: 'Download the App',
            subtitle: 'Best experience — offline, notifications, camera',
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.05),
          const SizedBox(height: 14),

          // Continue on Web card
          _GlassCard(
            onTap: () => setState(() => _step = 1),
            icon: Icons.language_rounded,
            iconColor: const Color(0xFF764ba2),
            title: 'Continue on Web',
            subtitle: 'No install needed — works in any browser',
          ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.05),
          const SizedBox(height: 28),
          Text(
            'Both versions share the same account & data',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAppWelcome() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Spliti5',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
              shadows: [
                Shadow(blurRadius: 20, color: const Color(0xFF667eea).withValues(alpha: 0.5)),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 800.ms).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: 600.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 14),
          Text(
            'Track expenses with your group.\nFair splits, zero awkwardness.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => setState(() => _step = 1),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
        ],
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

  Widget _buildGoogleSignInStep() {
    final auth = ref.watch(authServiceProvider);

    if (auth.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Spliti5',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sign in with Google',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your account is used for:\n'
            '• Storing trip photos in Google Drive\n'
            '• Syncing your expenses across devices\n'
            '• Same account on web & app',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          if (!auth.isSignedIn) const SignInButton(),
        ],
      ),
    );
  }

  Widget _buildWhatsAppStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_outlined, color: Color(0xFF25D366), size: 36),
          ),
          const SizedBox(height: 24),
          Text(
            'Link WhatsApp',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'WhatsApp is used for:\n'
            '• Trip group communication\n'
            '• Expense notifications\n'
            '• Daily balance summaries',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          if (_whatsappLinked)
            Column(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF25D366), size: 48),
                const SizedBox(height: 12),
                Text('WhatsApp linked!', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() => _step = 3),
                  child: const Text('Continue'),
                ),
              ],
            )
          else
            Column(
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final whatsapp = ref.read(whatsAppServiceProvider);
                    final installed = await whatsapp.isWhatsAppInstalled();
                    if (installed) {
                      await whatsapp.createGroup(tripName: 'Test', inviteCode: 'TEST00');
                    }
                    if (mounted) setState(() => _whatsappLinked = true);
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Link WhatsApp'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _step = 3),
                  child: Text('Skip for now', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline, color: Color(0xFF667eea), size: 52),
          ),
          const SizedBox(height: 32),
          Text(
            "You're all set!",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first trip and invite your group.\n'
            'Photos will be stored in Google Drive.\n'
            'Updates will be sent on WhatsApp.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), height: 1.6),
          ),
          const Spacer(),
          if (PlatformDetect.isWeb)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_android, size: 18, color: Colors.white.withValues(alpha: 0.6)),
                    const SizedBox(width: 8),
                    Text(
                      'Download the app for the full experience',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                    TextButton(
                      onPressed: _downloadApk,
                      child: const Text('Install'),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF667eea),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Start Splitting', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Glass-card button for the onboarding choices.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
