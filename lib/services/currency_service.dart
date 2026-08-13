import 'package:drift/drift.dart';

import '../core/database/app_database.dart';

class CurrencyService {
  CurrencyService(this._db);
  final AppDatabase _db;

  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toBase,
  }) async {
    if (fromCurrency == toBase) return amount;
    final rate = await getRate(fromCurrency: fromCurrency, toBase: toBase);
    if (rate == null) return amount;
    return amount * rate;
  }

  Future<double?> getRate({
    required String fromCurrency,
    required String toBase,
  }) async {
    if (fromCurrency == toBase) return 1;
    final row = await (_db.select(_db.rateCaches)
          ..where((r) =>
              r.baseCurrency.equals(toBase) &
              r.currency.equals(fromCurrency)))
        .getSingleOrNull();
    return row?.rateInBase;
  }

  Future<void> setRate({
    required String baseCurrency,
    required String currency,
    required double rate,
    String source = 'manual',
  }) async {
    if (baseCurrency == currency) return;
    final existing = await (_db.select(_db.rateCaches)
          ..where((r) =>
              r.baseCurrency.equals(baseCurrency) &
              r.currency.equals(currency)))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.rateCaches)
            ..where((r) => r.id.equals(existing.id)))
          .write(RateCachesCompanion(
        rateInBase: Value(rate),
        source: Value(source),
        fetchedAt: Value(DateTime.now()),
      ));
    } else {
      await _db.into(_db.rateCaches).insert(RateCachesCompanion.insert(
            baseCurrency: baseCurrency,
            currency: currency,
            rateInBase: rate,
            source: Value(source),
            fetchedAt: DateTime.now(),
          ));
    }
  }

  Future<List<RateCacheRow>> allRates(String baseCurrency) {
    return (_db.select(_db.rateCaches)
          ..where((r) => r.baseCurrency.equals(baseCurrency)))
        .get();
  }
}
