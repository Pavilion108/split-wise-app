import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import 'trip_dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(tripRepositoryProvider).watchTrips();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split Wise',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTrip(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Trip'),
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
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TripDashboardScreen(
                      tripId: trip.id,
                      tripName: trip.name,
                    ),
                  ));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
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
            'Create a trip, add your group,\nand start splitting expenses.',
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
