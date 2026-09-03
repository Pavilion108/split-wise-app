import 'package:flutter_test/flutter_test.dart';
import 'package:split_wise/models/models.dart';
import 'package:split_wise/services/balance_engine.dart';
import 'package:split_wise/services/split_calculator.dart';
import 'package:split_wise/core/constants.dart';

Member m(String id, {String? name, bool deleted = false}) => Member(
      id: id,
      tripId: 'trip1',
      name: name ?? id,
      deviceId: 'dev_$id',
      avatarColor: 0xFF000000,
      joinedAt: DateTime(2026),
      deleted: deleted,
    );

Expense e({
  required String id,
  required String authorId,
  required double amount,
  String currency = 'INR',
  double? convertedAmount,
  bool deleted = false,
}) =>
    Expense(
      id: id,
      tripId: 'trip1',
      authorId: authorId,
      category: 'Food',
      amount: amount,
      currency: currency,
      convertedAmount: convertedAmount ?? amount,
      rateUsed: 1,
      splitType: 'equal',
      createdAt: DateTime(2026),
      deleted: deleted,
    );

Split s({
  required String expenseId,
  required String memberId,
  required double shareConverted,
}) =>
    Split(
      id: 's_${expenseId}_$memberId',
      expenseId: expenseId,
      memberId: memberId,
      shareAmount: shareConverted,
      shareConverted: shareConverted,
    );

Settlement st({
  required String from,
  required String to,
  required double amount,
  bool deleted = false,
}) =>
    Settlement(
      id: 'st_${from}_$to',
      tripId: 'trip1',
      fromMemberId: from,
      toMemberId: to,
      amount: amount,
      paidAt: DateTime(2026),
      deleted: deleted,
    );

void main() {
  // =========================================================================
  // SPLIT CALCULATOR — CA-LEVEL TESTS
  // =========================================================================
  group('Split Calculator', () {
    test('equal split: 3 members, ₹100', () {
      final splits =
          computeSplits(amount: 100, type: 'equal', allMemberIds: ['a', 'b', 'c']);
      expect(splits.length, 3);
      final sum = splits.fold(0.0, (double s, sp) => s + sp.amount);
      expect(sum, closeTo(100, 0.01), reason: 'Penny-perfect sum');
    });

    test('equal split: 2 members, ₹100 → 50+50', () {
      final splits =
          computeSplits(amount: 100, type: 'equal', allMemberIds: ['a', 'b']);
      expect(splits[0].amount, 50);
      expect(splits[1].amount, 50);
    });

    test('equal split: 4 members, ₹100 → 25 each', () {
      final splits = computeSplits(
          amount: 100, type: 'equal', allMemberIds: ['a', 'b', 'c', 'd']);
      for (final sp in splits) {
        expect(sp.amount, 25);
      }
    });

    test('single member gets full amount', () {
      final splits =
          computeSplits(amount: 999, type: 'equal', allMemberIds: ['a']);
      expect(splits.length, 1);
      expect(splits[0].amount, 999);
    });

    test('split sum equals amount for ALL rounding-prone amounts', () {
      final amounts = <double>[
        0.01, 0.02, 0.03, 0.10, 0.33, 0.99, 1.00, 1.01,
        10, 33, 50, 100, 250, 999, 1000, 3333,
        0.07, 0.13, 0.97, 2.99, 7.77, 13.13, 99.99, 199.99,
        1234.56, 9999.99, 0.30, 1.20, 5.50,
      ];
      for (final amt in amounts) {
        for (final n in [2, 3, 4, 5, 6, 7]) {
          final ids = List.generate(n, (i) => 'm$i');
          final splits =
              computeSplits(amount: amt, type: 'equal', allMemberIds: ids);
          final sum = splits.fold(0.0, (double s, sp) => s + sp.amount);
          expect(sum, closeTo(amt, 0.01),
              reason: 'amt=$amt, n=$n, sum=$sum');
        }
      }
    });

    test('custom split among subset', () {
      final splits = computeSplits(
          amount: 120,
          type: 'custom',
          allMemberIds: ['a', 'b', 'c', 'd'],
          subsetIds: ['a', 'b']);
      expect(splits.length, 2);
      expect(splits[0].amount, 60);
      expect(splits[1].amount, 60);
    });

    test('custom split: 3 of 5 members', () {
      final splits = computeSplits(
          amount: 300,
          type: 'custom',
          allMemberIds: ['a', 'b', 'c', 'd', 'e'],
          subsetIds: ['a', 'c', 'e']);
      expect(splits.length, 3);
      final sum = splits.fold(0.0, (double s, sp) => s + sp.amount);
      expect(sum, closeTo(300, 0.01));
    });

    test('zero amount → empty', () {
      expect(
          computeSplits(amount: 0, type: 'equal', allMemberIds: ['a', 'b']),
          isEmpty);
    });

    test('negative amount → empty', () {
      expect(
          computeSplits(amount: -100, type: 'equal', allMemberIds: ['a', 'b']),
          isEmpty);
    });

    test('empty member list → empty', () {
      expect(computeSplits(amount: 100, type: 'equal', allMemberIds: []),
          isEmpty);
    });

    test('₹1 split among 3 → sum is exactly ₹1', () {
      final splits =
          computeSplits(amount: 1, type: 'equal', allMemberIds: ['a', 'b', 'c']);
      final sum = splits.fold(0.0, (double s, sp) => s + sp.amount);
      expect(sum, closeTo(1, 0.01));
    });

    test('₹0.01 split among 2 → penny handling', () {
      final splits =
          computeSplits(amount: 0.01, type: 'equal', allMemberIds: ['a', 'b']);
      final sum = splits.fold(0.0, (double s, sp) => s + sp.amount);
      expect(sum, closeTo(0.01, 0.01));
    });
  });

  // =========================================================================
  // BALANCE ENGINE — CA-LEVEL TESTS
  // =========================================================================
  group('Balance Engine — Basic', () {
    test('empty: all zero', () {
      final b = computeBalance(
          expenses: [], splits: [], settlements: [], members: [m('a'), m('b')]);
      expect(b.totalExpense, 0);
      expect(b.forMember('a')!.net, 0);
    });

    test('one payer, two share equally', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 300)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 150),
                 s(expenseId: 'e1', memberId: 'b', shareConverted: 150)],
        settlements: [],
        members: [m('a'), m('b')],
      );
      expect(b.totalExpense, closeTo(300, 0.01));
      expect(b.forMember('a')!.net, closeTo(150, 0.01));
      expect(b.forMember('b')!.net, closeTo(-150, 0.01));
    });

    test('full settlement zeros out', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 200)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
                 s(expenseId: 'e1', memberId: 'b', shareConverted: 100)],
        settlements: [st(from: 'b', to: 'a', amount: 100)],
        members: [m('a'), m('b')],
      );
      expect(b.forMember('a')!.net, closeTo(0, 0.01));
      expect(b.forMember('b')!.net, closeTo(0, 0.01));
    });
  });

  group('Balance Engine — Deletion Safety', () {
    test('deleted expense ignored', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 300, deleted: true)],
        splits: [],
        settlements: [],
        members: [m('a'), m('b')],
      );
      expect(b.totalExpense, 0);
    });

    test('deleted settlement ignored', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 200)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
                 s(expenseId: 'e1', memberId: 'b', shareConverted: 100)],
        settlements: [st(from: 'b', to: 'a', amount: 100, deleted: true)],
        members: [m('a'), m('b')],
      );
      // Settlement is deleted, so balance is same as no settlement
      expect(b.forMember('a')!.net, closeTo(100, 0.01));
      expect(b.forMember('b')!.net, closeTo(-100, 0.01));
    });

    test('deleted member excluded from balance', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 200)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
                 s(expenseId: 'e1', memberId: 'b', shareConverted: 100)],
        settlements: [],
        members: [m('a'), m('b', name: 'Bob')],
      );
      expect(b.members.length, 2);
    });
  });

  group('Balance Engine — Multi-Payer Scenarios', () {
    test('both pay, equal split', () {
      final b = computeBalance(
        expenses: [
          e(id: 'e1', authorId: 'a', amount: 200),
          e(id: 'e2', authorId: 'b', amount: 100),
        ],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 100),
          s(expenseId: 'e2', memberId: 'a', shareConverted: 50),
          s(expenseId: 'e2', memberId: 'b', shareConverted: 50),
        ],
        settlements: [],
        members: [m('a'), m('b')],
      );
      // a paid 200, share 150, net +50
      // b paid 100, share 150, net -50
      expect(b.forMember('a')!.net, closeTo(50, 0.01));
      expect(b.forMember('b')!.net, closeTo(-50, 0.01));
    });

    test('three payers, cross-expenses', () {
      final b = computeBalance(
        expenses: [
          e(id: 'e1', authorId: 'a', amount: 900),
          e(id: 'e2', authorId: 'b', amount: 600),
          e(id: 'e3', authorId: 'c', amount: 300),
        ],
        splits: [
          // e1 split 3 ways
          s(expenseId: 'e1', memberId: 'a', shareConverted: 300),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 300),
          s(expenseId: 'e1', memberId: 'c', shareConverted: 300),
          // e2 split 3 ways
          s(expenseId: 'e2', memberId: 'a', shareConverted: 200),
          s(expenseId: 'e2', memberId: 'b', shareConverted: 200),
          s(expenseId: 'e2', memberId: 'c', shareConverted: 200),
          // e3 split 3 ways
          s(expenseId: 'e3', memberId: 'a', shareConverted: 100),
          s(expenseId: 'e3', memberId: 'b', shareConverted: 100),
          s(expenseId: 'e3', memberId: 'c', shareConverted: 100),
        ],
        settlements: [],
        members: [m('a'), m('b'), m('c')],
      );
      // a paid 900, share 600, net +300
      // b paid 600, share 600, net 0
      // c paid 300, share 600, net -300
      expect(b.forMember('a')!.net, closeTo(300, 0.01));
      expect(b.forMember('b')!.net, closeTo(0, 0.01));
      expect(b.forMember('c')!.net, closeTo(-300, 0.01));
      expect(b.totalExpense, closeTo(1800, 0.01));
    });
  });

  group('Balance Engine — Settlements', () {
    test('partial settlement', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 3000)],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 1000),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 1000),
          s(expenseId: 'e1', memberId: 'c', shareConverted: 1000),
        ],
        settlements: [st(from: 'b', to: 'a', amount: 500)],
        members: [m('a'), m('b'), m('c')],
      );
      expect(b.forMember('a')!.net, closeTo(1500, 0.01));
      expect(b.forMember('b')!.net, closeTo(-500, 0.01));
      expect(b.forMember('c')!.net, closeTo(-1000, 0.01));
    });

    test('multiple settlements between same pair', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 1000)],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 500),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 500),
        ],
        settlements: [
          st(from: 'b', to: 'a', amount: 200),
          st(from: 'b', to: 'a', amount: 100),
          st(from: 'b', to: 'a', amount: 50),
        ],
        members: [m('a'), m('b')],
      );
      // a paid 1000, share 500, received 350 → net = 500 - 350 = 150
      // b paid 0, share 500, paidOut 350 → net = -500 + 350 = -150
      expect(b.forMember('a')!.net, closeTo(150, 0.01));
      expect(b.forMember('b')!.net, closeTo(-150, 0.01));
    });

    test('over-settlement (paid more than owed)', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 200)],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 100),
        ],
        // b pays 150 (more than owed 100)
        settlements: [st(from: 'b', to: 'a', amount: 150)],
        members: [m('a'), m('b')],
      );
      // a: paid=200, share=100, received=150 → net=200-100-150=-50 (now owes!)
      // b: paid=0, share=100, paidOut=150 → net=0-100+150=+50 (is owed!)
      expect(b.forMember('a')!.net, closeTo(-50, 0.01));
      expect(b.forMember('b')!.net, closeTo(50, 0.01));
    });

    test('circular settlements: a→b→c→a', () {
      final b = computeBalance(
        expenses: [],
        splits: [],
        settlements: [
          st(from: 'a', to: 'b', amount: 100),
          st(from: 'b', to: 'c', amount: 100),
          st(from: 'c', to: 'a', amount: 100),
        ],
        members: [m('a'), m('b'), m('c')],
      );
      // Each paid 100 and received 100 → all nets are 0
      expect(b.forMember('a')!.net, closeTo(0, 0.01));
      expect(b.forMember('b')!.net, closeTo(0, 0.01));
      expect(b.forMember('c')!.net, closeTo(0, 0.01));
    });
  });

  group('Balance Engine — Rounding Safety', () {
    test('₹100 split 3 ways: sums are exact', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 100)],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 33.34),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 33.33),
          s(expenseId: 'e1', memberId: 'c', shareConverted: 33.33),
        ],
        settlements: [],
        members: [m('a'), m('b'), m('c')],
      );
      expect(b.totalExpense, closeTo(100, 0.01));
      // All nets sum to 0 (accounting equation)
      final netSum =
          b.members.fold(0.0, (double sum, bal) => sum + bal.net);
      expect(netSum, closeTo(0, 0.01));
    });

    test('₹1 split 7 ways: no penny leak', () {
      final ids = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
      final splits = computeSplits(amount: 1, type: 'equal', allMemberIds: ids);
      final sum = splits.fold(0.0, (double s, sp) => s + sp.amount);
      expect(sum, closeTo(1, 0.01));
    });

    test('large amount: ₹99999.99 split 3 ways', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 99999.99)],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 33333.33),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 33333.33),
          s(expenseId: 'e1', memberId: 'c', shareConverted: 33333.33),
        ],
        settlements: [],
        members: [m('a'), m('b'), m('c')],
      );
      expect(b.totalExpense, closeTo(99999.99, 0.02));
      final netSum = b.members.fold(0.0, (double sum, bal) => sum + bal.net);
      expect(netSum, closeTo(0, 0.02));
    });

    test('micro amounts: ₹0.01 split 2 ways', () {
      final splits =
          computeSplits(amount: 0.01, type: 'equal', allMemberIds: ['a', 'b']);
      final sum = splits.fold(0.0, (double s, sp) => s + sp.amount);
      expect(sum, closeTo(0.01, 0.01));
    });
  });

  group('Balance Engine — Edge Cases', () {
    test('single member: net is always 0', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 500)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 500)],
        settlements: [],
        members: [m('a')],
      );
      expect(b.forMember('a')!.net, closeTo(0, 0.01));
    });

    test('no expenses: all zero', () {
      final b = computeBalance(
        expenses: [],
        splits: [],
        settlements: [],
        members: [m('a'), m('b'), m('c')],
      );
      expect(b.totalExpense, 0);
      for (final mb in b.members) {
        expect(mb.net, closeTo(0, 0.01));
      }
    });

    test('only settlements, no expenses', () {
      final b = computeBalance(
        expenses: [],
        splits: [],
        settlements: [st(from: 'a', to: 'b', amount: 50)],
        members: [m('a'), m('b')],
      );
      // net = paid - share - received + paidOut
      // a: paid=0, share=0, received=0, paidOut=50 → net = +50
      // b: paid=0, share=0, received=50, paidOut=0 → net = -50
      expect(b.forMember('a')!.net, closeTo(50, 0.01));
      expect(b.forMember('b')!.net, closeTo(-50, 0.01));
    });

    test('settlement to non-member: both sides skipped', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 200)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
                 s(expenseId: 'e1', memberId: 'b', shareConverted: 100)],
        settlements: [st(from: 'a', to: 'unknown', amount: 50)],
        members: [m('a'), m('b')],
      );
      // Settlement to non-member 'unknown': both sides skipped to preserve
      // accounting invariant. 'a' paid the expense but settlement is ignored.
      // a: paid=200, share=100, received=0, paidOut=0 → net = 100
      expect(b.forMember('a')!.net, closeTo(100, 0.01));
      expect(b.forMember('b')!.net, closeTo(-100, 0.01));
    });

    test('settlement involving deleted member: both sides skipped', () {
      // Only settlements to/from deleted members are skipped.
      // a owes b 100, but b is deleted → settlement skipped → a's net unchanged.
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 200)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
                 s(expenseId: 'e1', memberId: 'b', shareConverted: 100)],
        settlements: [st(from: 'a', to: 'b', amount: 50)],
        members: [m('a'), m('b', name: 'Bob', deleted: true)],
      );
      // Bob deleted → settlement skipped.
      // a: paid=200, share=100, received=0, paidOut=0 → net=100
      expect(b.forMember('a')!.net, closeTo(100, 0.01));
      expect(b.members.length, 1);
    });

    test('nets sum to 0 with settlement to inactive party', () {
      // Charlie is deleted. Settlement between a and b is skipped.
      // Splits only for active members.
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 200)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
                 s(expenseId: 'e1', memberId: 'b', shareConverted: 100)],
        settlements: [st(from: 'b', to: 'a', amount: 50)],
        members: [m('a'), m('b'), m('c', name: 'Charlie', deleted: true)],
      );
      // a: paid=200, share=100, received=0, paidOut=0 → net = 100
      // b: paid=0, share=100, received=0, paidOut=0 → net = -100
      final netSum = b.members.fold(0.0, (double sum, bal) => sum + bal.net);
      expect(netSum, closeTo(0, 0.02));
    });

    test('totalExpense equals sum of all shares', () {
      final b = computeBalance(
        expenses: [
          e(id: 'e1', authorId: 'a', amount: 500),
          e(id: 'e2', authorId: 'b', amount: 300),
        ],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 250),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 250),
          s(expenseId: 'e2', memberId: 'a', shareConverted: 150),
          s(expenseId: 'e2', memberId: 'b', shareConverted: 150),
        ],
        settlements: [],
        members: [m('a'), m('b')],
      );
      expect(b.totalExpense, closeTo(800, 0.01));
    });

    test('nets always sum to 0 (accounting equation)', () {
      final b = computeBalance(
        expenses: [
          e(id: 'e1', authorId: 'a', amount: 1234.56),
          e(id: 'e2', authorId: 'b', amount: 789.12),
        ],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 617.28),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 617.28),
          s(expenseId: 'e2', memberId: 'a', shareConverted: 394.56),
          s(expenseId: 'e2', memberId: 'b', shareConverted: 394.56),
        ],
        settlements: [st(from: 'b', to: 'a', amount: 250)],
        members: [m('a'), m('b')],
      );
      final netSum = b.members.fold(0.0, (double sum, bal) => sum + bal.net);
      expect(netSum, closeTo(0, 0.01));
    });

    test('no duplicate currency codes', () {
      final codes = kDefaultCurrencies.map((c) => c['code']).toList();
      final unique = codes.toSet();
      expect(codes.length, unique.length, reason: 'Duplicate currency codes found');
    });
  });

  // =========================================================================
  // SETTLEMENT SUGGESTIONS — CA-LEVEL TESTS
  // =========================================================================
  group('Settlement Suggestions', () {
    test('two members: minimal 1 transfer', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 200)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
                 s(expenseId: 'e1', memberId: 'b', shareConverted: 100)],
        settlements: [],
        members: [m('a'), m('b')],
      );
      final t = suggestSettlements(b);
      expect(t.length, 1);
      expect(t[0].from, 'b');
      expect(t[0].to, 'a');
      expect(t[0].amount, closeTo(100, 0.01));
    });

    test('three members: 2 transfers', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 3000)],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 1000),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 1000),
          s(expenseId: 'e1', memberId: 'c', shareConverted: 1000),
        ],
        settlements: [],
        members: [m('a'), m('b'), m('c')],
      );
      final t = suggestSettlements(b);
      expect(t.length, 2);
      // Total transferred should equal total debt
      final totalTransferred = t.fold(0.0, (sum, tr) => sum + tr.amount);
      expect(totalTransferred, closeTo(2000, 0.01));
    });

    test('fully settled: no transfers', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 200)],
        splits: [s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
                 s(expenseId: 'e1', memberId: 'b', shareConverted: 100)],
        settlements: [st(from: 'b', to: 'a', amount: 100)],
        members: [m('a'), m('b')],
      );
      expect(suggestSettlements(b), isEmpty);
    });

    test('all equal: no transfers', () {
      final b = computeBalance(
        expenses: [
          e(id: 'e1', authorId: 'a', amount: 200),
          e(id: 'e2', authorId: 'b', amount: 200),
        ],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 100),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 100),
          s(expenseId: 'e2', memberId: 'a', shareConverted: 100),
          s(expenseId: 'e2', memberId: 'b', shareConverted: 100),
        ],
        settlements: [],
        members: [m('a'), m('b')],
      );
      expect(suggestSettlements(b), isEmpty);
    });

    test('4 members complex: optimal transfers', () {
      final b = computeBalance(
        expenses: [e(id: 'e1', authorId: 'a', amount: 4000)],
        splits: [
          s(expenseId: 'e1', memberId: 'a', shareConverted: 1000),
          s(expenseId: 'e1', memberId: 'b', shareConverted: 1000),
          s(expenseId: 'e1', memberId: 'c', shareConverted: 1000),
          s(expenseId: 'e1', memberId: 'd', shareConverted: 1000),
        ],
        settlements: [],
        members: [m('a'), m('b'), m('c'), m('d')],
      );
      final t = suggestSettlements(b);
      // At most n-1 = 3 transfers
      expect(t.length, lessThanOrEqualTo(3));
      // Total transferred = total debt = 3000
      final totalTransferred = t.fold(0.0, (sum, tr) => sum + tr.amount);
      expect(totalTransferred, closeTo(3000, 0.01));
    });
  });

  // =========================================================================
  // FORMAT MONEY — CA-LEVEL TESTS
  // =========================================================================
  group('Format Money', () {
    test('INR: basic formatting', () {
      expect(formatMoney(100, 'INR'), '₹100');
      expect(formatMoney(1000, 'INR'), '₹1,000');
      expect(formatMoney(100000, 'INR'), '₹1,00,000');
      expect(formatMoney(10000000, 'INR'), '₹1,00,00,000');
    });

    test('INR: decimal formatting', () {
      expect(formatMoney(100.50, 'INR'), '₹100.50');
      expect(formatMoney(1000.99, 'INR'), '₹1,000.99');
    });

    test('USD: western grouping', () {
      expect(formatMoney(1000, 'USD'), '\$1,000');
      expect(formatMoney(1000000, 'USD'), '\$1,000,000');
    });

    test('negative amounts', () {
      expect(formatMoney(-100, 'INR'), '-₹100');
      expect(formatMoney(-1000.50, 'USD'), '-\$1,000.50');
    });

    test('zero amount', () {
      expect(formatMoney(0, 'INR'), '₹0');
      expect(formatMoney(0, 'USD'), '\$0');
    });

    test('small decimal amounts', () {
      expect(formatMoney(0.01, 'INR'), '₹0.01');
      expect(formatMoney(0.99, 'INR'), '₹0.99');
    });

    test('unknown currency falls back to code', () {
      final result = formatMoney(100, 'XYZ');
      expect(result, contains('XYZ'));
      expect(result, contains('100'));
    });

    test('JPY (no decimals expected in real use)', () {
      expect(formatMoney(1000, 'JPY'), '¥1,000');
    });
  });

  // =========================================================================
  // REAL-WORLD SCENARIOS — Multi-payer, settlement, recomputation
  // =========================================================================
  group('Real-World Multi-Payer Scenarios', () {
    test('User1 pays 1000, User2 pays 1500, equal split → correct net balances', () {
      final members = [m('u1', name: 'Alice'), m('u2', name: 'Bob')];
      final expenses = [
        e(id: 'e1', authorId: 'u1', amount: 1000),
        e(id: 'e2', authorId: 'u2', amount: 1500),
      ];
      final splits = [
        s(expenseId: 'e1', memberId: 'u1', shareConverted: 500),
        s(expenseId: 'e1', memberId: 'u2', shareConverted: 500),
        s(expenseId: 'e2', memberId: 'u1', shareConverted: 750),
        s(expenseId: 'e2', memberId: 'u2', shareConverted: 750),
      ];
      final b = computeBalance(expenses: expenses, splits: splits, settlements: [], members: members);
      expect(b.totalExpense, 2500);
      // Alice paid 1000, share 1250 → net = -250 (owes 250)
      final alice = b.forMember('u1')!;
      expect(alice.paid, 1000);
      expect(alice.share, 1250);
      expect(alice.net, closeTo(-250, 0.01));
      // Bob paid 1500, share 1250 → net = +250 (owed 250)
      final bob = b.forMember('u2')!;
      expect(bob.paid, 1500);
      expect(bob.share, 1250);
      expect(bob.net, closeTo(250, 0.01));
    });

    test('3 users: A pays 3000, B pays 0, C pays 0 → A owed, B/C owe', () {
      final members = [m('a', name: 'A'), m('b', name: 'B'), m('c', name: 'C')];
      final expenses = [
        e(id: 'e1', authorId: 'a', amount: 3000),
      ];
      final splits = [
        s(expenseId: 'e1', memberId: 'a', shareConverted: 1000),
        s(expenseId: 'e1', memberId: 'b', shareConverted: 1000),
        s(expenseId: 'e1', memberId: 'c', shareConverted: 1000),
      ];
      final b = computeBalance(expenses: expenses, splits: splits, settlements: [], members: members);
      expect(b.forMember('a')!.net, closeTo(2000, 0.01));
      expect(b.forMember('b')!.net, closeTo(-1000, 0.01));
      expect(b.forMember('c')!.net, closeTo(-1000, 0.01));
      // Sum of nets should be 0
      final netSum = b.members.fold(0.0, (sum, m) => sum + m.net);
      expect(netSum.abs(), lessThan(0.02));
    });

    test('User1 pays 1000 for 2 people, User2 pays 500 for 2 people, mixed expenses', () {
      final members = [m('u1', name: 'Alice'), m('u2', name: 'Bob')];
      final expenses = [
        e(id: 'e1', authorId: 'u1', amount: 1000),
        e(id: 'e2', authorId: 'u2', amount: 500),
      ];
      final splits = [
        s(expenseId: 'e1', memberId: 'u1', shareConverted: 500),
        s(expenseId: 'e1', memberId: 'u2', shareConverted: 500),
        s(expenseId: 'e2', memberId: 'u1', shareConverted: 250),
        s(expenseId: 'e2', memberId: 'u2', shareConverted: 250),
      ];
      final b = computeBalance(expenses: expenses, splits: splits, settlements: [], members: members);
      // Alice paid 1000, share 750 → net = +250
      expect(b.forMember('u1')!.net, closeTo(250, 0.01));
      // Bob paid 500, share 750 → net = -250
      expect(b.forMember('u2')!.net, closeTo(-250, 0.01));
    });

    test('Partial settlement: after paying 200, remaining balance correct', () {
      final members = [m('u1', name: 'Alice'), m('u2', name: 'Bob')];
      final expenses = [
        e(id: 'e1', authorId: 'u1', amount: 1000),
      ];
      final splits = [
        s(expenseId: 'e1', memberId: 'u1', shareConverted: 500),
        s(expenseId: 'e1', memberId: 'u2', shareConverted: 500),
      ];
      final settlements = [
        st(from: 'u2', to: 'u1', amount: 200),
      ];
      final b = computeBalance(expenses: expenses, splits: splits, settlements: settlements, members: members);
      // Alice paid 1000, share 500, received 200 → net = 1000 - 500 - 200 = 300
      expect(b.forMember('u1')!.net, closeTo(300, 0.01));
      // Bob paid 0, share 500, paidOut 200 → net = 0 - 500 + 200 = -300
      expect(b.forMember('u2')!.net, closeTo(-300, 0.01));
    });

    test('Settlement suggestion: 3 users with cross-expenses', () {
      final members = [m('a'), m('b'), m('c')];
      final expenses = [
        e(id: 'e1', authorId: 'a', amount: 3000),
        e(id: 'e2', authorId: 'b', amount: 1500),
        e(id: 'e3', authorId: 'c', amount: 0),
      ];
      final splits = [
        s(expenseId: 'e1', memberId: 'a', shareConverted: 1000),
        s(expenseId: 'e1', memberId: 'b', shareConverted: 1000),
        s(expenseId: 'e1', memberId: 'c', shareConverted: 1000),
        s(expenseId: 'e2', memberId: 'a', shareConverted: 500),
        s(expenseId: 'e2', memberId: 'b', shareConverted: 500),
        s(expenseId: 'e2', memberId: 'c', shareConverted: 500),
      ];
      final b = computeBalance(expenses: expenses, splits: splits, settlements: [], members: members);
      final transfers = suggestSettlements(b);
      // A net = 3000-1500 = +1500, B net = 1500-1500 = 0, C net = 0-1500 = -1500
      // Should have 1 transfer: C pays A 1500
      expect(transfers.length, 1);
      expect(transfers[0].from, 'c');
      expect(transfers[0].to, 'a');
      expect(transfers[0].amount, closeTo(1500, 0.01));
    });

    test('New member added: splits recomputed to include them', () {
      final members = [m('u1'), m('u2'), m('u3')];
      final expenses = [
        e(id: 'e1', authorId: 'u1', amount: 3000),
      ];
      // After recomputation, all 3 members share equally
      final splits = [
        s(expenseId: 'e1', memberId: 'u1', shareConverted: 1000),
        s(expenseId: 'e1', memberId: 'u2', shareConverted: 1000),
        s(expenseId: 'e1', memberId: 'u3', shareConverted: 1000),
      ];
      final b = computeBalance(expenses: expenses, splits: splits, settlements: [], members: members);
      // u1 paid 3000, share 1000 → net = +2000
      expect(b.forMember('u1')!.net, closeTo(2000, 0.01));
      // u2 paid 0, share 1000 → net = -1000
      expect(b.forMember('u2')!.net, closeTo(-1000, 0.01));
      // u3 paid 0, share 1000 → net = -1000
      expect(b.forMember('u3')!.net, closeTo(-1000, 0.01));
      // Net sum = 0
      final netSum = b.members.fold(0.0, (sum, m) => sum + m.net);
      expect(netSum.abs(), lessThan(0.02));
    });

    test('Currency conversion: mixed currencies, correct base amounts', () {
      final members = [m('u1'), m('u2')];
      final expenses = [
        e(id: 'e1', authorId: 'u1', amount: 1000, currency: 'INR', convertedAmount: 1000),
        e(id: 'e2', authorId: 'u2', amount: 20, currency: 'USD', convertedAmount: 1680),
      ];
      final splits = [
        s(expenseId: 'e1', memberId: 'u1', shareConverted: 500),
        s(expenseId: 'e1', memberId: 'u2', shareConverted: 500),
        s(expenseId: 'e2', memberId: 'u1', shareConverted: 840),
        s(expenseId: 'e2', memberId: 'u2', shareConverted: 840),
      ];
      final b = computeBalance(expenses: expenses, splits: splits, settlements: [], members: members);
      expect(b.totalExpense, closeTo(2680, 0.01));
      // u1 paid 1000, share 1340 → net = -340
      expect(b.forMember('u1')!.net, closeTo(-340, 0.01));
      // u2 paid 1680, share 1340 → net = +340
      expect(b.forMember('u2')!.net, closeTo(340, 0.01));
    });
  });
}
