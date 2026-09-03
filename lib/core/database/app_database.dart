import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../constants.dart';

part 'app_database.g.dart';

@DataClassName('TripRow')
class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get baseCurrency => text().withDefault(const Constant('INR'))();
  /// 6-char invite code for sharing via WhatsApp/Gmail.
  TextColumn get inviteCode => text().withDefault(const Constant(''))();
  /// Google Drive folder ID for this trip's photos/receipts.
  TextColumn get driveFolderId => text().withDefault(const Constant(''))();
  /// Google Drive web link (for sharing with members).
  TextColumn get driveFolderLink => text().withDefault(const Constant(''))();
  /// WhatsApp group invite link.
  TextColumn get whatsappGroupLink => text().withDefault(const Constant(''))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  /// Trip lifecycle status: 'active' or 'completed'.
  TextColumn get status => text().withDefault(const Constant('active'))();
  /// Timestamp when the trip was marked completed (null while active).
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MemberRow')
class Members extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id)();
  TextColumn get name => text()();
  TextColumn get deviceId => text()();
  IntColumn get avatarColor => integer().withDefault(const Constant(0xFF1E88E5))();
  TextColumn get avatarAsset => text().withDefault(const Constant(''))();
  TextColumn get googleId => text().withDefault(const Constant(''))();
  TextColumn get emailLower => text().withDefault(const Constant(''))();
  DateTimeColumn get joinedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get tripId => text().nullable().references(Trips, #id)();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id)();
  TextColumn get authorId => text().references(Members, #id)();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get currency => text()();
  RealColumn get convertedAmount => real()();
  RealColumn get rateUsed => real()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get splitType => text().withDefault(const Constant('equal'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get editedAt => dateTime().nullable()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SplitRow')
class SplitRows extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text().references(Expenses, #id)();
  TextColumn get memberId => text().references(Members, #id)();
  RealColumn get shareAmount => real()();
  RealColumn get shareConverted => real()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettlementRow')
class Settlements extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text().references(Trips, #id)();
  TextColumn get fromMemberId => text().references(Members, #id)();
  TextColumn get toMemberId => text().references(Members, #id)();
  RealColumn get amount => real()();
  RealColumn get partialRemaining => real().nullable()();
  /// Payment method: 'upi', 'cash', 'other' (empty = legacy).
  TextColumn get method => text().withDefault(const Constant(''))();
  /// Provider transaction reference / id (for audit trail).
  TextColumn get transactionRef => text().withDefault(const Constant(''))();
  /// 'paid' or 'pending'.
  TextColumn get status => text().withDefault(const Constant('paid'))();
  /// When the payment was verified/confirmed.
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get paidAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('RateCacheRow')
class RateCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get baseCurrency => text()();
  TextColumn get currency => text()();
  RealColumn get rateInBase => real()();
  TextColumn get source => text().withDefault(const Constant('rbi'))();
  DateTimeColumn get fetchedAt => dateTime()();
}

@DataClassName('OpLogRow')
class OpLogs extends Table {
  TextColumn get id => text()();
  TextColumn get tripId => text()();
  TextColumn get opType => text()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()();
  TextColumn get authorDevice => text()();
  IntColumn get lamportTs => integer()();
  IntColumn get deviceCounter => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Trips,
  Members,
  Categories,
  Expenses,
  SplitRows,
  Settlements,
  RateCaches,
  OpLogs,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedDefaultCategories();
        },
        onUpgrade: (m, from, to) async {
          if (from < 5) {
            await m.addColumn(trips, trips.status);
            await m.addColumn(trips, trips.completedAt);
          }
          if (from < 6) {
            await m.addColumn(settlements, settlements.method);
            await m.addColumn(settlements, settlements.transactionRef);
            await m.addColumn(settlements, settlements.status);
            await m.addColumn(settlements, settlements.verifiedAt);
          }
          if (from < 7) {
            await m.addColumn(members, members.avatarAsset);
            await m.addColumn(members, members.googleId);
            await m.addColumn(members, members.emailLower);
          }
        },
      );

  Future<void> _seedDefaultCategories() async {
    await batch((b) {
      for (final name in kDefaultCategories) {
        b.insert(
          categories,
          CategoriesCompanion.insert(
            id: _uuid(),
            name: name,
            isDefault: const Value(true),
          ),
        );
      }
    });
  }

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'split_wise',
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      );
}
String _uuid() {
  return const Uuid().v4();
}
