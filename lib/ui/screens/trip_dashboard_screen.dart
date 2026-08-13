import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart';
import '../../core/sync/invite_code.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/upi_launcher.dart';
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

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(tripRepositoryProvider);
    final balanceAsync = ref.watch(tripBalanceProvider(widget.tripId));

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
        ],
      ),
      body: StreamBuilder<Trip?>(
        stream: repo.watchTrip(widget.tripId),
        builder: (context, tripSnap) {
          final trip = tripSnap.data;
          if (trip == null) {
            return const Center(child: Text('Trip not found'));
          }
          return StreamBuilder<List<Member>>(
            stream: repo.watchMembers(widget.tripId),
            builder: (context, membersSnap) {
              final members = membersSnap.data ?? [];
              final me = members.firstWhereOrNull(
                (m) => m.deviceId == ref.read(deviceIdentityProvider).id,
              );
              return balanceAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (balance) => _buildPage(trip, members, me, balance),
              );
            },
          );
        },
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
                          final ok = await launchUpi(
                            payeeName: me!.name,
                            amount: net.abs(),
                            note: 'Split Wise settlement',
                          );
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('No UPI app found')),
                            );
                          }
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
    final expensesStream = ref
        .read(expenseRepositoryProvider)
        .watchExpenses(tripId);
    final byId = {for (final m in members) m.id: m};

    return StreamBuilder<List<Expense>>(
      stream: expensesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final expenses = snapshot.data ?? [];
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
    final settlementsStream = ref
        .read(expenseRepositoryProvider)
        .watchSettlements(tripId);
    final byId = {for (final m in members) m.id: m};

    return StreamBuilder<List<Settlement>>(
      stream: settlementsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        final settlements = snapshot.data ?? [];
        if (settlements.isEmpty) {
          return const Center(child: Text('No payments recorded'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96, top: 8),
          itemCount: settlements.length,
          itemBuilder: (_, i) {
            final s = settlements[i];
            final isMine = s.toMemberId == myId;
            return Card(
              child: ListTile(
                leading: Icon(
                  isMine ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isMine ? Colors.green[700] : null,
                ),
                title: Text(
                  '${byId[s.fromMemberId]?.name ?? '?'} -> ${byId[s.toMemberId]?.name ?? '?'}',
                ),
                subtitle: s.partialRemaining != null
                    ? Text(
                        '${formatMoney(s.amount, baseCurrency)}  ${formatMoney(s.partialRemaining!, baseCurrency)} remaining')
                    : Text(formatMoney(s.amount, baseCurrency)),
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
