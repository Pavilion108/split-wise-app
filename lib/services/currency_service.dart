import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../core/database/app_database.dart';

/// Result of a live rate fetch.
class LiveRate {
  const LiveRate({
    required this.rate,
    required this.source,
    required this.fetchedAt,
  });

  /// Rate: 1 unit of [currency] = [rate] units of [baseCurrency].
  final double rate;
  /// Human-readable source label (e.g. "Live market rate").
  final String source;
  final DateTime fetchedAt;
}

/// Cached rate with freshness metadata.
class CachedRate {
  const CachedRate({
    required this.rate,
    required this.fetchedAt,
  });
  final double rate;
  final DateTime fetchedAt;
}

class CurrencyService {
  CurrencyService(this._db);
  final AppDatabase _db;

  /// Maximum age for a cached rate to be considered fresh (7 days).
  static const _stalenessDuration = Duration(days: 7);

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
    final cached = await getRateWithFreshness(
      fromCurrency: fromCurrency,
      toBase: toBase,
    );
    return cached?.rate;
  }

  /// Returns [CachedRate] with freshness info, or null if no cached rate.
  Future<CachedRate?> getRateWithFreshness({
    required String fromCurrency,
    required String toBase,
  }) async {
    if (fromCurrency == toBase) {
      return CachedRate(rate: 1, fetchedAt: DateTime.now());
    }
    final row = await (_db.select(_db.rateCaches)
          ..where((r) =>
              r.baseCurrency.equals(toBase) &
              r.currency.equals(fromCurrency)))
        .getSingleOrNull();
    if (row == null) return null;
    return CachedRate(rate: row.rateInBase, fetchedAt: row.fetchedAt);
  }

  /// Returns true if the cached rate is older than [_stalenessDuration].
  Future<bool> isRateStale({
    required String fromCurrency,
    required String toBase,
  }) async {
    final cached = await getRateWithFreshness(
      fromCurrency: fromCurrency,
      toBase: toBase,
    );
    if (cached == null) return true;
    return DateTime.now().difference(cached.fetchedAt) > _stalenessDuration;
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

  /// Fetch the current market rate from a free, no-key FX source.
  ///
  /// The provider name is intentionally NOT surfaced to the user; callers
  /// should display [LiveRate.source] ("Live market rate") for the audit trail.
  Future<LiveRate> fetchLiveRate({
    required String fromCurrency,
    required String toBase,
  }) async {
    if (fromCurrency == toBase) {
      return LiveRate(
        rate: 1,
        source: 'Live market rate',
        fetchedAt: DateTime.now(),
      );
    }

    final uri = Uri.parse(
      'https://open.er-api.com/v6/latest/$fromCurrency',
    );
    final resp = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 12));
    if (resp.statusCode != 200) {
      throw Exception('Rate service returned ${resp.statusCode}');
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final rates = json['rates'] as Map<String, dynamic>?;
    final rate = (rates?[toBase] as num?)?.toDouble();
    if (rate == null) {
      throw Exception('Rate for $toBase unavailable');
    }

    return LiveRate(
      rate: rate,
      source: 'Live market rate',
      fetchedAt: DateTime.now(),
    );
  }
}
