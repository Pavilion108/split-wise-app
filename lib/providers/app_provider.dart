import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/sync/cloud_sync.dart';
import '../core/sync/device_identity.dart';
import '../core/sync/op_log_service.dart';
import '../core/sync/sync_service.dart';
import '../models/models.dart';
import '../repositories/expense_repository.dart';
import '../repositories/trip_repository.dart';
import '../services/auth_service.dart';
import '../services/avatar_service.dart';
import '../services/balance_engine.dart';
import '../services/currency_service.dart';
import '../services/daily_brief_service.dart';
import '../services/drive_service.dart';
import '../services/settings_service.dart';
import '../services/user_directory_service.dart';
import '../services/whatsapp_service.dart';

// Conditionally import platform-specific sync modules.
// On web, these stubs are unused but the providers still need
// to compile — the actual constructors are never called.
import '../core/sync/ble_sync.dart' if (dart.library.html) '../core/sync/ble_sync.dart';
import '../core/sync/wifi_sync.dart' if (dart.library.html) '../core/sync/wifi_sync.dart';

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

final settingsServiceProvider = ChangeNotifierProvider<SettingsService>((ref) {
  return SettingsService();
});

// --- Auth ---

final authServiceProvider = ChangeNotifierProvider<AuthService>((ref) {
  return AuthService();
});

// --- Drive ---

final driveServiceProvider = Provider<DriveService>((ref) {
  return DriveService(ref.read(authServiceProvider));
});

// --- WhatsApp ---

final whatsAppServiceProvider = Provider<WhatsAppService>((ref) {
  return WhatsAppService();
});

final userDirectoryServiceProvider = Provider<UserDirectoryService>((ref) {
  return UserDirectoryService();
});

// --- Sync ---

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.read(databaseProvider),
    ref.read(deviceIdentityProvider).id,
  );
});

final cloudSyncProvider = Provider<CloudSyncService>((ref) {
  final auth = ref.watch(authServiceProvider);
  return CloudSyncService(
    ref.read(syncServiceProvider),
    ref.read(deviceIdentityProvider).id,
    auth.currentUser?.id,
  );
});

final wifiSyncProvider = Provider<WifiSyncTransport?>((ref) {
  if (kIsWeb) return null; // WiFi sync uses dart:io — unavailable on web.
  return WifiSyncTransport(
    ref.read(syncServiceProvider),
    ref.read(deviceIdentityProvider).id,
  );
});

final bleSyncProvider = Provider<BleSyncTransport?>((ref) {
  if (kIsWeb) return null; // BLE not available on web.
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
    ref.read(driveServiceProvider),
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
    StreamProvider.family<TripBalance, String>((ref, tripId) {
  final repo = ref.read(expenseRepositoryProvider);
  final tripRepo = ref.read(tripRepositoryProvider);
  return _balanceStream(tripRepo, repo, tripId);
});

/// Combines the underlying watch streams and recomputes the balance only
/// when the underlying data actually changes (no polling → no flicker).
Stream<TripBalance> _balanceStream(
  TripRepository tripRepo,
  ExpenseRepository repo,
  String tripId,
) {
  final controller = StreamController<TripBalance>();
  List<Member>? m;
  List<Expense>? e;
  List<Split>? s;
  List<Settlement>? st;
  final subs = <StreamSubscription>[];

  void emitIfReady() {
    if (m != null && e != null && s != null && st != null) {
      controller.add(computeBalance(
        expenses: e!,
        splits: s!,
        settlements: st!,
        members: m!,
      ));
    }
  }

  subs.add(tripRepo.watchMembers(tripId).listen((v) {
    m = v;
    emitIfReady();
  }));
  subs.add(repo.watchExpenses(tripId).listen((v) {
    e = v;
    emitIfReady();
  }));
  subs.add(repo.watchSplits(tripId).listen((v) {
    s = v;
    emitIfReady();
  }));
  subs.add(repo.watchSettlements(tripId).listen((v) {
    st = v;
    emitIfReady();
  }));

  controller.onCancel = () {
    for (final sub in subs) sub.cancel();
  };

  return controller.stream;
}

final tripBalanceProvider =
    Provider.family<AsyncValue<TripBalance?>, String>((ref, tripId) {
  final streamRef = ref.watch(tripBalanceStreamProvider(tripId));
  return streamRef.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (b) => AsyncData(b),
  );
});

// Stable stream providers — Riverpod keeps the subscription alive across widget
// rebuilds, so consumers (e.g. the Expenses/Payments tabs) don't re-subscribe
// and flash a loading state when the parent rebuilds.

final tripStreamProvider = StreamProvider.family<Trip?, String>((ref, tripId) {
  final repo = ref.read(tripRepositoryProvider);
  return repo.watchTrip(tripId);
});

final membersStreamProvider =
    StreamProvider.family<List<Member>, String>((ref, tripId) {
  final repo = ref.read(tripRepositoryProvider);
  return repo.watchMembers(tripId);
});

final expensesStreamProvider =
    StreamProvider.family<List<Expense>, String>((ref, tripId) {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.watchExpenses(tripId);
});

final settlementsStreamProvider =
    StreamProvider.family<List<Settlement>, String>((ref, tripId) {
  final repo = ref.read(expenseRepositoryProvider);
  return repo.watchSettlements(tripId);
});

