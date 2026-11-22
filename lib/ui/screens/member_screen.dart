import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/avatar_service.dart';
import '../../ui/widgets/avatar_picker.dart';
import '../../ui/widgets/responsive_layout.dart';

class MemberScreen extends ConsumerStatefulWidget {
  const MemberScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends ConsumerState<MemberScreen> {
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  String _pickedAvatar = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _doSearch(q);
    });
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final res = await ref.read(userDirectoryServiceProvider).search(q);
      if (mounted) setState(() => _searchResults = res);
    } catch (_) {
      if (mounted) setState(() => _searchResults = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(tripRepositoryProvider);
    final myDeviceId = ref.watch(deviceIdentityProvider).id;

    return Scaffold(
      appBar: AppBar(title: const Text('Members', style: TextStyle(fontFamily: 'Liberation Sans'))),
      body: CenteredBody(
        child: StreamBuilder<List<Member>>(
          stream: repo.watchMembers(widget.tripId),
          builder: (context, snapshot) {
            final list = snapshot.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          labelText: 'Search by email or name',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2)),
                                )
                              : _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _searchResults = []);
                                      },
                                    )
                                  : null,
                          border: const OutlineInputBorder(),
                          hintText: 'Start typing email...',
                        ),
                        onChanged: _onSearchChanged,
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final u = _searchResults[i];
                              final av = AvatarService.byId(
                                  u['avatarAsset'] ?? '');
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: av != null
                                      ? Color(av['color'] as int)
                                          .withValues(alpha: 0.2)
                                      : Colors.grey.shade200,
                                  child: Text(
                                    av != null
                                        ? av['emoji'] as String
                                        : (u['displayName'] ?? '?')[0],
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                title:
                                    Text(u['displayName'] ?? ''),
                                subtitle: Text(
                                  u['emailMasked'] ?? u['email'] ?? '',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: FilledButton.tonalIcon(
                                  onPressed: () => _invite(u),
                                  icon: const Icon(Icons.send_rounded,
                                      size: 16),
                                  label: const Text('Invite'),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final picked = await showAvatarPicker(
                                  context, _pickedAvatar);
                              if (picked != null)
                                setState(() => _pickedAvatar = picked);
                            },
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: _pickedAvatar.isNotEmpty
                                  ? AvatarService.colorFor(_pickedAvatar)
                                      .withValues(alpha: 0.2)
                                  : Colors.grey.shade200,
                              child: Text(
                                _pickedAvatar.isNotEmpty
                                    ? AvatarService.emojiFor(_pickedAvatar)
                                    : '🙂',
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _nameCtrl,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                  labelText: 'Or add manual name'),
                              onSubmitted: (_) => _add(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                              onPressed: _add,
                              icon: const Icon(Icons.add),
                              label: const Text('Add')),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final isMe = m.deviceId == myDeviceId;
                      final av = AvatarService.byId(m.avatarAsset);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: av != null
                              ? Color(av['color'] as int)
                              : Color(m.avatarColor),
                          child: Text(
                            av != null
                                ? av['emoji'] as String
                                : (m.name.isNotEmpty
                                    ? m.name[0].toUpperCase()
                                    : '?'),
                            style: const TextStyle(
                                fontFamily: 'Liberation Sans',
                                color: Colors.white,
                                fontSize: 16),
                          ),
                        ),
                        title: Text(m.name),
                        subtitle: isMe
                            ? const Text('You (this device)')
                            : (m.emailLower.isNotEmpty
                                ? Text(m.emailLower,
                                    style: const TextStyle(fontSize: 11))
                                : null),
                        trailing: isMe
                            ? IconButton(
                                icon: const Icon(Icons.edit_rounded),
                                onPressed: () async {
                                  final picked = await showAvatarPicker(
                                      context, m.avatarAsset);
                                  if (picked != null) {
                                    await ref
                                        .read(tripRepositoryProvider)
                                        .updateMemberAvatar(
                                            m.id, picked);
                                    await ref
                                        .read(
                                            userDirectoryServiceProvider)
                                        .setAvatarAsset(picked);
                                  }
                                })
                            : IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline),
                                onPressed: () => _remove(m)),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _add() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    // Check for duplicate: don't add a member with the same name in this trip.
    final existing = ref.read(tripRepositoryProvider).watchMembers(widget.tripId);
    final currentMembers = await existing.first;
    final duplicate =
        currentMembers.any((m) => m.name.toLowerCase() == name.toLowerCase());
    if (duplicate) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('"$name" is already a member')));
      }
      return;
    }

    _nameCtrl.clear();
    final deviceId = ref.read(deviceIdentityProvider).id;
    final av = _pickedAvatar;
    setState(() => _pickedAvatar = '');
    await ref.read(tripRepositoryProvider).addMember(
          tripId: widget.tripId,
          name: name,
          deviceId: deviceId,
          avatarAsset: av,
          avatarColor:
              av.isNotEmpty ? AvatarService.colorFor(av).value : 0xFF43A047,
        );

    // Recompute splits for all existing equal-split expenses.
    await ref
        .read(expenseRepositoryProvider)
        .recomputeEqualSplits(widget.tripId);
  }

  Future<void> _invite(Map<String, dynamic> user) async {
    final trip = await ref.read(tripRepositoryProvider).getTrip(widget.tripId);
    if (trip == null) return;

    // Derive a friendly name from displayName or email.
    final email = (user['email'] ?? user['emailLower'] ?? '').toString();
    var name = (user['displayName'] ?? '').toString().trim();
    if (name.isEmpty && email.isNotEmpty) {
      final local = email.split('@').first;
      name = local[0].toUpperCase() +
          local.substring(1).replaceAll(RegExp(r'[._-]'), ' ');
    }

    // Create member row first so the trip appears for the invited user.
    final member = await ref.read(tripRepositoryProvider).addMember(
          tripId: widget.tripId,
          name: name,
          deviceId: '', // Will be filled when the user actually joins
          avatarAsset: user['avatarAsset'] ?? '',
          avatarColor: 0xFF1E88E5,
          googleId: user['googleId'] ?? '',
          emailLower: email.toLowerCase(),
        );

    // Send invite notification + register trip for the invited user.
    await ref.read(cloudSyncProvider).sendInvite(
          tripId: widget.tripId,
          invitedGoogleId: user['googleId'] ?? '',
          invitedEmail: email,
          tripName: trip.name,
          memberName: name,
          memberId: member.id,
        );

    // Recompute splits for all existing equal-split expenses.
    await ref
        .read(expenseRepositoryProvider)
        .recomputeEqualSplits(widget.tripId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name added to ${trip.name}')));
      setState(() => _searchResults = []);
      _searchCtrl.clear();
    }
  }

  Future<void> _remove(Member m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove ${m.name}?'),
        content: const Text(
            "Past expenses remain, but they won't share future splits."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tripRepositoryProvider).removeMember(m.id);
    }
  }
}
