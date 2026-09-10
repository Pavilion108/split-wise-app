import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/sync/invite_code.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../services/avatar_service.dart';
import '../../services/balance_engine.dart';
import '../../services/settlement_summary_service.dart';
import '../../services/upi_launcher.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/trip_background.dart';
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
  void initState() {
    super.initState();
    // Real-time sync: apply remote ops automatically as they arrive.
    // The HomeScreen already started listeners for all trips; this call
    // is a no-op if already listening, ensuring updates arrive even if
    // the user navigated here directly.
    try {
      ref.read(cloudSyncProvider).startListening(widget.tripId);
    } catch (_) {
      // Auto-sync unavailable (e.g., offline) — manual Sync button still works.
    }
    // One-time repair: recompute splits for any expenses that were synced
    // before the split-creation bug was fixed (expenses without split rows).
    _repairOrphanedSplits();
  }

  Future<void> _repairOrphanedSplits() async {
    try {
      await ref.read(expenseRepositoryProvider).recomputeEqualSplits(widget.tripId);
    } catch (_) {
      // Non-critical — balance may be temporarily inaccurate.
    }
  }

  @override
  void dispose() {
    // Do NOT stop listening here — HomeScreen manages the lifecycle.
    // Stopping would kill real-time sync when the user briefly leaves
    // the dashboard (e.g. opening a sub-screen).
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final balanceAsync = ref.watch(tripBalanceProvider(widget.tripId));
    final tripAsync = ref.watch(tripStreamProvider(widget.tripId));
    final membersAsync = ref.watch(membersStreamProvider(widget.tripId));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: TripBackground(
      currencyCode: tripAsync.value?.baseCurrency ?? 'INR',
      child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_rounded, color: Colors.white, size: 18),
            ),
            tooltip: 'WhatsApp Group',
            onPressed: () => _openWhatsAppGroup(context),
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
                  // Wait for members to load — without this, 'me' is null
                  // and all personal stats (paid/share/net) show as 0.
                  final members = membersAsync.value;
                  if (members == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final me = members.firstWhereOrNull(
                    (m) => m.deviceId == ref.read(deviceIdentityProvider).id,
                  );
                  return _buildPage(trip, members, me, balance);
                },
              ),
            ),
          ),
        ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: Colors.black.withValues(alpha: 0.7),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.white.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12);
            }
            return TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.white, size: 24);
            }
            return IconThemeData(color: Colors.white.withValues(alpha: 0.6), size: 24);
          }),
        ),
        child: NavigationBar(
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_expense_fab',
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
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
    ),
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
    // Repair any orphaned splits after syncing.
    await ref.read(expenseRepositoryProvider).recomputeEqualSplits(widget.tripId);
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

    final members = await repo.watchMembers(widget.tripId).first;
    final creator = members.isNotEmpty ? members.first.name : 'Unknown';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Share Invite Code', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            // Code display with copy button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    trip.inviteCode,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share this code with friends',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(ctx).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: trip.inviteCode));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Code copied!')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy Code'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Share options
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share via...'),
              subtitle: const Text('Gmail, Messages, or any app'),
              onTap: () async {
                Navigator.pop(ctx);
                final message = InviteCode.buildShareMessage(
                  code: trip.inviteCode,
                  tripName: trip.name,
                  creatorName: creator,
                  baseCurrency: trip.baseCurrency,
                );
                await Share.share(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: const Text('Share via WhatsApp'),
              onTap: () async {
                Navigator.pop(ctx);
                final message = InviteCode.buildWhatsAppMessage(
                  code: trip.inviteCode,
                  tripName: trip.name,
                  creatorName: creator,
                  baseCurrency: trip.baseCurrency,
                );
                final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(message)}');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsAppGroup(BuildContext context) async {
    final repo = ref.read(tripRepositoryProvider);
    final trip = await repo.getTrip(widget.tripId);
    if (trip == null || !mounted) return;

    final members = await repo.watchMembers(widget.tripId).first;
    final me = members.firstWhereOrNull(
      (m) => m.deviceId == ref.read(deviceIdentityProvider).id,
    );
    final isCreator = me != null && members.isNotEmpty && me.id == members.first.id;

    if (trip.whatsappGroupLink.isEmpty) {
      if (isCreator) {
        // Creator: show dialog to add link
        final controller = TextEditingController();
        final link = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Add WhatsApp Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Create a WhatsApp group for this trip, then paste the invite link here:'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'https://chat.whatsapp.com/...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                child: const Text('Save Link'),
              ),
            ],
          ),
        );
        if (link != null && link.trim().isNotEmpty) {
          await repo.setWhatsAppLink(widget.tripId, link.trim());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('WhatsApp group link saved!')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No WhatsApp group yet. Ask the trip creator to add one.'),
          ),
        );
      }
      return;
    }

    // Link exists: show options
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF25D366),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text('WhatsApp Group', style: Theme.of(ctx).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.open_in_new_rounded),
              title: const Text('Open WhatsApp Group'),
              subtitle: const Text('Join the conversation'),
              onTap: () async {
                Navigator.pop(ctx);
                await launchUrl(
                  Uri.parse(trip.whatsappGroupLink),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            if (isCreator)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Update Group Link'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final controller = TextEditingController(text: trip.whatsappGroupLink);
                  final newLink = await showDialog<String>(
                    context: context,
                    builder: (ctx2) => AlertDialog(
                      title: const Text('Update WhatsApp Link'),
                      content: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'https://chat.whatsapp.com/...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx2, controller.text),
                          child: const Text('Update'),
                        ),
                      ],
                    ),
                  );
                  if (newLink != null && newLink.trim().isNotEmpty) {
                    await repo.setWhatsAppLink(widget.tripId, newLink.trim());
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link updated!')),
                      );
                    }
                  }
                },
              ),
          ],
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trip creator is the first member
    final creator = members.isNotEmpty ? members.first : null;
    final isCreator = me != null && creator != null && me!.id == creator.id;

    // Smart insight based on balance
    String insight = '';
    IconData insightIcon = Icons.lightbulb_outline;
    if (members.length == 1) {
      insight = 'Invite friends to start splitting expenses!';
      insightIcon = Icons.person_add_outlined;
    } else if (balance?.totalExpense == 0) {
      insight = 'Add your first expense to get things rolling.';
      insightIcon = Icons.receipt_long_outlined;
    } else if (net.abs() < 0.01) {
      insight = 'All settled up! Great teamwork.';
      insightIcon = Icons.celebration_outlined;
    } else if (!isPositive) {
      insight = 'Tip: Settle up soon to keep friendships healthy.';
      insightIcon = Icons.tips_and_updates_outlined;
    } else {
      insight = 'You\'re owed money. Remind others to pay via UPI.';
      insightIcon = Icons.account_balance_wallet_outlined;
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // --- Trip Creator Badge ---
          if (creator != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Created by ${isCreator ? 'You' : creator.name}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // --- Summary Hero Card ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFFE8ECF4), const Color(0xFFF4F6FB)]
                    : [cs.primary, cs.primary.withValues(alpha: 0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Trip Expense',
                  style: TextStyle(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatMoney(balance?.totalExpense ?? 0, trip.baseCurrency),
                  style: TextStyle(
                    color: isDark ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 32,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _HeroStat(
                      label: 'You Paid',
                      value: formatMoney(my?.paid ?? 0, trip.baseCurrency),
                      dark: isDark,
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 20),
                    _HeroStat(
                      label: 'Your Share',
                      value: formatMoney(my?.share ?? 0, trip.baseCurrency),
                      dark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPositive
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        color: isDark ? Colors.black87 : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPositive ? 'You Should Receive' : 'You Should Pay',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${isPositive ? '+' : '-'}${formatMoney(net.abs(), trip.baseCurrency)}',
                              style: TextStyle(
                                color: isDark ? Colors.black : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPositive) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (me == null || balance == null) return;
                        _showPayBottomSheet(context, ref, balance!, members, me, trip);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: cs.primary,
                      ),
                       child: const Text('Pay via UPI'),
                    ),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.08, end: 0, duration: 400.ms, delay: 100.ms, curve: Curves.easeOut),
          const SizedBox(height: 12),

          // --- Smart Insight Card ---
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.amber.withValues(alpha: 0.08)
                  : Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(insightIcon, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 350.ms, delay: 250.ms),
          const SizedBox(height: 16),

          // --- Who Owes Whom Card ---
          if (balance != null && balance!.totalExpense > 0) ...[
            _SettlementsCard(
              balance: balance!,
              members: members,
              myId: me?.id ?? '',
              baseCurrency: trip.baseCurrency,
              onPay: (fromId, toId, amount) {
                _showPayBottomSheet(context, ref, balance!, members, me, trip);
              },
            ),
            const SizedBox(height: 16),
          ],

          // --- How It Works Card ---
          _HowItWorksCard(isDark: isDark),
          const SizedBox(height: 16),

          // --- Balances Card ---
          _MembersCard(
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

class _SettlementsCard extends StatelessWidget {
  const _SettlementsCard({
    required this.balance,
    required this.members,
    required this.myId,
    required this.baseCurrency,
    required this.onPay,
  });
  final TripBalance balance;
  final List<Member> members;
  final String myId;
  final String baseCurrency;
  final void Function(String fromId, String toId, double amount) onPay;

  @override
  Widget build(BuildContext context) {
    final transfers = suggestSettlements(balance);
    if (transfers.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String memberName(String id) {
      return members.where((m) => m.id == id).map((m) => m.name).firstOrNull ?? 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Who Owes Whom',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final t in transfers) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${memberName(t.from)} pays ${memberName(t.to)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  formatMoney(t.amount, baseCurrency),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: cs.primary,
                  ),
                ),
                if (t.from == myId) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => onPay(t.from, t.to, t.amount),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Pay', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
            if (t != transfers.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'How Splitting Works',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? AppColors.darkTextPrimary : cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InsightRow(
            icon: Icons.add_circle_outline,
            title: 'Add expenses',
            desc: 'Who paid? How much? What was it for?',
            isDark: isDark,
          ),
          _InsightRow(
            icon: Icons.balance_rounded,
            title: 'Auto-split',
            desc: 'We calculate each person\'s fair share instantly.',
            isDark: isDark,
          ),
          _InsightRow(
            icon: Icons.payments_outlined,
            title: 'Settle up',
            desc: 'Pay via UPI or mark cash payments as done.',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          Text(
            'Pro tip: The less you settle, the better. Fewer transactions = happier friendships.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextSecondary : cs.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.title,
    required this.desc,
    required this.isDark,
  });
  final IconData icon;
  final String title;
  final String desc;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextPrimary : cs.onSurface,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : cs.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value, this.dark = false});
  final String label;
  final String value;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: dark
                  ? Colors.black.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.75),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: dark ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a bottom sheet listing all settlements the current user needs to make.
/// User taps one to proceed to UPI payment.
void _showPayBottomSheet(
  BuildContext context,
  WidgetRef ref,
  TripBalance balance,
  List<Member> members,
  Member? me,
  dynamic trip,
) {
  final transfers = suggestSettlements(balance).where((t) => t.from == me?.id).toList();
  if (transfers.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No pending payments')));
    return;
  }

  String memberName(String id) {
    return members.where((m) => m.id == id).map((m) => m.name).firstOrNull ?? 'Unknown';
  }

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('Pay a member', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Select who you want to pay', style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.outline)),
          const SizedBox(height: 16),
          for (final t in transfers) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(ctx).colorScheme.primary.withValues(alpha: 0.1),
                child: Text(memberName(t.to).isNotEmpty ? memberName(t.to)[0].toUpperCase() : '?',
                    style: TextStyle(color: Theme.of(ctx).colorScheme.primary, fontWeight: FontWeight.w700)),
              ),
              title: Text('Pay ${memberName(t.to)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Text(
                formatMoney(t.amount, trip.baseCurrency),
                style: TextStyle(fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.primary),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                final payeeName = memberName(t.to);
                final refId = const Uuid().v4();

                // Try to open UPI app with prefilled amount.
                final ok = await launchUpi(
                  payeeName: payeeName,
                  amount: t.amount,
                   note: 'Spliti5 settlement $refId',
                );

                if (!ok) {
                  // Web/desktop: show info dialog, then ask for confirmation.
                  if (context.mounted) {
                    await showDialog<void>(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('Pay on Phone'),
                        content: Text(
                          'UPI apps are only available on mobile.\n\n'
                          'Pay ${formatMoney(t.amount, trip.baseCurrency)} to $payeeName '
                          'using your phone\'s UPI app, then confirm below.',
                        ),
                        actions: [
                          FilledButton(onPressed: () => Navigator.pop(dctx), child: const Text('Got it')),
                        ],
                      ),
                    );
                   }
                }

                // Ask for payment confirmation.
                if (context.mounted) {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dctx) => AlertDialog(
                      title: const Text('Payment successful?'),
                      content: Text('Confirm that you paid ${formatMoney(t.amount, trip.baseCurrency)} to $payeeName.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Yes, paid')),
                      ],
                    ),
                  );
                  if (confirmed != true) return;

                  // Record the settlement.
                  await ref.read(expenseRepositoryProvider).addSettlement(
                        tripId: trip.id,
                        fromMemberId: me!.id,
                        toMemberId: t.to,
                        amount: t.amount,
                        method: 'upi',
                        transactionRef: refId,
                        status: 'paid',
                        verifiedAt: DateTime.now(),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Payment of ${formatMoney(t.amount, trip.baseCurrency)} to $payeeName recorded')),
                    );
                  }
                }
              },
            ),
            if (t != transfers.last) const Divider(height: 1),
          ],
        ],
      ),
    ),
  );
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({
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
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'Balances',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Member',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : cs.outline)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Paid',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : cs.outline)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Share',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : cs.outline)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Balance',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : cs.outline)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            for (var i = 0; i < members.length; i++) ...[
              _MemberRow(
                member: members[i],
                balance: balance?.forMember(members[i].id),
                isMe: members[i].id == myId,
                baseCurrency: baseCurrency,
                isFirst: i == 0,
                isLast: i == members.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.balance,
    required this.isMe,
    required this.baseCurrency,
    required this.isFirst,
    required this.isLast,
  });

  final Member member;
  final Balance? balance;
  final bool isMe;
  final String baseCurrency;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final net = balance?.net ?? 0;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = net > 0.01
        ? (isDark ? AppColors.darkReceived : AppColors.received)
        : net < -0.01
            ? (isDark ? AppColors.darkOwed : AppColors.owed)
            : (isDark ? AppColors.darkTextSecondary : cs.outline);
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.cardBorder;
    final textPrimary = isDark ? AppColors.darkTextPrimary : cs.onSurface;
    final textSecondary = isDark ? AppColors.darkTextSecondary : cs.outline;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: member.avatarAsset.isNotEmpty ? AvatarService.colorFor(member.avatarAsset).withValues(alpha: isDark ? 0.25 : 0.15) : Color(member.avatarColor).withValues(alpha: isDark ? 0.25 : 0.15),
                  child: Text(
                    member.avatarAsset.isNotEmpty ? AvatarService.emojiFor(member.avatarAsset) : (member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
                    style: TextStyle(
                      fontSize: member.avatarAsset.isNotEmpty ? 14 : 12,
                      fontWeight: FontWeight.w700,
                      color: member.avatarAsset.isNotEmpty ? AvatarService.colorFor(member.avatarAsset) : Color(member.avatarColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    isMe ? '${member.name} (You)' : member.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                      color: textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatMoney(balance?.paid ?? 0, baseCurrency),
              style: TextStyle(fontSize: 13, color: textPrimary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              formatMoney(balance?.share ?? 0, baseCurrency),
              style: TextStyle(fontSize: 13, color: textSecondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              net.abs() < 0.01
                  ? '--'
                  : '${net > 0 ? '+' : '-'}${formatMoney(net.abs(), baseCurrency)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Expenses Tab ---

class _ExpensesTab extends ConsumerStatefulWidget {
  const _ExpensesTab({
    required this.tripId,
    required this.baseCurrency,
    required this.members,
  });

  final String tripId;
  final String baseCurrency;
  final List<Member> members;

  @override
  ConsumerState<_ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<_ExpensesTab> {
  String _searchQuery = '';
  String _filterCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesStreamProvider(widget.tripId));
    final byId = {for (final m in widget.members) m.id: m};
    final cs = Theme.of(context).colorScheme;

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (expenses) {
        final categories = <String>{'All'};
        for (final e in expenses) {
          if (e.category.isNotEmpty) categories.add(e.category);
        }

        var filtered = expenses;
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filtered = filtered.where((e) {
            final payer = byId[e.authorId]?.name ?? '';
            return e.category.toLowerCase().contains(q) ||
                payer.toLowerCase().contains(q) ||
                e.note.toLowerCase().contains(q) ||
                e.amount.toString().contains(q);
          }).toList();
        }
        if (_filterCategory != 'All') {
          filtered = filtered.where((e) => e.category == _filterCategory).toList();
        }

        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 56, color: cs.outline.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('No expenses yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text('Tap the + button to add one',
                    style: TextStyle(color: cs.outline, fontSize: 13)),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search expenses...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''))
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  isDense: true,
                ),
              ),
            ),
            if (categories.length > 2)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final cat = categories.elementAt(i);
                    return ChoiceChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      selected: _filterCategory == cat,
                      onSelected: (_) => setState(() => _filterCategory = cat),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
              ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text('No matching expenses', style: TextStyle(color: cs.outline)))
                  : RefreshIndicator(
                      onRefresh: () async {},
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 96, top: 4, left: 8, right: 8),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final e = filtered[i];
                          final payer = byId[e.authorId];
                          final catIcon = _categoryIcon(e.category);
                          final showDate = i == 0 || !_sameDay(e.createdAt, filtered[i - 1].createdAt);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDate)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  child: Text(_formatDate(e.createdAt),
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.outline, letterSpacing: 0.5)),
                                ),
                              Dismissible(
                                key: ValueKey(e.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.owed.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.delete_rounded, color: AppColors.owed),
                                ),
                                confirmDismiss: (_) async {
                                  return await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Delete expense?'),
                                      content: Text('Remove ${e.category} (${formatMoney(e.amount, e.currency)})?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                        FilledButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: FilledButton.styleFrom(backgroundColor: AppColors.owed),
                                            child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (_) async {
                                  await ref.read(expenseRepositoryProvider).deleteExpense(e);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${e.category} deleted')));
                                  }
                                },
                                child: _ExpenseTile(
                                  expense: e,
                                  payer: payer,
                                  catIcon: catIcon,
                                  baseCurrency: widget.baseCurrency,
                                  onTap: () => _showExpenseDetail(context, ref, e, payer, byId),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _showExpenseDetail(BuildContext context, WidgetRef ref, Expense e, Member? payer, Map<String, Member> byId) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.outline.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Icon(_categoryIcon(e.category), size: 24, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.category, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  Text('Paid by ${payer?.name ?? '?'}', style: TextStyle(fontSize: 13, color: cs.outline)),
                ],
              )),
            ]),
            const SizedBox(height: 20),
            _detailRow('Amount', '${formatMoney(e.amount, e.currency)} (${e.currency})'),
            if (e.currency != widget.baseCurrency)
              _detailRow('Converted', formatMoney(e.convertedAmount, widget.baseCurrency)),
            _detailRow('Split Type', e.splitType == 'equal' ? 'Equal' : 'Subset'),
            if (e.note.isNotEmpty) _detailRow('Note', e.note),
            _detailRow('Date', _formatDate(e.createdAt)),
            if (e.editedAt != null) _detailRow('Last Edited', _formatDate(e.editedAt!)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddExpenseScreen(
                        tripId: widget.tripId,
                        baseCurrency: widget.baseCurrency,
                        editExpense: e,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit Expense'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (d) => AlertDialog(
                      title: const Text('Delete expense?'),
                      content: Text('Remove ${e.category}?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(d, true), style: FilledButton.styleFrom(backgroundColor: AppColors.owed), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    Navigator.pop(ctx);
                    await ref.read(expenseRepositoryProvider).deleteExpense(e);
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.category} deleted')));
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: AppColors.owed),
                icon: const Icon(Icons.delete_rounded, size: 18),
                label: const Text('Delete Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 13, color: cs.outline))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface))),
      ]),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Hotel': return Icons.hotel_rounded;
      case 'Flights': return Icons.flight_rounded;
      case 'Taxi/Cab': return Icons.local_taxi_rounded;
      case 'Food': return Icons.restaurant_rounded;
      case 'Snacks/Coffee': return Icons.coffee_rounded;
      case 'Activities': return Icons.emoji_events_rounded;
      case 'Fuel': return Icons.local_gas_station_rounded;
      case 'Shopping': return Icons.shopping_bag_rounded;
      case 'Visa': return Icons.badge_rounded;
      case 'SIM/Internet': return Icons.wifi_rounded;
      case 'Tickets': return Icons.confirmation_number_rounded;
      case 'Drinks': return Icons.local_bar_rounded;
      default: return Icons.receipt_rounded;
    }
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today';
    final yesterday = now.subtract(const Duration(days: 1));
    if (d.year == yesterday.year && d.month == yesterday.month && d.day == yesterday.day) return 'Yesterday';
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month]} ${d.day}, ${d.year}';
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.payer, required this.catIcon, required this.baseCurrency, required this.onTap});
  final Expense expense;
  final Member? payer;
  final IconData catIcon;
  final String baseCurrency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
              child: Icon(catIcon, size: 20, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.category, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cs.onSurface)),
                const SizedBox(height: 2),
                Text('${payer?.name ?? '?'}${expense.note.isNotEmpty ? ' · ${expense.note}' : ''}',
                    style: TextStyle(color: cs.outline, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatMoney(expense.amount, expense.currency), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: cs.onSurface)),
                if (expense.currency != baseCurrency) ...[
                  const SizedBox(height: 2),
                  Text('= ${formatMoney(expense.convertedAmount, baseCurrency)}', style: TextStyle(fontSize: 11, color: cs.outline)),
                ],
              ],
            ),
            if (expense.editedAt != null) ...[const SizedBox(width: 6), Icon(Icons.edit_rounded, size: 14, color: Colors.orange[600])],
          ]),
        ),
      ),
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
    final cs = Theme.of(context).colorScheme;

    return settlementsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (settlements) {
        if (settlements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_horiz_rounded,
                    size: 56, color: cs.outline.withValues(alpha: 0.4)),
                const SizedBox(height: 12),
                Text('No payments recorded',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(
                  'Settle up with your group',
                  style: TextStyle(color: cs.outline, fontSize: 13),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showRecordPaymentDialog(
                    context, ref, tripId, members, baseCurrency,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Record payment'),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96, top: 8, left: 8, right: 8),
          itemCount: settlements.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showRecordPaymentDialog(
                      context, ref, tripId, members, baseCurrency,
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
              child: InkWell(
                onTap: () => _showEditSettlementDialog(
                  context, ref, s, members, baseCurrency,
                ),
                onLongPress: () => _confirmDeleteSettlement(
                  context, ref, s,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isMine
                              ? AppColors.received.withValues(alpha: 0.1)
                              : cs.primaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isMine
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 20,
                          color: isMine ? AppColors.received : cs.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${byId[s.fromMemberId]?.name ?? '?'}  →  ${byId[s.toMemberId]?.name ?? '?'}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.partialRemaining != null
                                  ? '${formatMoney(s.amount, baseCurrency)}  '
                                      '${formatMoney(s.partialRemaining!, baseCurrency)} remaining'
                                      '$refLabel'
                                  : '${formatMoney(s.amount, baseCurrency)}  ·  $methodLabel$refLabel',
                              style: TextStyle(
                                color: cs.outline,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isMine)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.received.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formatMoney(s.amount, baseCurrency),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.received,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, size: 20, color: cs.outline),
                    ],
                  ),
                ),
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
    note: 'Spliti5 settlement $refId',
  );
  if (!ok) {
    if (context.mounted) {
      // On web/desktop, show a dialog with payment details instead of
      // attempting the broken upi:// deep link.
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            Icons.phone_android,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          title: const Text('Pay via UPI App'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open a UPI app on your phone to pay $payeeName',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatMoney(amount, baseCurrency),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'To: $payeeName',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'After paying, come back and tap "Yes, paid" to record the settlement.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('I\'ll pay on phone'),
            ),
          ],
        ),
      );
      // Still allow recording the payment manually.
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
    } else {
      return;
    }
  } else {
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
  }

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

Future<void> _showEditSettlementDialog(
  BuildContext context,
  WidgetRef ref,
  Settlement settlement,
  List<Member> members,
  String baseCurrency,
) async {
  String fromId = settlement.fromMemberId;
  String toId = settlement.toMemberId;
  String method = settlement.method.isNotEmpty ? settlement.method : 'upi';
  final amountCtrl = TextEditingController(text: settlement.amount.toString());

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setState) => AlertDialog(
        title: const Text('Edit payment'),
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
              await ref.read(expenseRepositoryProvider).editSettlement(
                    settlement: settlement,
                    fromMemberId: fromId,
                    toMemberId: toId,
                    amount: amount,
                    method: method,
                  );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

void _confirmDeleteSettlement(
  BuildContext context,
  WidgetRef ref,
  Settlement settlement,
) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete payment?'),
      content: const Text('This payment record will be permanently removed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(ctx);
            await ref
                .read(expenseRepositoryProvider)
                .deleteSettlement(settlement);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment deleted')),
              );
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
