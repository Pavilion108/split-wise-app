import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../services/admin_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.adminEmail});
  final String adminEmail;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tab = 0;
  Map<String, int> _stats = {};
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic> _inviteCodes = {};
  Map<String, dynamic> _invites = {};
  bool _loading = true;
  String? _selectedTripId;
  List<Map<String, dynamic>> _selectedTripOps = [];
  List<Map<String, dynamic>> _selectedTripMembers = [];
  StreamSubscription? _opsSub;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _opsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final admin = AdminService.instance;
      final results = await Future.wait([
        admin.getDatabaseStats(),
        admin.getAllTrips(),
        admin.getAllUsers(),
        admin.getAllInviteCodes(),
        admin.getAllInvites(),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, int>;
          _trips = results[1] as List<Map<String, dynamic>>;
          _users = results[2] as List<Map<String, dynamic>>;
          _inviteCodes = results[3] as Map<String, dynamic>;
          _invites = results[4] as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectTrip(String tripId) async {
    setState(() {
      _selectedTripId = tripId;
      _selectedTripOps = [];
      _selectedTripMembers = [];
    });
    try {
      final admin = AdminService.instance;
      final results = await Future.wait([
        admin.getTripOps(tripId),
        admin.getTripMembers(tripId),
      ]);
      if (mounted) {
        setState(() {
          _selectedTripOps = results[0] as List<Map<String, dynamic>>;
          _selectedTripMembers = results[1] as List<Map<String, dynamic>>;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings, color: cs.error, size: 22),
            const SizedBox(width: 8),
            const Text('Admin Dashboard'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh all data',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selectedTripId != null
              ? _buildTripDetail(cs)
              : _buildOverview(cs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          _tab = i;
          _selectedTripId = null;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.directions_bus_outlined), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.vpn_key_outlined), label: 'Codes'),
          NavigationDestination(icon: Icon(Icons.mail_outline), label: 'Invites'),
        ],
      ),
    );
  }

  Widget _buildOverview(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats cards
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _statCard('Trips', '${_stats['trips'] ?? 0}', Icons.directions_bus, cs.primary),
            _statCard('Users', '${_stats['users'] ?? 0}', Icons.people, cs.tertiary),
            _statCard('Invite Codes', '${_stats['invite_codes'] ?? 0}', Icons.vpn_key, Colors.orange),
            _statCard('Email Trips', '${_stats['email_trips'] ?? 0}', Icons.email, Colors.teal),
          ],
        ),
        const SizedBox(height: 20),
        // Admin info
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.error,
              child: const Icon(Icons.shield, color: Colors.white),
            ),
            title: const Text('Admin Access', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(widget.adminEmail),
            trailing: Chip(
              label: const Text('Full Access'),
              backgroundColor: cs.errorContainer,
              labelStyle: TextStyle(color: cs.onErrorContainer),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Quick actions
        Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.download, size: 18),
              label: const Text('Export All Data'),
              onPressed: _exportAllData,
            ),
            ActionChip(
              avatar: const Icon(Icons.delete_forever, size: 18),
              label: const Text('Delete All Trips'),
              onPressed: _deleteAllTrips,
            ),
            ActionChip(
              avatar: const Icon(Icons.people_alt, size: 18),
              label: const Text('View All Members'),
              onPressed: _viewAllMembers,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripsList(ColorScheme cs) {
    if (_trips.isEmpty) return const Center(child: Text('No trips found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _trips.length,
      itemBuilder: (_, i) {
        final t = _trips[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primary,
              child: Text('${(t['name'] as String)[0]}', style: const TextStyle(color: Colors.white)),
            ),
            title: Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${t['memberCount']} members  |  ${t['opsCount']} ops'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  tooltip: 'View details',
                  onPressed: () => _selectTrip(t['id'] as String),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 20, color: cs.error),
                  tooltip: 'Delete permanently',
                  onPressed: () => _confirmDeleteTrip(t),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUsersList(ColorScheme cs) {
    if (_users.isEmpty) return const Center(child: Text('No users found'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (_, i) {
        final u = _users[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${(u['displayName'] ?? '?')[0]}'),
            ),
            title: Text(u['displayName'] ?? 'Unknown'),
            subtitle: Text(u['emailLower'] ?? ''),
            trailing: IconButton(
              icon: Icon(Icons.delete, size: 20, color: cs.error),
              onPressed: () => _confirmDeleteUser(u),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInviteCodesList(ColorScheme cs) {
    if (_inviteCodes.isEmpty) return const Center(child: Text('No invite codes'));
    final entries = _inviteCodes.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final data = Map<String, dynamic>.from(e.value as Map);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.vpn_key),
            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
            subtitle: Text('Trip: ${data['tripId'] ?? 'Unknown'}'),
            trailing: IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: e.key));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Code ${e.key} copied')));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildInvitesList(ColorScheme cs) {
    if (_invites.isEmpty) return const Center(child: Text('No invites'));
    final userEntries = _invites.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: userEntries.length,
      itemBuilder: (_, i) {
        final userEntry = userEntries[i];
        final trips = Map<String, dynamic>.from(userEntry.value as Map);
        return Card(
          child: ExpansionTile(
            leading: const Icon(Icons.mail),
            title: Text('User: ${userEntry.key}'),
            subtitle: Text('${trips.length} invite(s)'),
            children: trips.entries.map((te) {
              final tripData = Map<String, dynamic>.from(te.value as Map);
              return ListTile(
                title: Text('Trip: ${te.key}'),
                subtitle: Text('Status: ${tripData['status'] ?? 'unknown'}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, size: 18, color: cs.error),
                  onPressed: () async {
                    await AdminService.instance.deleteInvite(userEntry.key, te.key);
                    _loadData();
                  },
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTripDetail(ColorScheme cs) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: cs.primaryContainer.withValues(alpha: 0.3),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedTripId = null),
              ),
              const SizedBox(width: 8),
              Text('Trip: $_selectedTripId', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${_selectedTripMembers.length} members | ${_selectedTripOps.length} ops'),
            ],
          ),
        ),
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(tabs: [Tab(text: 'Members'), Tab(text: 'Ops (Audit Log)')]),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Members
                      _selectedTripMembers.isEmpty
                          ? const Center(child: Text('No members'))
                          : ListView.builder(
                              itemCount: _selectedTripMembers.length,
                              itemBuilder: (_, i) {
                                final m = _selectedTripMembers[i];
                                return ListTile(
                                  leading: CircleAvatar(child: Text('${(m['name'] ?? '?')[0]}')),
                                  title: Text(m['name'] ?? ''),
                                  subtitle: Text('Email: ${m['emailLower'] ?? 'N/A'}'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, size: 18, color: cs.error),
                                    onPressed: () async {
                                      await AdminService.instance.deleteMember(_selectedTripId!, m['id'] as String);
                                      _selectTrip(_selectedTripId!);
                                    },
                                  ),
                                );
                              },
                            ),
                      // Ops
                      _selectedTripOps.isEmpty
                          ? const Center(child: Text('No ops'))
                          : ListView.builder(
                              itemCount: _selectedTripOps.length,
                              itemBuilder: (_, i) {
                                final op = _selectedTripOps[i];
                                final ts = op['lamportTs'] ?? 0;
                                final type = op['opType'] ?? '';
                                final author = op['authorDevice'] ?? '';
                                return ListTile(
                                  leading: Icon(
                                    type == 'member' ? Icons.person :
                                    type == 'expense' ? Icons.receipt :
                                    type == 'settlement' ? Icons.payment :
                                    Icons.code,
                                    size: 20,
                                  ),
                                  title: Text(type, style: const TextStyle(fontSize: 14)),
                                  subtitle: Text('TS: $ts | Author: ${author.substring(0, author.length > 8 ? 8 : author.length)}...'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, size: 16, color: cs.error),
                                    onPressed: () async {
                                      await AdminService.instance.deleteOp(_selectedTripId!, op['id'] as String);
                                      _selectTrip(_selectedTripId!);
                                    },
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTrip(Map<String, dynamic> trip) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip Permanently?'),
        content: Text('This will permanently delete "${trip['name']}" and ALL its data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await AdminService.instance.deleteTripPermanently(trip['id'] as String);
      _loadData();
    }
  }

  Future<void> _confirmDeleteUser(Map<String, dynamic> user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text('Delete "${user['displayName']}" from directory?'),
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
    if (ok == true) {
      await AdminService.instance.deleteUser(user['googleId'] as String);
      _loadData();
    }
  }

  Future<void> _exportAllData() async {
    try {
      final data = await AdminService.instance.getFullDatabaseSnapshot();
      final json = data.toString();
      await Clipboard.setData(ClipboardData(text: json));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database snapshot copied to clipboard')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllTrips() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('DELETE ALL TRIPS?'),
        content: const Text('This will permanently delete ALL trips from the database. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );
    if (ok == true) {
      for (final trip in _trips) {
        await AdminService.instance.deleteTripPermanently(trip['id'] as String);
      }
      _loadData();
    }
  }

  void _viewAllMembers() {
    _tab = 1;
    setState(() {});
  }
}
