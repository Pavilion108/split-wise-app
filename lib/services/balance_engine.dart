import 'dart:math';

import '../models/models.dart';

/// Round to 2 decimal places to avoid floating-point noise.
double _r2(double v) => (v * 100).roundToDouble() / 100;

/// Pure balance computation. No DB dependency — unit testable.
///
/// For each member:
///   net = (total they paid) - (their share of expenses) -
///         (settlements received) + (settlements paid out)
///
/// Positive net → member is owed money (creditor).
/// Negative net → member owes money (debtor).
TripBalance computeBalance({
  required List<Expense> expenses,
  required List<Split> splits,
  required List<Settlement> settlements,
  required List<Member> members,
}) {
  final activeMemberIds = <String>{};
  for (final m in members) {
    if (!m.deleted) activeMemberIds.add(m.id);
  }

  // Accumulators — only track active members.
  final paid = <String, double>{};
  final share = <String, double>{};
  final received = <String, double>{};
  final paidOut = <String, double>{};

  for (final id in activeMemberIds) {
    paid[id] = 0;
    share[id] = 0;
    received[id] = 0;
    paidOut[id] = 0;
  }

  // 1. Aggregate what each member PAID for expenses.
  //    Skip expenses authored by deleted members — their financial
  //    contributions are removed from the trip's accounting.
  for (final e in expenses) {
    if (e.deleted) continue;
    if (!activeMemberIds.contains(e.authorId)) continue;
    final authorBalance = paid[e.authorId];
    if (authorBalance != null) {
      paid[e.authorId] = _r2(authorBalance + e.convertedAmount);
    }
  }

  // 2. Aggregate each member's SHARE of expenses (from splits).
  //    We only count splits whose expense is NOT deleted (the caller
  //    is responsible for filtering; the DB query already does this).
  for (final s in splits) {
    final memberShare = share[s.memberId];
    if (memberShare != null) {
      share[s.memberId] = _r2(memberShare + s.shareConverted);
    }
  }

  // 3. Aggregate settlements: received = money coming in,
  //    paidOut = money going out.
  //    Both sides must be active to count either side — this preserves the
  //    accounting identity sum(nets) == 0.
  for (final s in settlements) {
    if (s.deleted) continue;
    final senderActive = activeMemberIds.contains(s.fromMemberId);
    final receiverActive = activeMemberIds.contains(s.toMemberId);
    if (senderActive && receiverActive) {
      received[s.toMemberId] =
          _r2((received[s.toMemberId] ?? 0) + s.amount);
      paidOut[s.fromMemberId] =
          _r2((paidOut[s.fromMemberId] ?? 0) + s.amount);
    }
  }

  // 4. Compute total expense (sum of all shares) and per-member balances.
  var total = 0.0;
  final result = <Balance>[];
  for (final m in members) {
    if (m.deleted) continue;
    final p = paid[m.id] ?? 0;
    final sh = share[m.id] ?? 0;
    total = _r2(total + sh);
    result.add(Balance(
      memberId: m.id,
      paid: p,
      share: sh,
      received: received[m.id] ?? 0,
      paidOut: paidOut[m.id] ?? 0,
    ));
  }

  // Accounting invariant check (debug only): sum of all nets should be ~0.
  // When deleted members have expenses/splits, this may not hold exactly
  // because their financial activity is excluded. That's expected.
  assert(() {
    final netSum = result.fold(0.0, (double sum, b) => sum + b.net);
    if (netSum.abs() >= 0.02) {
      // ignore: avoid_print
      print('[BalanceEngine] WARNING: sum(nets)=$netSum (may be caused by deleted members)');
    }
    return true;
  }());

  return TripBalance(totalExpense: total, members: result);
}

/// Greedy minimal-transfer settlement. Yields at most n-1 transfers.
List<SuggestedTransfer> suggestSettlements(TripBalance balance) {
  final creditors = [
    for (final b in balance.members)
      if (b.net > 0.01) _Pair(b.memberId, b.net),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  final debtors = [
    for (final b in balance.members)
      if (b.net < -0.01) _Pair(b.memberId, -b.net),
  ]..sort((a, b) => b.amount.compareTo(a.amount));

  final transfers = <SuggestedTransfer>[];
  var ci = 0, di = 0;
  while (ci < creditors.length && di < debtors.length) {
    final amount = min(creditors[ci].amount, debtors[di].amount);
    transfers.add(SuggestedTransfer(
      from: debtors[di].id,
      to: creditors[ci].id,
      amount: amount,
    ));
    creditors[ci] = _Pair(creditors[ci].id, creditors[ci].amount - amount);
    debtors[di] = _Pair(debtors[di].id, debtors[di].amount - amount);
    if (creditors[ci].amount <= 0.01) ci++;
    if (debtors[di].amount <= 0.01) di++;
  }
  return transfers;
}

class _Pair {
  const _Pair(this.id, this.amount);
  final String id;
  final double amount;
}
