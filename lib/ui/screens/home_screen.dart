import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../core/sync/invite_code.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import 'trip_dashboard_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Intelligently restore any trips from the cloud if the local database was wiped
    Future.microtask(() => ref.read(cloudSyncProvider).restoreTrips());
  }

  @override
  Widget build(BuildContext context) {
    final trips = ref.watch(tripRepositoryProvider).watchTrips();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Wise',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<Trip>>(
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
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 96, top: 8),
            itemCount: list.length,
            itemBuilder: (_, i) => _TripTile(trip: list[i]),
          );
        },
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
    final message = InviteCode.buildWhatsAppMessage(
      code: trip.inviteCode,
      tripName: trip.name,
      creatorName: 'You',
      baseCurrency: trip.baseCurrency,
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Trip Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this invite code with your group:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
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
            const SizedBox(height: 16),
            Text(
              'Or share via WhatsApp/Gmail',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Share.share(message);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
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

  Future<void> _joinTrip(BuildContext context, WidgetRef ref) async {
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                decoration: const InputDecoration(
                  labelText: 'Invite code',
                  hintText: 'ABC123',
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
              final code = codeCtrl.text.trim();
              final name = nameCtrl.text.trim();
              if (code.isEmpty || name.isEmpty) return;

              final deviceId = ref.read(deviceIdentityProvider).id;
              final trip = await ref.read(tripRepositoryProvider).joinTrip(
                    inviteCode: code,
                    memberName: name,
                    deviceId: deviceId,
                  );

              if (trip == null) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid invite code')),
                  );
                }
                return;
              }

              if (ctx.mounted) {
                Navigator.pop(ctx, true);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => TripDashboardScreen(
                    tripId: trip.id,
                    tripName: trip.name,
                  ),
                ));
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    return Card(
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
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              TripDashboardScreen(tripId: trip.id, tripName: trip.name),
        )),
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
