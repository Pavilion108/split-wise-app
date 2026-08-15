import 'package:flutter/material.dart';

import '../../core/platform/platform_detect.dart';
import '../../core/platform/web_download.dart';

/// Banner shown after web sign-in prompting user to open/download the native app.
class AppInstallBanner extends StatelessWidget {
  const AppInstallBanner({super.key, this.onDismiss});

  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (!PlatformDetect.isWeb) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.phone_android,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get the full experience',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Download the app for offline access, notifications & camera.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _downloadApk(context),
              child: const Text('Install'),
            ),
            if (onDismiss != null)
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadApk(BuildContext context) async {
    final ok = await downloadFile(
      PlatformDetect.apkDownloadUrl,
      fileName: 'split-wise.apk',
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not start download')),
      );
    }
  }
}

/// Full-screen prompt shown when user first visits on web.
/// Offers "Download App" or "Continue on Web" choice.
class PlatformChoiceScreen extends StatelessWidget {
  const PlatformChoiceScreen({
    super.key,
    required this.onContinueWeb,
    required this.onDownloadApp,
  });

  final VoidCallback onContinueWeb;
  final VoidCallback onDownloadApp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: cs.primary,
                  ),
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
                  _ChoiceCard(
                    icon: Icons.phone_android,
                    title: 'Download the App',
                    subtitle: 'Best experience — offline access, notifications, camera',
                    color: cs.primary,
                    onTap: onDownloadApp,
                  ),
                  const SizedBox(height: 16),

                  // Continue on Web card
                  _ChoiceCard(
                    icon: Icons.language,
                    title: 'Continue on Web',
                    subtitle: 'No install needed — works in any browser',
                    color: cs.secondary,
                    onTap: onContinueWeb,
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
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
