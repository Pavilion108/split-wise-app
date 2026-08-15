import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../widgets/responsive_layout.dart';
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
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Wise',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
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
                itemBuilder: (_, i) => _TripTile(trip: list[i]),
              );
            },
          ),
        ),
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
                const SizedBox(height: 8),
              ],
              Text(
                'Or share via WhatsApp/Gmail',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
            label: const Text('Create WhatsApp Group'),
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
                _showJoinSuccess(context, ref, trip);
              }
            },
            child: const Text('Join'),
          ),
        ],
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

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              TripDashboardScreen(tripId: trip.id, tripName: trip.name),
        )),
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
                    if (trip.driveFolderLink.isNotEmpty) ...[
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
