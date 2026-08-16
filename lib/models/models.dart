import '../core/database/app_database.dart';

class Trip {
  Trip({
    required this.id,
    required this.name,
    required this.baseCurrency,
    required this.createdAt,
    this.inviteCode = '',
    this.driveFolderId = '',
    this.driveFolderLink = '',
    this.whatsappGroupLink = '',
    this.deleted = false,
    this.status = 'active',
    this.completedAt,
  });

  factory Trip.fromRow(TripRow row) => Trip(
        id: row.id,
        name: row.name,
        baseCurrency: row.baseCurrency,
        createdAt: row.createdAt,
        inviteCode: row.inviteCode,
        driveFolderId: row.driveFolderId,
        driveFolderLink: row.driveFolderLink,
        whatsappGroupLink: row.whatsappGroupLink,
        deleted: row.deleted,
        status: row.status,
        completedAt: row.completedAt,
      );

  final String id;
  final String name;
  final String baseCurrency;
  final DateTime createdAt;
  final String inviteCode;
  final String driveFolderId;
  final String driveFolderLink;
  final String whatsappGroupLink;
  final bool deleted;
  final String status;
  final DateTime? completedAt;
}

class Member {
  Member({
    required this.id,
    required this.tripId,
    required this.name,
    required this.deviceId,
    required this.avatarColor,
    required this.joinedAt,
    this.deleted = false,
  });

  factory Member.fromRow(MemberRow row) => Member(
        id: row.id,
        tripId: row.tripId,
        name: row.name,
        deviceId: row.deviceId,
        avatarColor: row.avatarColor,
        joinedAt: row.joinedAt,
        deleted: row.deleted,
      );

  final String id;
  final String tripId;
  final String name;
  final String deviceId;
  final int avatarColor;
  final DateTime joinedAt;
  final bool deleted;
}

class Expense {
  Expense({
    required this.id,
    required this.tripId,
    required this.authorId,
    required this.category,
    required this.amount,
    required this.currency,
    required this.convertedAmount,
    required this.rateUsed,
    required this.splitType,
    required this.createdAt,
    this.note = '',
    this.editedAt,
    this.deleted = false,
  });

  factory Expense.fromRow(ExpenseRow row) => Expense(
        id: row.id,
        tripId: row.tripId,
        authorId: row.authorId,
        category: row.category,
        amount: row.amount,
        currency: row.currency,
        convertedAmount: row.convertedAmount,
        rateUsed: row.rateUsed,
        splitType: row.splitType,
        createdAt: row.createdAt,
        note: row.note,
        editedAt: row.editedAt,
        deleted: row.deleted,
      );

  final String id;
  final String tripId;
  final String authorId;
  final String category;
  final double amount;
  final String currency;
  final double convertedAmount;
  final double rateUsed;
  final String splitType;
  final DateTime createdAt;
  final String note;
  final DateTime? editedAt;
  final bool deleted;
}

class Split {
  Split({
    required this.id,
    required this.expenseId,
    required this.memberId,
    required this.shareAmount,
    required this.shareConverted,
  });

  factory Split.fromRow(SplitRow row) => Split(
        id: row.id,
        expenseId: row.expenseId,
        memberId: row.memberId,
        shareAmount: row.shareAmount,
        shareConverted: row.shareConverted,
      );

  final String id;
  final String expenseId;
  final String memberId;
  final double shareAmount;
  final double shareConverted;
}

class Settlement {
  Settlement({
    required this.id,
    required this.tripId,
    required this.fromMemberId,
    required this.toMemberId,
    required this.amount,
    required this.paidAt,
    this.partialRemaining,
    this.note = '',
    this.deleted = false,
  });

  factory Settlement.fromRow(SettlementRow row) => Settlement(
        id: row.id,
        tripId: row.tripId,
        fromMemberId: row.fromMemberId,
        toMemberId: row.toMemberId,
        amount: row.amount,
        partialRemaining: row.partialRemaining,
        note: row.note,
        paidAt: row.paidAt,
        deleted: row.deleted,
      );

  final String id;
  final String tripId;
  final String fromMemberId;
  final String toMemberId;
  final double amount;
  final double? partialRemaining;
  final String note;
  final DateTime paidAt;
  final bool deleted;
}

class Category {
  Category({
    required this.id,
    required this.name,
    required this.isDefault,
    this.tripId,
    this.deleted = false,
  });

  factory Category.fromRow(CategoryRow row) => Category(
        id: row.id,
        name: row.name,
        tripId: row.tripId,
        isDefault: row.isDefault,
        deleted: row.deleted,
      );

  final String id;
  final String name;
  final String? tripId;
  final bool isDefault;
  final bool deleted;
}

class Balance {
  const Balance({
    required this.memberId,
    required this.paid,
    required this.share,
    required this.received,
    required this.paidOut,
  });

  final String memberId;
  final double paid;
  final double share;
  final double received;
  final double paidOut;

  /// Positive = should RECEIVE. Negative = should PAY.
  double get net => paid - share - received + paidOut;
}

class TripBalance {
  const TripBalance({
    required this.totalExpense,
    required this.members,
  });

  final double totalExpense;
  final List<Balance> members;

  Balance? forMember(String memberId) {
    for (final b in members) {
      if (b.memberId == memberId) return b;
    }
    return null;
  }
}

class SuggestedTransfer {
  const SuggestedTransfer({
    required this.from,
    required this.to,
    required this.amount,
  });

  final String from;
  final String to;
  final double amount;
}
