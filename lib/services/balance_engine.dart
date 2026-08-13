import 'dart:math';

import '../models/models.dart';

/// Pure balance computation. No DB dependency — unit testable.
TripBalance computeBalance({
  required List<Expense> expenses,
  required List<Split> splits,
  required List<Settlement> settlements,
  required List<Member> members,
}) {
  final paid = <String, double>{};
  final share = <String, double>{};
  final received = <String, double>{};
  final paidOut = <String, double>{};

  for (final m in members) {
    if (m.deleted) continue;
    paid[m.id] = 0;
    share[m.id] = 0;
    received[m.id] = 0;
    paidOut[m.id] = 0;
  }

  for (final e in expenses) {
    if (e.deleted) continue;
    paid[e.authorId] = (paid[e.authorId] ?? 0) + e.convertedAmount;
  }

  for (final s in splits) {
    share[s.memberId] = (share[s.memberId] ?? 0) + s.shareConverted;
  }

  for (final s in settlements) {
    if (s.deleted) continue;
    received[s.toMemberId] = (received[s.toMemberId] ?? 0) + s.amount;
    paidOut[s.fromMemberId] = (paidOut[s.fromMemberId] ?? 0) + s.amount;
  }

  var total = 0.0;
  final result = <Balance>[];
  for (final m in members) {
    if (m.deleted) continue;
    final p = paid[m.id] ?? 0;
    final sh = share[m.id] ?? 0;
    total += sh;
    result.add(Balance(
      memberId: m.id,
      paid: p,
      share: sh,
      received: received[m.id] ?? 0,
      paidOut: paidOut[m.id] ?? 0,
    ));
  }

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
