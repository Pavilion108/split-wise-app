import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/platform/platform_detect.dart';
import '../../providers/app_provider.dart';
import '../widgets/sign_in_button.dart';
import 'home_screen.dart';

/// Onboarding flow.
///
/// **Web users**: Get Started → Choose "Download App" or "Continue on Web"
/// → If Continue: Google Sign-In → "Open in App" banner → Home
///
/// **App users**: Auto-login via device Google account (silent) → Home
/// If no device account: Get Started → Google Sign-In → Home
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  bool _whatsappLinked = false;

  // Steps:
  // 0 = Welcome / Platform Choice (web only shows choice, app shows Get Started)
  // 1 = Google Sign-In
  // 2 = WhatsApp
  // 3 = Complete

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final auth = ref.read(authServiceProvider);
    await auth.checkSignIn();
    if (auth.isSignedIn && mounted) {
      // Auto-login succeeded (device had Google account) — skip to home.
      if (auth.wasAutoLogin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }
      setState(() => _step = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: IndexedStack(
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
    );
  }

  /// Step 0: Platform Choice (web) or Welcome (app).
  Widget _buildPlatformChoiceStep() {
    if (PlatformDetect.isWeb) {
      return _buildWebPlatformChoice();
    }
    return _buildAppWelcome();
  }

  /// Web: "Download App" or "Continue on Web".
  Widget _buildWebPlatformChoice() {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: cs.primary),
          const SizedBox(height: 24),
          Text(
            'Split Wise',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track expenses with your group.\nFair splits, zero awkwardness.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: cs.outline,
                ),
          ),
          const SizedBox(height: 48),

          // Download App card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _downloadApk(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.phone_android,
                          color: cs.primary, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download the App',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Best experience — offline, notifications, camera',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cs.primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Continue on Web card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => setState(() => _step = 1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cs.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.language,
                          color: cs.secondary, size: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue on Web',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No install needed — works in any browser',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cs.secondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Both versions share the same account & data',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.outline,
                ),
          ),
        ],
      ),
    );
  }

  /// App: Simple welcome with Get Started.
  Widget _buildAppWelcome() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Split Wise',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Track expenses with your group.\nFair splits, zero awkwardness.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: () => setState(() => _step = 1),
            child: const Text('Get Started'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _downloadApk() async {
    final uri = Uri.parse(PlatformDetect.apkDownloadUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open download link')),
      );
    }
  }

  Widget _buildGoogleSignInStep() {
    final auth = ref.watch(authServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Sign in with Google',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your account is used for:\n'
            '• Storing trip photos in Google Drive\n'
            '• Syncing your expenses across devices\n'
            '• Same account on web & app',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          if (auth.isSignedIn)
            Column(
              children: [
                if (auth.currentUser?.photoUrl != null)
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(auth.currentUser!.photoUrl!),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Signed in as ${auth.currentUser?.displayName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  auth.currentUser?.email ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() => _step = 2),
                  child: const Text('Continue'),
                ),
              ],
            )
          else
            const SignInButton(),
          if (PlatformDetect.isWeb) ...[
            const SizedBox(height: 24),
            // After web sign-in, prompt to open in app.
            if (auth.isSignedIn) _buildOpenInAppPrompt(),
          ],
        ],
      ),
    );
  }

  Widget _buildOpenInAppPrompt() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.phone_android, color: cs.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Have the app?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Open it to auto-login with this account',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(PlatformDetect.apkDownloadUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text('Install'),
          ),
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
          Icon(
            Icons.chat_outlined,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Link WhatsApp',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'WhatsApp is used for:\n'
            '• Trip group communication\n'
            '• Expense notifications\n'
            '• Daily balance summaries',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          if (_whatsappLinked)
            Column(
              children: [
                Icon(Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary, size: 48),
                const SizedBox(height: 12),
                Text(
                  'WhatsApp linked!',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
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
                      await whatsapp.createGroup(
                        tripName: 'Test',
                        inviteCode: 'TEST00',
                      );
                    }
                    if (mounted) {
                      setState(() => _whatsappLinked = true);
                    }
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Link WhatsApp'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _step = 3),
                  child: const Text('Skip for now'),
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
          Icon(
            Icons.check_circle_outline,
            size: 96,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'You\'re all set!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first trip and invite your group.\n'
            'Photos will be stored in Google Drive.\n'
            'Updates will be sent on WhatsApp.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const Spacer(),
          if (PlatformDetect.isWeb)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_android,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Download the app for the full experience',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: _downloadApk,
                      child: const Text('Install'),
                    ),
                  ],
                ),
              ),
            ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
            child: const Text('Start Splitting'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
