import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:simple_calculator/util/storage_manager.dart';

class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;
}

class CurrencyConverterStore extends ChangeNotifier {
  CurrencyConverterStore._();

  static final CurrencyConverterStore instance = CurrencyConverterStore._();

  static const _ratesKey = 'currency_rates_v1';
  static const _updatedAtKey = 'currency_rates_updated_at_v1';
  static const _customRatesKey = 'currency_custom_rates_v1';
  static const _fromKey = 'currency_last_from_v1';
  static const _toKey = 'currency_last_to_v1';

  static const List<CurrencyInfo> currencies = [
    CurrencyInfo(code: 'USD', symbol: r'$', name: 'US Dollar'),
    CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    CurrencyInfo(code: 'HKD', symbol: r'HK$', name: 'Hong Kong Dollar'),
    CurrencyInfo(code: 'TWD', symbol: r'NT$', name: 'New Taiwan Dollar'),
    CurrencyInfo(code: 'AUD', symbol: r'A$', name: 'Australian Dollar'),
    CurrencyInfo(code: 'NZD', symbol: r'NZ$', name: 'New Zealand Dollar'),
    CurrencyInfo(code: 'CAD', symbol: r'C$', name: 'Canadian Dollar'),
    CurrencyInfo(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc'),
    CurrencyInfo(code: 'SGD', symbol: r'S$', name: 'Singapore Dollar'),
    CurrencyInfo(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    CurrencyInfo(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    CurrencyInfo(code: 'MXN', symbol: r'MX$', name: 'Mexican Peso'),
    CurrencyInfo(code: 'BRL', symbol: r'R$', name: 'Brazilian Real'),
    CurrencyInfo(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
    CurrencyInfo(code: 'NOK', symbol: 'kr', name: 'Norwegian Krone'),
    CurrencyInfo(code: 'AED', symbol: 'AED', name: 'UAE Dirham'),
    CurrencyInfo(code: 'THB', symbol: '฿', name: 'Thai Baht'),
  ];

  /// Built-in offline reference rates (units per 1 USD).
  static const Map<String, double> defaultRatesPerUsd = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 154.0,
    'CNY': 7.24,
    'HKD': 7.78,
    'TWD': 32.5,
    'AUD': 1.54,
    'NZD': 1.69,
    'CAD': 1.40,
    'CHF': 0.88,
    'SGD': 1.34,
    'KRW': 1395.0,
    'INR': 84.4,
    'MXN': 20.3,
    'BRL': 5.80,
    'SEK': 10.9,
    'NOK': 11.0,
    'AED': 3.6725,
    'THB': 34.5,
  };

  final Map<String, double> _rates = Map<String, double>.of(defaultRatesPerUsd);
  final Map<String, double> _customRates = {};
  String? _updatedAtIso;
  String _lastFrom = 'USD';
  String _lastTo = 'EUR';
  bool _loaded = false;

  String? get updatedAtIso => _updatedAtIso;
  String get lastFrom => _lastFrom;
  String get lastTo => _lastTo;

  static CurrencyInfo infoFor(String code) => currencies.firstWhere(
    (c) => c.code == code,
    orElse: () => currencies.first,
  );

  void ensureLoaded() {
    if (_loaded) return;
    load();
  }

  void load() {
    _loaded = true;
    _rates
      ..clear()
      ..addAll(defaultRatesPerUsd);
    _customRates.clear();
    _updatedAtIso = null;
    _lastFrom = 'USD';
    _lastTo = 'EUR';

    try {
      final prefs = StorageManager.sharedPreferences;
      if (prefs == null) return;

      final rawRates = prefs.getString(_ratesKey);
      if (rawRates != null) {
        final decoded = jsonDecode(rawRates);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final key = entry.key;
            final val = entry.value;
            if (key is String &&
                defaultRatesPerUsd.containsKey(key) &&
                val is num &&
                val.isFinite &&
                val > 0) {
              _rates[key] = val.toDouble();
            }
          }
          _rates['USD'] = 1.0;
        }
      }

      final updated = prefs.getString(_updatedAtKey);
      if (updated != null && updated.isNotEmpty) {
        _updatedAtIso = updated;
      }

      final rawCustom = prefs.getString(_customRatesKey);
      if (rawCustom != null) {
        final decoded = jsonDecode(rawCustom);
        if (decoded is Map) {
          for (final entry in decoded.entries) {
            final key = entry.key;
            final val = entry.value;
            if (key is String && val is num && val.isFinite && val > 0) {
              _customRates[key] = val.toDouble();
            }
          }
        }
      }

      final savedFrom = prefs.getString(_fromKey);
      if (savedFrom != null && defaultRatesPerUsd.containsKey(savedFrom)) {
        _lastFrom = savedFrom;
      }
      final savedTo = prefs.getString(_toKey);
      if (savedTo != null && defaultRatesPerUsd.containsKey(savedTo)) {
        _lastTo = savedTo;
      }
    } catch (error) {
      debugPrint('Currency settings unavailable: $error');
    }
    notifyListeners();
  }

  String _pairKey(String from, String to) => '${from}_$to';

  bool hasCustomRate(String from, String to) =>
      from != to && _customRates.containsKey(_pairKey(from, to));

  double baseRateBetween(String from, String to) {
    if (from == to) return 1.0;
    final fromPerUsd = _rates[from] ?? 1.0;
    final toPerUsd = _rates[to] ?? 1.0;
    return toPerUsd / fromPerUsd;
  }

  double rateBetween(String from, String to) {
    if (from == to) return 1.0;
    return _customRates[_pairKey(from, to)] ?? baseRateBetween(from, to);
  }

  double convert(double amount, String from, String to) =>
      amount * rateBetween(from, to);

  void setPair(String from, String to) {
    if (!defaultRatesPerUsd.containsKey(from) ||
        !defaultRatesPerUsd.containsKey(to)) {
      return;
    }
    _lastFrom = from;
    _lastTo = to;
    final prefs = StorageManager.sharedPreferences;
    if (prefs != null) {
      unawaited(prefs.setString(_fromKey, from));
      unawaited(prefs.setString(_toKey, to));
    }
    notifyListeners();
  }

  void setCustomRate(String from, String to, double rate) {
    if (from == to || !rate.isFinite || rate <= 0) return;
    _customRates[_pairKey(from, to)] = rate;
    _persistCustomRates();
    notifyListeners();
  }

  void clearCustomRate(String from, String to) {
    if (_customRates.remove(_pairKey(from, to)) == null) return;
    _persistCustomRates();
    notifyListeners();
  }

  void _persistCustomRates() {
    try {
      final prefs = StorageManager.sharedPreferences;
      if (prefs == null) return;
      unawaited(prefs.setString(_customRatesKey, jsonEncode(_customRates)));
    } catch (_) {}
  }

  /// Fetches live reference rates (base USD) from Frankfurter (ECB data),
  /// falling back gracefully to saved/offline rates when offline.
  Future<bool> refreshOnline({
    Future<Map<String, double>?> Function()? fetcher,
  }) async {
    try {
      final fetched = await (fetcher ?? _fetchFrankfurterRates)();
      if (fetched == null || fetched.isEmpty) return false;
      var updated = false;
      for (final entry in fetched.entries) {
        if (defaultRatesPerUsd.containsKey(entry.key) &&
            entry.value.isFinite &&
            entry.value > 0) {
          _rates[entry.key] = entry.value;
          updated = true;
        }
      }
      if (!updated) return false;
      _rates['USD'] = 1.0;
      final now = DateTime.now();
      _updatedAtIso =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final prefs = StorageManager.sharedPreferences;
      if (prefs != null) {
        unawaited(prefs.setString(_ratesKey, jsonEncode(_rates)));
        unawaited(prefs.setString(_updatedAtKey, _updatedAtIso!));
      }
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('Currency refresh failed: $error');
      return false;
    }
  }

  static Future<Map<String, double>?> _fetchFrankfurterRates() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final request = await client
          .getUrl(Uri.parse('https://api.frankfurter.app/latest?from=USD'))
          .timeout(const Duration(seconds: 5));
      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 5));
      final decoded = jsonDecode(body);
      if (decoded is! Map || decoded['rates'] is! Map) return null;
      final result = <String, double>{'USD': 1.0};
      for (final entry in (decoded['rates'] as Map).entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is num && value.isFinite && value > 0) {
          result[key] = value.toDouble();
        }
      }
      return result;
    } finally {
      client.close(force: true);
    }
  }
}
