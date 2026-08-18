import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/sync/invite_code.dart';
import '../../core/sync/sync_service.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/balance_engine.dart';
import '../../services/settlement_summary_service.dart';
import '../../services/upi_launcher.dart';
import '../widgets/responsive_layout.dart';
import 'add_expense_screen.dart';
import 'member_screen.dart';

class TripDashboardScreen extends ConsumerStatefulWidget {
  const TripDashboardScreen({
    super.key,
    required this.tripId,
    required this.tripName,
  });

  final String tripId;
  final String tripName;

  @override
  ConsumerState<TripDashboardScreen> createState() =>
      _TripDashboardScreenState();
}

class _TripDashboardScreenState extends ConsumerState<TripDashboardScreen> {
  int _tab = 0;
  StreamSubscription<SyncEvent>? _syncSub;

  @override
  void initState() {
    super.initState();
    // Real-time sync: apply remote ops automatically as they arrive.
    try {
      _syncSub =
          ref.read(cloudSyncProvider).listenForOps(widget.tripId).listen((_) {});
    } catch (_) {
      // Auto-sync unavailable (e.g., offline) — manual Sync button still works.
    }
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(tripBalanceProvider(widget.tripId));
    final tripAsync = ref.watch(tripStreamProvider(widget.tripId));
    final membersAsync = ref.watch(membersStreamProvider(widget.tripId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripName),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync with cloud',
            onPressed: () => _syncWithCloud(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share invite code',
            onPressed: () => _shareInviteCode(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Members',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberScreen(tripId: widget.tripId),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More',
            onSelected: (value) {
              if (value == 'complete') _confirmMarkComplete(context);
              if (value == 'summary') _showSummarySheet(context);
              if (value == 'whatsapp') _showWhatsAppGroupDialog(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'complete',
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('Mark as Complete'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'summary',
                child: ListTile(
                  leading: Icon(Icons.summarize_outlined),
                  title: Text('Share settlement'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'whatsapp',
                child: ListTile(
                  leading: Icon(Icons.group_add_outlined),
                  title: Text('WhatsApp Group'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.contentMaxWidth(context),
          ),
          child: balanceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (balance) => tripAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (trip) {
                if (trip == null) {
                  return const Center(child: Text('Trip not found'));
                }
                final members = membersAsync.value ?? [];
                final me = members.firstWhereOrNull(
                  (m) => m.deviceId == ref.read(deviceIdentityProvider).id,
                );
                return _buildPage(trip, members, me, balance);
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_outlined),
            selectedIcon: Icon(Icons.swap_horiz),
            label: 'Payments',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_expense_fab',
        onPressed: () async {
          final repo = ref.read(tripRepositoryProvider);
          final trip = await repo.getTrip(widget.tripId);
          if (!mounted || trip == null) return;
          final nav = Navigator.of(context);
          await nav.push(
            MaterialPageRoute(
              builder: (_) => AddExpenseScreen(
                tripId: widget.tripId,
                baseCurrency: trip.baseCurrency,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildPage(
    Trip trip,
    List<Member> members,
    Member? me,
    TripBalance? balance,
  ) {
    switch (_tab) {
      case 0:
        return _OverviewTab(
          trip: trip,
          members: members,
          me: me,
          balance: balance,
          onRefresh: () => _syncWithCloud(context),
        );
      case 1:
        return _ExpensesTab(
          tripId: widget.tripId,
          baseCurrency: trip.baseCurrency,
          members: members,
        );
      case 2:
        return _PaymentsTab(
          tripId: widget.tripId,
          baseCurrency: trip.baseCurrency,
          members: members,
          myId: me?.id,
        );
      default:
        return const SizedBox();
    }
  }

  Future<void> _syncWithCloud(BuildContext context) async {
    final cloudSync = ref.read(cloudSyncProvider);
    final result = await cloudSync.fullSync(widget.tripId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Synced: ${result.opsPushed} sent, ${result.opsPulled} received'
                : 'Sync failed: ${result.error}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareInviteCode(BuildContext context) async {
    final repo = ref.read(tripRepositoryProvider);
    final trip = await repo.getTrip(widget.tripId);
    if (trip == null || !mounted) return;

    final message = InviteCode.buildWhatsAppMessage(
      code: trip.inviteCode,
      tripName: trip.name,
      creatorName: 'Me',
      baseCurrency: trip.baseCurrency,
    );

    await Share.share(message);
  }

  Future<void> _showWhatsAppGroupDialog(BuildContext context) async {
    final repo = ref.read(tripRepositoryProvider);
    final trip = await repo.getTrip(widget.tripId);
    if (trip == null || !mounted) return;

    final linkCtrl = TextEditingController(text: trip.whatsappGroupLink);
    final hasLink = trip.whatsappGroupLink.isNotEmpty;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('WhatsApp Group'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasLink) ...[
                Text(
                  'WhatsApp doesn\'t allow apps to create groups '
                  'automatically. To link your trip group:\n\n'
                  '1. Open WhatsApp and create a group named '
                  '"${trip.name}" (or any name).\n'
                  '2. Tap the group name → Invite link → Copy link.\n'
                  '3. Paste it below so everyone in the trip can join.',
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: linkCtrl,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp group invite link',
                  hintText: 'https://chat.whatsapp.com/...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (hasLink)
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                launchUrl(
                  Uri.parse(trip.whatsappGroupLink),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text('Open group'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final link = linkCtrl.text.trim();
              if (link.isEmpty) {
                Navigator.pop(ctx);
                return;
              }
              await repo.setWhatsAppLink(widget.tripId, link);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('WhatsApp group link saved'),
                  ),
                );
              }
            },
            child: Text(hasLink ? 'Update link' : 'Save link'),
          ),
        ],
      ),
    );
  }

  SettlementSummaryService _summaryService() => SettlementSummaryService(
        ref.read(tripRepositoryProvider),
        ref.read(expenseRepositoryProvider),
        ref.read(whatsAppServiceProvider),
      );

  Future<void> _confirmMarkComplete(BuildContext context) async {
    final repo = ref.read(tripRepositoryProvider);
    final trip = await repo.getTrip(widget.tripId);
    if (trip == null || !mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark trip as complete?'),
        content: const Text(
          'This marks the trip as settled. It stays in your history (with a '
          '"Completed" badge) and you can still view it anytime. You can then '
          'share a final settlement summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await repo.markTripComplete(widget.tripId);
      if (mounted) _showSummarySheet(context);
    }
  }

  void _showSummarySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settlement Summary',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Share the final trip settlement with your group.'),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Share to WhatsApp'),
              onTap: () async {
                Navigator.pop(ctx);
                await _summaryService().shareToWhatsApp(widget.tripId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Download PDF'),
              onTap: () async {
                Navigator.pop(ctx);
                final bytes =
                    await _summaryService().buildPdf(widget.tripId);
                await Printing.sharePdf(
                  bytes: bytes,
                  filename: '${widget.tripName}-settlement.pdf',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- Overview Tab ---

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({
    required this.trip,
    required this.members,
    required this.me,
    required this.balance,
    this.onRefresh,
  });

  final Trip trip;
  final List<Member> members;
  final Member? me;
  final TripBalance? balance;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final my = balance?.forMember(me?.id ?? '');
    final net = my?.net ?? 0;
    final isPositive = net > 0;
    final cs = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Trip Expense',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: cs.outline)),
                  const SizedBox(height: 4),
                  Text(
                    formatMoney(balance?.totalExpense ?? 0, trip.baseCurrency),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'You Paid',
                          value: formatMoney(
                              my?.paid ?? 0, trip.baseCurrency),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _Stat(
                          label: 'Your Share',
                          value: formatMoney(
                              my?.share ?? 0, trip.baseCurrency),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isPositive ? Colors.green : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          color: isPositive
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isPositive
                                  ? 'You Should Receive'
                                  : 'You Should Pay'),
                              Text(
                                '${isPositive ? '+' : '-'}${formatMoney(net.abs(), trip.baseCurrency)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isPositive
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!isPositive)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (me == null) return;
                          final transfers = balance == null
                              ? <SuggestedTransfer>[]
                              : suggestSettlements(balance!);
                          final t = transfers.firstWhereOrNull(
                            (x) => x.from == me!.id,
                          );
                          if (t == null) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No pending payment found'),
                                ),
                              );
                            }
                            return;
                          }
                          final payee =
                              members.firstWhereOrNull((m) => m.id == t.to);
                          await _payViaUpiAndRecord(
                            context: context,
                            ref: ref,
                            tripId: trip.id,
                            fromId: me!.id,
                            toId: t.to,
                            payeeName: payee?.name ?? '',
                            amount: t.amount,
                            baseCurrency: trip.baseCurrency,
                          );
                        },
                        icon: const Icon(Icons.qr_code_2),
                        label: const Text('Pay via UPI'),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _MembersTable(
            balance: balance,
            members: members,
            myId: me?.id ?? '',
            baseCurrency: trip.baseCurrency,
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _MembersTable extends StatelessWidget {
  const _MembersTable({
    required this.balance,
    required this.members,
    required this.myId,
    required this.baseCurrency,
  });

  final TripBalance? balance;
  final List<Member> members;
  final String myId;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('Balances',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.8),
              },
              children: [
                _headerRow(),
                for (final m in members) _dataRow(m, balance?.forMember(m.id)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _headerRow() {
    const style = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    return const TableRow(
      children: [
        Padding(
            padding: EdgeInsets.all(8), child: Text('Member', style: style)),
        Padding(
            padding: EdgeInsets.all(8), child: Text('Paid', style: style)),
        Padding(
            padding: EdgeInsets.all(8), child: Text('Share', style: style)),
        Padding(
            padding: EdgeInsets.all(8),
            child: Text('Balance', style: style)),
      ],
    );
  }

  TableRow _dataRow(Member m, Balance? b) {
    final net = b?.net ?? 0;
    final isMe = m.id == myId;
    final color = net > 0.01
        ? Colors.green[700]
        : net < -0.01
            ? Colors.red[700]
            : null;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            isMe ? '${m.name} *' : m.name,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(formatMoney(b?.paid ?? 0, baseCurrency),
              style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(formatMoney(b?.share ?? 0, baseCurrency),
              style: const TextStyle(fontSize: 13)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            net.abs() < 0.01
                ? '--'
                : '${net > 0 ? '+' : '-'}${formatMoney(net.abs(), baseCurrency)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// --- Expenses Tab ---

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({
    required this.tripId,
    required this.baseCurrency,
    required this.members,
  });

  final String tripId;
  final String baseCurrency;
  final List<Member> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesStreamProvider(tripId));
    final byId = {for (final m in members) m.id: m};

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96, top: 8),
          itemCount: expenses.length,
          itemBuilder: (_, i) {
            final e = expenses[i];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(
                      e.category.isNotEmpty ? e.category[0] : '?'),
                ),
                title: Text(e.category,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${byId[e.authorId]?.name ?? '?'}  ${formatMoney(e.amount, e.currency)}'
                  '${e.currency != baseCurrency ? ' -> ${formatMoney(e.convertedAmount, baseCurrency)}' : ''}',
                ),
                trailing: e.editedAt != null
                    ? const Icon(Icons.edit, size: 16, color: Colors.orange)
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

// --- Payments Tab ---

class _PaymentsTab extends ConsumerWidget {
  const _PaymentsTab({
    required this.tripId,
    required this.baseCurrency,
    required this.members,
    this.myId,
  });

  final String tripId;
  final String baseCurrency;
  final List<Member> members;
  final String? myId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementsAsync = ref.watch(settlementsStreamProvider(tripId));
    final byId = {for (final m in members) m.id: m};

    return settlementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (settlements) {
        if (settlements.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No payments recorded'),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _showRecordPaymentDialog(
                  context,
                  ref,
                  tripId,
                  members,
                  baseCurrency,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Record payment'),
              ),
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96, top: 8),
          itemCount: settlements.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showRecordPaymentDialog(
                      context,
                      ref,
                      tripId,
                      members,
                      baseCurrency,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Record payment'),
                  ),
                ),
              );
            }
            final s = settlements[i - 1];
            final isMine = s.toMemberId == myId;
            final methodLabel = s.method.isNotEmpty
                ? (s.method == 'upi' ? 'UPI' : s.method.toUpperCase())
                : 'Payment';
            final refLabel = s.transactionRef.isNotEmpty
                ? '  ·  Ref: ${s.transactionRef.substring(0, 8)}'
                : '';
            return Card(
              child: ListTile(
                leading: Icon(
                  isMine ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isMine ? Colors.green[700] : null,
                ),
                title: Text(
                  '${byId[s.fromMemberId]?.name ?? '?'} -> ${byId[s.toMemberId]?.name ?? '?'}',
                ),
                subtitle: Text(
                  s.partialRemaining != null
                      ? '${formatMoney(s.amount, baseCurrency)}  '
                          '${formatMoney(s.partialRemaining!, baseCurrency)} remaining'
                          '$refLabel'
                      : '${formatMoney(s.amount, baseCurrency)}  ·  $methodLabel$refLabel',
                ),
                trailing: isMine
                    ? Text(formatMoney(s.amount, baseCurrency),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700]))
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

/// Launch a UPI intent and, after the user confirms, log the settlement.
///
/// UPI apps do NOT reliably return a verified transaction status to the caller,
/// so we never auto-claim success — the user confirms, and we store our own
/// generated reference id + timestamp for the audit trail.
Future<void> _payViaUpiAndRecord({
  required BuildContext context,
  required WidgetRef ref,
  required String tripId,
  required String fromId,
  required String toId,
  required String payeeName,
  required double amount,
  required String baseCurrency,
}) async {
  final refId = const Uuid().v4();
  final ok = await launchUpi(
    payeeName: payeeName,
    amount: amount,
    note: 'Split Wise settlement $refId',
  );
  if (!ok) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No UPI app found')),
      );
    }
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Payment successful?'),
      content: Text(
        'Did the UPI payment of ${formatMoney(amount, baseCurrency)} '
        'complete? We can\'t auto-verify it, so please confirm.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not yet'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Yes, paid'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  await ref.read(expenseRepositoryProvider).addSettlement(
        tripId: tripId,
        fromMemberId: fromId,
        toMemberId: toId,
        amount: amount,
        method: 'upi',
        transactionRef: refId,
        status: 'paid',
        verifiedAt: DateTime.now(),
      );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment logged')),
    );
  }
}

Future<void> _showRecordPaymentDialog(
  BuildContext context,
  WidgetRef ref,
  String tripId,
  List<Member> members,
  String baseCurrency,
) async {
  if (members.length < 2) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two members first')),
      );
    }
    return;
  }

  String fromId = members.first.id;
  String toId = members.last.id;
  String method = 'upi';
  final amountCtrl = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setState) => AlertDialog(
        title: const Text('Record payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: fromId,
                decoration: const InputDecoration(labelText: 'Paid by'),
                items: [
                  for (final m in members)
                    DropdownMenuItem(value: m.id, child: Text(m.name)),
                ],
                onChanged: (v) => setState(() => fromId = v!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: toId,
                decoration: const InputDecoration(labelText: 'Paid to'),
                items: [
                  for (final m in members)
                    DropdownMenuItem(value: m.id, child: Text(m.name)),
                ],
                onChanged: (v) => setState(() => toId = v!),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration:
                    InputDecoration(labelText: 'Amount ($baseCurrency)'),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'upi', label: Text('UPI')),
                  ButtonSegment(value: 'cash', label: Text('Cash')),
                  ButtonSegment(value: 'other', label: Text('Other')),
                ],
                selected: {method},
                onSelectionChanged: (s) => setState(() => method = s.first),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text.trim());
              if (amount == null || amount <= 0 || fromId == toId) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid amount and '
                        'different payer/payee'),
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              if (method == 'upi') {
                final payee =
                    members.firstWhereOrNull((m) => m.id == toId);
                await _payViaUpiAndRecord(
                  context: context,
                  ref: ref,
                  tripId: tripId,
                  fromId: fromId,
                  toId: toId,
                  payeeName: payee?.name ?? '',
                  amount: amount,
                  baseCurrency: baseCurrency,
                );
              } else {
                await ref.read(expenseRepositoryProvider).addSettlement(
                      tripId: tripId,
                      fromMemberId: fromId,
                      toMemberId: toId,
                      amount: amount,
                      method: method,
                      status: 'paid',
                      verifiedAt: DateTime.now(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment logged')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
