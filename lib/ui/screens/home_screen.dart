import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/platform/platform_detect.dart';
import '../../core/sync/invite_code.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/version_service.dart';
import '../widgets/app_install_banner.dart';
import '../widgets/responsive_layout.dart';
import 'profile_screen.dart';
import 'trip_dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialJoinCode});

  final String? initialJoinCode;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showInstallBanner = PlatformDetect.isWeb;
  StreamSubscription<List<Trip>>? _tripSub;

  @override
  void initState() {
    super.initState();
    // Intelligently restore any trips from the cloud if the local database was wiped
    Future.microtask(() => ref.read(cloudSyncProvider).restoreTrips());
    // Check for app updates
    Future.microtask(() => _checkForUpdate());
    // Start real-time listeners for all active trips so updates arrive
    // even when the user is on the home screen.
    Future.microtask(_startListenersForAllTrips);
    // When a remote device adds a member, recompute splits locally.
    Future.microtask(() {
      ref.read(cloudSyncProvider).onMemberAdded = (tripId) {
        ref.read(expenseRepositoryProvider).recomputeEqualSplits(tripId);
      };
    });
    // Repair orphaned splits: expenses synced before the split-creation
    // bug fix have no split rows. Recompute all trips on app load.
    Future.microtask(_repairAllTrips);

    // If we have a pending join code from deep link, auto-open join dialog.
    if (widget.initialJoinCode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _joinTripWithCode(context, ref, widget.initialJoinCode!);
      });
    }
  }

  Future<void> _repairAllTrips() async {
    try {
      final tripRepo = ref.read(tripRepositoryProvider);
      final expenseRepo = ref.read(expenseRepositoryProvider);
      final trips = await tripRepo.watchTrips().first;
      for (final trip in trips) {
        await expenseRepo.recomputeEqualSplits(trip.id);
      }
    } catch (_) {
      // Non-critical — balance may be temporarily inaccurate.
    }
  }

  @override
  void dispose() {
    _tripSub?.cancel();
    ref.read(cloudSyncProvider).stopAllListeners();
    super.dispose();
  }

  /// Listen to the trip list and dynamically manage real-time sync listeners.
  void _startListenersForAllTrips() {
    final tripRepo = ref.read(tripRepositoryProvider);
    _tripSub = tripRepo.watchTrips().listen((trips) {
      if (!mounted) return;
      final cloudSync = ref.read(cloudSyncProvider);
      final activeTripIds = <String>{for (final t in trips) t.id};
      // Start listening for any new trips.
      for (final id in activeTripIds) {
        cloudSync.startListening(id);
      }
      // Stop listening for any trips that were removed.
      // (CloudSyncService.startListening is idempotent.)
    });
  }

  Future<void> _checkForUpdate() async {
    final isNew = await VersionService.isNewVersion();
    if (isNew && mounted) {
      // Small delay to let the screen render first
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        final version = await VersionService.getCurrentVersion();
        if (mounted) {
          showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: Icon(Icons.system_update_rounded, color: Theme.of(context).colorScheme.primary, size: 40),
              title: Text('What\'s New in v$version'),
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripRepositoryProvider).watchTrips();
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final auth = ref.watch(authServiceProvider);
    final myGoogleId = auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Wise',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showInstallBanner)
            AppInstallBanner(
              onDismiss: () => setState(() => _showInstallBanner = false),
            ),
          if (myGoogleId.isNotEmpty)
            StreamBuilder<Map<String, dynamic>>(
              stream: ref.watch(cloudSyncProvider).watchInvites(myGoogleId),
              builder: (ctx, snap) {
                final invites = snap.data ?? {};
                final pending = invites.entries.where((e) => (e.value as Map)['status'] == 'pending').toList();
                if (pending.isEmpty) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2))),
                  child: Column(
                    children: pending.map((e) {
                      final v = Map<String, dynamic>.from(e.value as Map);
                      return ListTile(
                        leading: const Icon(Icons.mail_rounded),
                        title: Text('Invite: ${v['tripName'] ?? e.key}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: const Text('Tap to accept', style: TextStyle(fontSize: 12)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          TextButton(onPressed: () => ref.read(cloudSyncProvider).respondInvite(googleId: myGoogleId, tripId: e.key, accept: false), child: const Text('Decline')),
                          FilledButton(onPressed: () async {
                            await ref.read(cloudSyncProvider).respondInvite(googleId: myGoogleId, tripId: e.key, accept: true);
                            final tripId = e.key;
                            await ref.read(cloudSyncProvider).pullAllOps(tripId);
                            // Recompute splits now that we're a member.
                            await ref.read(expenseRepositoryProvider).recomputeEqualSplits(tripId);
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Joined ${v['tripName']}')));
                          }, child: const Text('Accept')),
                        ]),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveLayout.contentMaxWidth(context),
                ),
                child: StreamBuilder<List<Trip>>(
                  stream: trips,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) return const _EmptyState();
                    if (isDesktop) {
                      return _DesktopTripGrid(trips: list);
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96, top: 8),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _TripTile(trip: list[i])
                          .animate()
                          .fadeIn(duration: 300.ms, delay: (i * 50).ms)
                          .slideX(begin: 0.05, end: 0, duration: 300.ms, delay: (i * 50).ms),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.link),
            selectedIcon: Icon(Icons.link),
            label: 'Join',
          ),
        ],
        onDestinationSelected: (i) {
          if (i == 0) {
            _createTrip(context, ref);
          } else {
            _joinTrip(context, ref);
          }
        },
      ),
    );
  }

  Future<void> _createTrip(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final memberCtrl = TextEditingController();
    final whatsappCtrl = TextEditingController();
    String currency = 'INR';

    await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Trip name',
                    hintText: 'Goa Trip Dec 2026',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  decoration:
                      const InputDecoration(labelText: 'Base currency'),
                  items: [
                    for (final c in kDefaultCurrencies)
                      DropdownMenuItem(
                        value: c['code'],
                        child: Text('${c['code']}  ${c['name']}'),
                      ),
                  ],
                  onChanged: (v) => setState(() => currency = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: memberCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    hintText: 'How members see you',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: whatsappCtrl,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp group link (optional)',
                    hintText: 'https://chat.whatsapp.com/...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    memberCtrl.text.trim().isEmpty) {
                  return;
                }
                final deviceId = ref.read(deviceIdentityProvider).id;
                final repo = ref.read(tripRepositoryProvider);
                final trip = await repo.createTrip(
                  name: nameCtrl.text.trim(),
                  baseCurrency: currency,
                  memberName: memberCtrl.text.trim(),
                  deviceId: deviceId,
                  whatsappGroupLink: whatsappCtrl.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx, true);
                  // Show invite code dialog.
                  _showInviteCode(context, ref, trip);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteCode(BuildContext context, WidgetRef ref, Trip trip) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trip Created!'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share this invite code with your group:'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trip.inviteCode,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                ),
              ),
              const SizedBox(height: 8),
              // Copy code button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                        ClipboardData(text: trip.inviteCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Code'),
                ),
              ),
              const SizedBox(height: 8),
              // Share button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final text = InviteCode.copyableText(
                      code: trip.inviteCode,
                      tripName: trip.name,
                    );
                    SharePlus.instance.share(
                      ShareParams(text: text),
                    );
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                InviteCode.websiteUrl,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.outline,
                  decoration: TextDecoration.underline,
                ),
              ),
              if (trip.driveFolderLink.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text('Drive folder created'),
                    TextButton(
                      onPressed: () =>
                          launchUrl(Uri.parse(trip.driveFolderLink)),
                      child: const Text('Open'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              final whatsapp = ref.read(whatsAppServiceProvider);
              await whatsapp.createGroup(
                tripName: trip.name,
                inviteCode: trip.inviteCode,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.chat),
            label: const Text('WhatsApp'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TripDashboardScreen(
                  tripId: trip.id,
                  tripName: trip.name,
                ),
              ));
            },
            child: const Text('Open Trip'),
          ),
        ],
      ),
    );
  }

  /// Join trip with a pre-filled code (from deep link).
  Future<void> _joinTripWithCode(BuildContext context, WidgetRef ref, String code) async {
    // Wait for auth to settle
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final codeCtrl = TextEditingController(text: code);
    final auth = ref.read(authServiceProvider);
    final googleName = auth.currentUser?.displayName ?? '';
    final nameCtrl = TextEditingController(text: googleName);
    _showJoinDialog(context, ref, codeCtrl, nameCtrl);
  }

  Future<void> _joinTrip(BuildContext context, WidgetRef ref) async {
    final codeCtrl = TextEditingController();
    final auth = ref.read(authServiceProvider);
    final googleName = auth.currentUser?.displayName ?? '';
    final nameCtrl = TextEditingController(text: googleName);
    _showJoinDialog(context, ref, codeCtrl, nameCtrl);
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref, TextEditingController codeCtrl, TextEditingController nameCtrl) {
    bool _loading = false;
    String? _error;

    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Join Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter the invite code from your group:'),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    labelText: 'Invite code',
                    hintText: 'ABC123',
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    hintText: 'How members see you',
                  ),
                ),
                if (_loading) ...[
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('Joining trip...'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _loading ? null : () async {
                final code = codeCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (code.isEmpty || name.isEmpty) {
                  setState(() => _error = 'Both fields are required');
                  return;
                }
                if (!InviteCode.isValid(code)) {
                  setState(() => _error = 'Code must be 6 characters (letters/numbers)');
                  return;
                }

                setState(() { _loading = true; _error = null; });

                try {
                  final deviceId = ref.read(deviceIdentityProvider).id;
                  final auth = ref.read(authServiceProvider);
                  final myGoogleId = auth.currentUser?.id ?? '';
                  final myEmail = auth.currentUser?.email ?? '';
                  final trip = await ref.read(tripRepositoryProvider).joinTrip(
                        inviteCode: code,
                        memberName: name,
                        deviceId: deviceId,
                        googleId: myGoogleId,
                        emailLower: myEmail.toLowerCase(),
                      );

                  if (trip == null) {
                    setState(() { _loading = false; _error = 'Invalid invite code. Check and try again.'; });
                    return;
                  }

                  // Recompute splits now that we're a member.
                  await ref.read(expenseRepositoryProvider).recomputeEqualSplits(trip.id);

                  if (ctx.mounted) {
                    Navigator.pop(ctx, true);
                    _showJoinSuccess(context, ref, trip);
                  }
                } catch (e) {
                  setState(() { _loading = false; _error = 'Error: ${e.toString().replaceAll('Exception: ', '')}'; });
                }
              },
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinSuccess(BuildContext context, WidgetRef ref, Trip trip) {
    final hasDrive = trip.driveFolderLink.isNotEmpty;
    final hasWhatsApp = trip.whatsappGroupLink.isNotEmpty;

    if (!hasDrive && !hasWhatsApp) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) =>
            TripDashboardScreen(tripId: trip.id, tripName: trip.name),
      ));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Joined!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You\'ve joined "${trip.name}"'),
            if (hasDrive) ...[
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Drive Folder'),
                subtitle: const Text('Photos & receipts'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () =>
                    launchUrl(Uri.parse(trip.driveFolderLink)),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (hasWhatsApp) ...[
              ListTile(
                leading: const Icon(Icons.chat_outlined,
                    color: Colors.green),
                title: const Text('WhatsApp Group'),
                subtitle: const Text('Trip chat'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () =>
                    launchUrl(Uri.parse(trip.whatsappGroupLink)),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) =>
                    TripDashboardScreen(tripId: trip.id, tripName: trip.name),
              ));
            },
            child: const Text('Open Trip'),
          ),
        ],
      ),
    );
  }
}

class _TripTile extends ConsumerWidget {
  const _TripTile({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onLongPress: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Trip?'),
            content: Text('"${trip.name}" will be hidden from your trips. You can rejoin later with the invite code.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) {
          await ref.read(tripRepositoryProvider).deleteTrip(trip.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${trip.name}" deleted')));
          }
        }
      },
      child: Card(
        child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            trip.name.isNotEmpty ? trip.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(trip.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(trip.baseCurrency),
        trailing: trip.status == 'completed'
            ? const Chip(
                label: Text('Completed'),
                avatar: Icon(Icons.check_circle, size: 16),
                visualDensity: VisualDensity.compact,
              )
            : const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              TripDashboardScreen(tripId: trip.id, tripName: trip.name),
        )),
      ),
    ),
    );
  }
}

class _DesktopTripGrid extends StatelessWidget {
  const _DesktopTripGrid({required this.trips});
  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: trips.length,
      itemBuilder: (_, i) => _TripCard(trip: trips[i]),
    );
  }
}

class _TripCard extends ConsumerWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              TripDashboardScreen(tripId: trip.id, tripName: trip.name),
        )),
        onLongPress: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Trip?'),
              content: Text('"${trip.name}" will be hidden. You can rejoin with the invite code.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(backgroundColor: cs.error),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
          if (confirmed == true && context.mounted) {
            await ref.read(tripRepositoryProvider).deleteTrip(trip.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cs.primary,
                radius: 24,
                child: Text(
                  trip.name.isNotEmpty ? trip.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                     Text(trip.baseCurrency,
                         style: TextStyle(color: cs.outline, fontSize: 13)),
                     if (trip.status == 'completed')
                       Row(
                         children: [
                           Icon(Icons.check_circle,
                               size: 14, color: Colors.green[700]),
                           const SizedBox(width: 4),
                           Text('Completed',
                               style: TextStyle(
                                   fontSize: 12, color: Colors.green[700])),
                         ],
                       )
                     else if (trip.driveFolderLink.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.folder_outlined,
                              size: 14, color: cs.primary),
                          const SizedBox(width: 4),
                          Text('Drive',
                              style:
                                  TextStyle(fontSize: 12, color: cs.primary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 72, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text('No trips yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Create a trip or join with an invite code.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
