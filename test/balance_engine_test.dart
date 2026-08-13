import 'package:flutter_test/flutter_test.dart';
import 'package:split_wise/models/models.dart';
import 'package:split_wise/services/balance_engine.dart';
import 'package:split_wise/services/split_calculator.dart';

void main() {
  group('Split Calculator', () {
    test('equal split among all members', () {
      final splits = computeSplits(
        amount: 100,
        type: 'equal',
        allMemberIds: ['a', 'b', 'c'],
      );
      expect(splits.length, 3);
      expect(splits[0].amount, closeTo(33.33, 0.01));
      expect(splits[1].amount, closeTo(33.33, 0.01));
      expect(splits[2].amount, closeTo(33.33, 0.01));
    });

    test('equal split with single member', () {
      final splits = computeSplits(
        amount: 50,
        type: 'equal',
        allMemberIds: ['a'],
      );
      expect(splits.length, 1);
      expect(splits[0].amount, 50);
    });

    test('custom split among subset', () {
      final splits = computeSplits(
        amount: 120,
        type: 'custom',
        allMemberIds: ['a', 'b', 'c', 'd'],
        subsetIds: ['a', 'b'],
      );
      expect(splits.length, 2);
      expect(splits[0].amount, 60);
      expect(splits[1].amount, 60);
    });

    test('zero amount returns empty', () {
      final splits = computeSplits(
        amount: 0,
        type: 'equal',
        allMemberIds: ['a', 'b'],
      );
      expect(splits, isEmpty);
    });
  });

  group('Balance Engine', () {
    Member m(String id) => Member(
          id: id,
          tripId: 'trip1',
          name: id,
          deviceId: 'dev_$id',
          avatarColor: 0,
          joinedAt: DateTime(2026),
        );

    test('no expenses: all balances zero', () {
      final balance = computeBalance(
        expenses: [],
        splits: [],
        settlements: [],
        members: [m('a'), m('b')],
      );
      expect(balance.totalExpense, 0);
      expect(balance.forMember('a')!.net, 0);
      expect(balance.forMember('b')!.net, 0);
    });

    test('single equal expense splits evenly', () {
      final balance = computeBalance(
        expenses: [
          Expense(
            id: 'e1',
            tripId: 'trip1',
            authorId: 'a',
            category: 'Food',
            amount: 300,
            currency: 'INR',
            convertedAmount: 300,
            rateUsed: 1,
            splitType: 'equal',
            createdAt: DateTime(2026),
          ),
        ],
        splits: [
          Split(id: 's1', expenseId: 'e1', memberId: 'a', shareAmount: 150, shareConverted: 150),
          Split(id: 's2', expenseId: 'e1', memberId: 'b', shareAmount: 150, shareConverted: 150),
        ],
        settlements: [],
        members: [m('a'), m('b')],
      );

      expect(balance.totalExpense, closeTo(300, 0.01));
      expect(balance.forMember('a')!.net, closeTo(150, 0.01));
      expect(balance.forMember('b')!.net, closeTo(-150, 0.01));
    });

    test('settlement reduces net balance', () {
      final balance = computeBalance(
        expenses: [
          Expense(
            id: 'e1',
            tripId: 'trip1',
            authorId: 'a',
            category: 'Food',
            amount: 300,
            currency: 'INR',
            convertedAmount: 300,
            rateUsed: 1,
            splitType: 'equal',
            createdAt: DateTime(2026),
          ),
        ],
        splits: [
          Split(id: 's1', expenseId: 'e1', memberId: 'a', shareAmount: 150, shareConverted: 150),
          Split(id: 's2', expenseId: 'e1', memberId: 'b', shareAmount: 150, shareConverted: 150),
        ],
        settlements: [
          Settlement(
            id: 'st1',
            tripId: 'trip1',
            fromMemberId: 'b',
            toMemberId: 'a',
            amount: 100,
            paidAt: DateTime(2026),
          ),
        ],
        members: [m('a'), m('b')],
      );

      expect(balance.forMember('a')!.net, closeTo(50, 0.01));
      expect(balance.forMember('b')!.net, closeTo(-50, 0.01));
    });

    test('deleted expenses excluded', () {
      final balance = computeBalance(
        expenses: [
          Expense(
            id: 'e1',
            tripId: 'trip1',
            authorId: 'a',
            category: 'Food',
            amount: 300,
            currency: 'INR',
            convertedAmount: 300,
            rateUsed: 1,
            splitType: 'equal',
            createdAt: DateTime(2026),
            deleted: true,
          ),
        ],
        splits: [],
        settlements: [],
        members: [m('a'), m('b')],
      );

      expect(balance.totalExpense, 0);
      expect(balance.forMember('a')!.net, 0);
    });

    test('three members: complex scenario', () {
      final balance = computeBalance(
        expenses: [
          Expense(
            id: 'e1',
            tripId: 'trip1',
            authorId: 'a',
            category: 'Hotel',
            amount: 3000,
            currency: 'INR',
            convertedAmount: 3000,
            rateUsed: 1,
            splitType: 'equal',
            createdAt: DateTime(2026),
          ),
        ],
        splits: [
          Split(id: 's1', expenseId: 'e1', memberId: 'a', shareAmount: 1000, shareConverted: 1000),
          Split(id: 's2', expenseId: 'e1', memberId: 'b', shareAmount: 1000, shareConverted: 1000),
          Split(id: 's3', expenseId: 'e1', memberId: 'c', shareAmount: 1000, shareConverted: 1000),
        ],
        settlements: [],
        members: [m('a'), m('b'), m('c')],
      );

      expect(balance.forMember('a')!.net, closeTo(2000, 0.01));
      expect(balance.forMember('b')!.net, closeTo(-1000, 0.01));
      expect(balance.forMember('c')!.net, closeTo(-1000, 0.01));
    });
  });

  group('Settlement Suggestions', () {
    Member m(String id) => Member(
          id: id,
          tripId: 'trip1',
          name: id,
          deviceId: 'dev_$id',
          avatarColor: 0,
          joinedAt: DateTime(2026),
        );

    test('minimal transfers for two members', () {
      final balance = computeBalance(
        expenses: [
          Expense(
            id: 'e1',
            tripId: 'trip1',
            authorId: 'a',
            category: 'Food',
            amount: 200,
            currency: 'INR',
            convertedAmount: 200,
            rateUsed: 1,
            splitType: 'equal',
            createdAt: DateTime(2026),
          ),
        ],
        splits: [
          Split(id: 's1', expenseId: 'e1', memberId: 'a', shareAmount: 100, shareConverted: 100),
          Split(id: 's2', expenseId: 'e1', memberId: 'b', shareAmount: 100, shareConverted: 100),
        ],
        settlements: [],
        members: [m('a'), m('b')],
      );

      final transfers = suggestSettlements(balance);
      expect(transfers.length, 1);
      expect(transfers[0].from, 'b');
      expect(transfers[0].to, 'a');
      expect(transfers[0].amount, closeTo(100, 0.01));
    });

    test('three members: minimal transfers', () {
      final balance = computeBalance(
        expenses: [
          Expense(
            id: 'e1',
            tripId: 'trip1',
            authorId: 'a',
            category: 'Hotel',
            amount: 3000,
            currency: 'INR',
            convertedAmount: 3000,
            rateUsed: 1,
            splitType: 'equal',
            createdAt: DateTime(2026),
          ),
        ],
        splits: [
          Split(id: 's1', expenseId: 'e1', memberId: 'a', shareAmount: 1000, shareConverted: 1000),
          Split(id: 's2', expenseId: 'e1', memberId: 'b', shareAmount: 1000, shareConverted: 1000),
          Split(id: 's3', expenseId: 'e1', memberId: 'c', shareAmount: 1000, shareConverted: 1000),
        ],
        settlements: [],
        members: [m('a'), m('b'), m('c')],
      );

      final transfers = suggestSettlements(balance);
      expect(transfers.length, 2);
      expect(transfers[0].to, 'a');
      expect(transfers[0].amount, closeTo(1000, 0.01));
    });
  });
}
