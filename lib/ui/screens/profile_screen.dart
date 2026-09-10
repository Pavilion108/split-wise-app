import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/admin_service.dart';
import '../../services/photo_upload_service.dart';
import 'admin_screen.dart';
import '../../services/avatar_service.dart';
import '../../services/upi_launcher.dart';
import '../../services/version_service.dart';
import '../widgets/avatar_picker.dart';
import '../widgets/sponsor_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authServiceProvider);
    final cs = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String themeLabel(ThemeMode m) => switch (m) {
          ThemeMode.light => 'Light',
          ThemeMode.dark => 'Dark',
          ThemeMode.system => 'System',
        };
    IconData themeIcon(ThemeMode m) => switch (m) {
          ThemeMode.light => Icons.light_mode_rounded,
          ThemeMode.dark => Icons.dark_mode_rounded,
          ThemeMode.system => Icons.brightness_auto_rounded,
        };

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --- User Card ---
          FutureBuilder<String>(
            future: ref.read(userDirectoryServiceProvider).avatarAsset,
            builder: (ctx, snap) {
              final avatarId = snap.data ?? '';
              final av = AvatarService.byId(avatarId);
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark ? [const Color(0xFFE8ECF4), const Color(0xFFF4F6FB)] : [cs.primary, cs.primary.withValues(alpha: 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: cs.primary.withValues(alpha: isDark ? 0.15 : 0.25), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        // Show dialog with two options: emoji avatar or photo upload
                        final choice = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Change Avatar'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.emoji_emotions_outlined),
                                  title: const Text('Choose Emoji Avatar'),
                                  onTap: () => Navigator.pop(ctx, 'emoji'),
                                ),
                                ListTile(
                                  leading: const Icon(Icons.camera_alt_outlined),
                                  title: const Text('Upload Photo'),
                                  subtitle: const Text('From gallery or camera'),
                                  onTap: () => Navigator.pop(ctx, 'photo'),
                                ),
                                if (avatarId.isNotEmpty || (auth.currentUser?.photoUrl?.isNotEmpty == true && avatarId.isEmpty))
                                  ListTile(
                                    leading: const Icon(Icons.close, color: Colors.red),
                                    title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                                    onTap: () => Navigator.pop(ctx, 'remove'),
                                  ),
                              ],
                            ),
                          ),
                        );

                        if (choice == 'emoji') {
                          final picked = await showAvatarPicker(context, avatarId);
                          if (picked != null) {
                            await ref.read(userDirectoryServiceProvider).setAvatarAsset(picked);
                            final user = auth.currentUser;
                            if (user != null) {
                              await ref.read(userDirectoryServiceProvider).upsertProfile(googleId: user.id, email: user.email, displayName: user.displayName ?? '', photoUrl: user.photoUrl ?? '', avatarAsset: picked);
                            }
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Avatar updated to ${AvatarService.byId(picked)?['name']}')));
                            if (ctx.mounted) (ctx as Element).markNeedsBuild();
                          }
                        } else if (choice == 'photo') {
                          final bytes = await PhotoUploadService.instance.pickImage();
                          if (bytes != null && auth.currentUser != null) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading photo...')));
                            final url = await PhotoUploadService.instance.uploadProfilePhoto(
                              googleId: auth.currentUser!.id,
                              imageBytes: bytes,
                            );
                            if (url != null) {
                              // Clear emoji avatar since we now have a photo
                              await ref.read(userDirectoryServiceProvider).setAvatarAsset('');
                              final user = auth.currentUser;
                              if (user != null) {
                                await ref.read(userDirectoryServiceProvider).upsertProfile(
                                  googleId: user.id,
                                  email: user.email,
                                  displayName: user.displayName ?? '',
                                  photoUrl: url,
                                  avatarAsset: '',
                                );
                              }
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo uploaded!')));
                              if (ctx.mounted) (ctx as Element).markNeedsBuild();
                            } else {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed. Try again.')));
                            }
                          }
                        } else if (choice == 'remove') {
                          await ref.read(userDirectoryServiceProvider).setAvatarAsset('');
                          if (auth.currentUser != null) {
                            await ref.read(userDirectoryServiceProvider).upsertProfile(
                              googleId: auth.currentUser!.id,
                              email: auth.currentUser!.email,
                              displayName: auth.currentUser!.displayName ?? '',
                              photoUrl: auth.currentUser!.photoUrl ?? '',
                              avatarAsset: '',
                            );
                          }
                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar reset to default')));
                          if (ctx.mounted) (ctx as Element).markNeedsBuild();
                        }
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: av != null ? Color(av['color'] as int) : (isDark ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.2)),
                            backgroundImage: av == null && auth.currentUser?.photoUrl != null ? NetworkImage(auth.currentUser!.photoUrl!) : null,
                            child: av != null
                                ? Text(av['emoji'] as String, style: const TextStyle(fontSize: 32))
                                : (auth.currentUser?.photoUrl == null ? Text((auth.currentUser?.displayName ?? 'U')[0].toUpperCase(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: isDark ? Colors.black : Colors.white)) : null),
                          ).animate().scale(duration: 200.ms, curve: Curves.easeOut),
                          Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: Colors.white, size: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Tap avatar to choose', style: TextStyle(color: isDark ? Colors.black.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final nameCtrl = TextEditingController(text: auth.currentUser?.displayName ?? '');
                        final newName = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Edit Name'),
                            content: TextField(
                              controller: nameCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(labelText: 'Display name'),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, nameCtrl.text.trim()), child: const Text('Save')),
                            ],
                          ),
                        );
                        if (newName != null && newName.isNotEmpty && newName != auth.currentUser?.displayName) {
                          final user = auth.currentUser;
                          if (user != null) {
                            final av2 = await ref.read(userDirectoryServiceProvider).avatarAsset;
                            await ref.read(userDirectoryServiceProvider).upsertProfile(
                              googleId: user.id,
                              email: user.email,
                              displayName: newName,
                              photoUrl: user.photoUrl ?? '',
                              avatarAsset: av2,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name updated to "$newName"')));
                              (ctx as Element).markNeedsBuild();
                            }
                          }
                        }
                      },
                      child: Text(
                        auth.currentUser?.displayName ?? 'User',
                        style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(auth.currentUser?.email ?? '', style: TextStyle(color: isDark ? Colors.black.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // --- Settings Section ---
          _sectionHeader(context, 'Settings'),
          _SettingsTile(
            icon: Icons.palette_rounded,
            title: 'Theme',
            subtitle: themeLabel(settings.themeMode),
            trailing: Icon(themeIcon(settings.themeMode), color: cs.outline, size: 20),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Theme'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final mode in ThemeMode.values)
                        RadioListTile<ThemeMode>(
                          title: Text(themeLabel(mode)),
                          value: mode,
                          groupValue: settings.themeMode,
                          onChanged: (v) {
                            if (v != null) settings.setThemeMode(v);
                            Navigator.pop(ctx);
                          },
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.notifications_rounded,
            title: 'Notifications',
            subtitle: 'Expense alerts & settlement reminders',
            trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Notifications'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay updated on your trips:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 12),
                      Text(
                        '\u2022  New expense added to your trip\n'
                        '\u2022  Settlement recorded against your balance\n'
                        '\u2022  New member joined the trip\n'
                        '\u2022  Trip marked as complete\n'
                        '\u2022  Daily expense summary (upcoming)',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Push notifications are delivered via Firebase Cloud Messaging. '
                        'You can disable them in your device settings at any time.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // --- Data Section ---
          _sectionHeader(context, 'Data'),
          _SettingsTile(
            icon: Icons.cloud_sync_rounded,
            title: 'Cloud Sync',
            subtitle: 'Sync trips across devices',
            trailing: Icon(Icons.check_circle_rounded, color: AppColors.received, size: 20),
          ),
          _SettingsTile(
            icon: Icons.download_rounded,
            title: 'Export Data',
            subtitle: 'Download all trip data as PDF',
            trailing: Icon(Icons.chevron_right_rounded, color: cs.outline),
            onTap: () => _exportData(context, ref),
          ),
          _SettingsTile(
            icon: Icons.delete_sweep_rounded,
            title: 'Delete All Trips',
            subtitle: 'Remove all trips from this device',
            trailing: Icon(Icons.chevron_right_rounded, color: cs.error),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete All Trips?'),
                  content: const Text('This will hide all trips from your home screen. You can rejoin any trip with its invite code.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(backgroundColor: cs.error),
                      child: const Text('Delete All'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                final count = await ref.read(tripRepositoryProvider).deleteAllTrips();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$count trip(s) deleted')));
                }
              }
            },
          ),
          FutureBuilder<bool>(
            future: ref.read(userDirectoryServiceProvider).searchable,
            builder: (ctx, snap) {
              final val = snap.data ?? true;
              return _SettingsTile(
                icon: Icons.search_rounded,
                title: 'Discoverable',
                subtitle: val ? 'Others can find you by email/username' : 'Hidden from search',
                trailing: Switch(value: val, onChanged: (v) async {
                  await ref.read(userDirectoryServiceProvider).setSearchable(v);
                  final user = ref.read(authServiceProvider).currentUser;
                  if (user != null) {
                    final av = await ref.read(userDirectoryServiceProvider).avatarAsset;
                    await ref.read(userDirectoryServiceProvider).upsertProfile(googleId: user.id, email: user.email, displayName: user.displayName ?? '', photoUrl: user.photoUrl ?? '', avatarAsset: av, searchableOverride: v);
                  }
                  if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(v ? 'You are now discoverable' : 'Hidden from search')));
                  (ctx as Element).markNeedsBuild();
                }),
              );
            },
          ),
          const SizedBox(height: 16),

          // --- About Section ---
          _sectionHeader(context, 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: '1.0.0',
            trailing: const SizedBox(),
            onTap: () async {
              final version = await VersionService.getCurrentVersion();
              if (context.mounted) {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Spliti5 v$version'),
                    content: SingleChildScrollView(
                      child: Text(VersionService.getWhatsNew()),
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () {
                          VersionService.markVersionSeen();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Got it!'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          _SettingsTile(
            icon: Icons.privacy_tip_rounded,
            title: 'Privacy Policy',
            subtitle: 'How we protect your data',
            trailing: Icon(Icons.open_in_new_rounded, color: cs.outline, size: 18),
            onTap: () => launchUrl(
              Uri.parse('https://splitwiser-26.web.app/privacy_policy.html'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _SettingsTile(
            icon: Icons.description_rounded,
            title: 'Terms of Service',
            subtitle: 'Rules for using Spliti5',
            trailing: Icon(Icons.open_in_new_rounded, color: cs.outline, size: 18),
            onTap: () => launchUrl(
              Uri.parse('https://splitwiser-26.web.app/terms_of_service.html'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 16),

          // --- Support Section ---
          _sectionHeader(context, 'Support'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.support_agent_rounded, color: cs.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Better Call Vighnesh',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Facing issues, bugs, or need help?\nReach out — we\'ve got your back.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => launchUrl(
                      Uri.parse('mailto:vighnesh.bagal99+split_wise-info@gmail.com'
                          '?subject=${Uri.encodeComponent('Spliti5 — Support Request')}'),
                    ),
                    icon: const Icon(Icons.email_outlined, size: 18),
                    label: const Text('Email Support'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: cs.primary,
                      side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Sponsor / Donate Section ---
          _sectionHeader(context, 'Sponsor a Coffee'),
          const SponsorCard(),
          const SizedBox(height: 24),

          // --- Admin Section (only for admin user) ---
          if (AdminService.isAdmin(auth.currentUser?.email)) ...[
            _sectionHeader(context, 'Admin'),
            _SettingsTile(
              icon: Icons.admin_panel_settings_rounded,
              title: 'Admin Dashboard',
              subtitle: 'Full database controls & monitoring',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminScreen(adminEmail: auth.currentUser?.email ?? ''),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // --- Sign Out ---
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign out?'),
                    content: const Text('You can sign back in anytime with the same Google account.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.owed),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.owed,
                side: const BorderSide(color: AppColors.owed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: cs.outline,
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(tripRepositoryProvider);
    final trips = await repo.watchTrips().first;
    if (trips.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No trips to export')),
        );
      }
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('Spliti5 — Exported Data');
    buffer.writeln('Generated: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('${'=' * 40}\n');

    for (final trip in trips) {
      buffer.writeln('TRIP: ${trip.name}');
      buffer.writeln('Currency: ${trip.baseCurrency}');
      buffer.writeln('Created: ${trip.createdAt.toString().substring(0, 10)}');
      buffer.writeln('Status: ${trip.status}');
      buffer.writeln('-' * 30);

      final members = await repo.watchMembers(trip.id).first;
      buffer.writeln('Members (${members.length}):');
      for (final m in members) {
        buffer.writeln('  • ${m.name}');
      }

      final expenses = await ref.read(expenseRepositoryProvider).watchExpenses(trip.id).first;
      buffer.writeln('\nExpenses (${expenses.length}):');
      double total = 0;
      for (final e in expenses) {
        total += e.amount;
        buffer.writeln('  • ${e.category}: ${formatMoney(e.amount, e.currency)} (${e.note.isNotEmpty ? e.note : 'no note'})');
      }
      buffer.writeln('  TOTAL: ${formatMoney(total, trip.baseCurrency)}');
      buffer.writeln('\n');
    }

    await Share.shareXFiles(
      [],
      text: buffer.toString(),
      subject: 'Spliti5 Data Export',
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported successfully')),
      );
    }
  }

  Future<void> _openUpiPayment(BuildContext context) async {
    final ok = await launchUpi(
      vpa: 'vighnesh.bagal99-1@okicici',
      payeeName: 'Vighnesh Bagal',
      amount: 0,
      note: 'Support Spliti5',
    );
    if (!ok && context.mounted) {
      Clipboard.setData(const ClipboardData(text: 'vighnesh.bagal99-1@okicici'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI ID copied! Open any UPI app to pay.')),
      );
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: cs.primary),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 12, color: cs.outline))
          : null,
      trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right_rounded, color: cs.outline, size: 20) : null),
    );
  }
}
