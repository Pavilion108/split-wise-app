import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../ui/widgets/responsive_layout.dart';

class MemberScreen extends ConsumerStatefulWidget {
  const MemberScreen({super.key, required this.tripId});
  final String tripId;

  @override
  ConsumerState<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends ConsumerState<MemberScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(tripRepositoryProvider);
    final myDeviceId = ref.watch(deviceIdentityProvider).id;

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: CenteredBody(
        child: StreamBuilder<List<Member>>(
          stream: repo.watchMembers(widget.tripId),
          builder: (context, snapshot) {
            final list = snapshot.data ?? [];
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Member name',
                          ),
                          onSubmitted: (_) => _add(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
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
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(m.avatarColor),
                        child: Text(
                          m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(m.name),
                      subtitle:
                          isMe ? const Text('You (this device)') : null,
                      trailing: isMe
                          ? null
                          : IconButton(
                              icon:
                                  const Icon(Icons.remove_circle_outline),
                              onPressed: () => _remove(m),
                            ),
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
    _nameCtrl.clear();
    final deviceId = ref.read(deviceIdentityProvider).id;
    await ref.read(tripRepositoryProvider).addMember(
          tripId: widget.tripId,
          name: name,
          deviceId: deviceId,
        );
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
