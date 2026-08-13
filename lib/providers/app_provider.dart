import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/sync/ble_sync.dart';
import '../core/sync/cloud_sync.dart';
import '../core/sync/device_identity.dart';
import '../core/sync/op_log_service.dart';
import '../core/sync/sync_service.dart';
import '../core/sync/wifi_sync.dart';
import '../models/models.dart';
import '../repositories/expense_repository.dart';
import '../repositories/trip_repository.dart';
import '../services/auth_service.dart';
import '../services/balance_engine.dart';
import '../services/currency_service.dart';
import '../services/daily_brief_service.dart';
import '../services/drive_service.dart';
import '../services/whatsapp_service.dart';

// --- Infrastructure ---

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final deviceIdentityProvider =
    Provider<DeviceIdentity>((ref) => DeviceIdentity.forTesting('boot'));

final opLogServiceProvider = Provider<OpLogService>((ref) {
  return OpLogService(
    ref.read(databaseProvider),
    deviceId: ref.read(deviceIdentityProvider).id,
  );
});

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService(ref.read(databaseProvider));
});

// --- Auth ---

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(service.dispose);
  return service;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authServiceProvider).authState;
});

// --- Drive ---

final driveServiceProvider = Provider<DriveService>((ref) {
  return DriveService(ref.read(authServiceProvider));
});

// --- WhatsApp ---

final whatsAppServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService();
});

// --- Sync ---

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(databaseProvider),
    ref.read(deviceIdentityProvider).id,
  );
});

final cloudSyncProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService(
    ref.read(syncServiceProvider),
    ref.read(deviceIdentityProvider).id,
  );
});

final wifiSyncProvider = Provider<WifiSyncTransport>((ref) {
  return WifiSyncTransport(
    ref.read(syncServiceProvider),
    ref.read(deviceIdentityProvider).id,
  );
});

final bleSyncProvider = Provider<BleSyncTransport>((ref) {
  return BleSyncTransport(
    ref.read(syncServiceProvider),
  );
});

// --- Repositories ---

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository(
    ref.read(databaseProvider),
    ref.read(opLogServiceProvider),
    ref.read(cloudSyncProvider),
  );
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    ref.read(databaseProvider),
    ref.read(opLogServiceProvider),
    ref.read(currencyServiceProvider),
    ref.read(cloudSyncProvider),
  );
});

// --- Daily Brief ---

final dailyBriefServiceProvider = Provider<DailyBriefService>((ref) {
  return DailyBriefService(
    ref.read(expenseRepositoryProvider),
    ref.read(tripRepositoryProvider),
    ref.read(whatsAppServiceProvider),
  );
});

// --- Balance ---

final tripBalanceStreamProvider =
    StreamProvider.family<TripBalance, String>((ref, tripId) async* {
  final repo = ref.read(expenseRepositoryProvider);
  final tripRepo = ref.read(tripRepositoryProvider);

  await for (final _ in Stream.periodic(const Duration(milliseconds: 200))) {
    final members = await tripRepo.watchMembers(tripId).first;
    final expenses = await repo.watchExpenses(tripId).first;
    final splits = await repo.watchSplits(tripId).first;
    final settlements = await repo.watchSettlements(tripId).first;
    yield computeBalance(
      expenses: expenses,
      splits: splits,
      settlements: settlements,
      members: members,
    );
  }
});

final tripBalanceProvider =
    Provider.family<AsyncValue<TripBalance?>, String>((ref, tripId) {
  final streamRef = ref.watch(tripBalanceStreamProvider(tripId));
  return streamRef.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (b) => AsyncData(b),
  );
});
