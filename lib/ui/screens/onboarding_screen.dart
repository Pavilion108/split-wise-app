import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_provider.dart';
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
      setState(() => _step = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _step,
          children: [
            _buildWelcomeStep(),
            _buildGoogleSignInStep(),
            _buildWhatsAppStep(),
            _buildCompleteStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
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

  Widget _buildGoogleSignInStep() {
    final authState = ref.watch(authStateProvider);

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
            '• Syncing your expenses across devices',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 32),
          authState.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
            data: (state) {
              if (state.isSignedIn) {
                return Column(
                  children: [
                    if (state.user?.photoUrl != null)
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(state.user!.photoUrl!),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Signed in as ${state.user?.displayName}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => _step = 2),
                      child: const Text('Continue'),
                    ),
                  ],
                );
              }
              return FilledButton.icon(
                onPressed: () async {
                  final result = await ref.read(authServiceProvider).signIn();
                  if (result.success && mounted) {
                    setState(() => _step = 2);
                  } else if (result.error != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result.error!)),
                    );
                  }
                },
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text('Sign in with Google'),
              );
            },
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
