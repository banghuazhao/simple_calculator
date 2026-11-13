import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum PremiumOutcome {
  purchased,
  restored,
  pending,
  cancelled,
  notPurchased,
  unavailable,
  failed,
  busy,
}

abstract interface class PremiumStore {
  Stream<bool> get entitlementUpdates;

  Future<bool> currentEntitlement();
  Future<String?> loadPrice();
  Future<PremiumOutcome> purchase();
  Future<PremiumOutcome> restore();
}

class PremiumController extends ChangeNotifier {
  PremiumController({
    PremiumStore? store,
    bool? supported,
    Duration lookupTimeout = const Duration(seconds: 5),
  }) : _store = store ?? const _NativeStore(),
       _supported =
           supported ??
           (!kIsWeb &&
               (defaultTargetPlatform == TargetPlatform.iOS ||
                   defaultTargetPlatform == TargetPlatform.macOS ||
                   defaultTargetPlatform == TargetPlatform.android)),
       offersAdRemoval =
           !kIsWeb &&
           (defaultTargetPlatform == TargetPlatform.iOS ||
               defaultTargetPlatform == TargetPlatform.android),
       _lookupTimeout = lookupTimeout;

  // Store product IDs; the native bridges own the lookup.
  static const productId = 'com.appsbay.simpleCalculator.premium';
  static const playProductId = 'premium';

  // The native bridge reports this when the device has no usable billing
  // service (e.g. no Google Play), so Premium is hidden and ads keep serving.
  static const unavailableErrorCode = 'billing_unavailable';

  final bool offersAdRemoval;
  final PremiumStore _store;
  final Duration _lookupTimeout;
  bool _supported;
  bool? _entitlement;
  bool _finishedInitialCheck = false;
  bool _busy = false;
  bool _disposed = false;
  int _entitlementRevision = 0;
  String? _price;
  Future<void>? _initialization;
  Future<void>? _readingEntitlement;
  Future<void>? _loadingPrice;
  StreamSubscription<bool>? _updates;

  bool get isSupported => _supported;
  bool get isPremium => _entitlement == true;
  bool get isChecking => isSupported && !_finishedInitialCheck;
  bool get isBusy => _busy;
  String? get price => _price;

  // Wait for a definitive store answer before serving ads.
  bool get allowsAds =>
      offersAdRemoval && !isPremium && (!isSupported || _entitlement == false);

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    await refreshEntitlement();
    unawaited(loadProduct());
  }

  Future<void> refreshEntitlement() async {
    if (_disposed || !isSupported) return;
    final reading = _readingEntitlement ??= _readEntitlement().whenComplete(
      () => _readingEntitlement = null,
    );
    try {
      await reading.timeout(_lookupTimeout);
    } on TimeoutException {
      // The in-flight read can still update the entitlement when it resolves.
    } finally {
      if (!_disposed && !_finishedInitialCheck) {
        _finishedInitialCheck = true;
        notifyListeners();
      }
    }
  }

  Future<void> _readEntitlement() async {
    final revision = _entitlementRevision;
    try {
      final active = await _store.currentEntitlement();
      if (_disposed) return;
      if (_entitlementRevision == revision) _applyEntitlement(active);
      _observeEntitlement();
    } on MissingPluginException {
      _markUnsupported();
    } on PlatformException catch (error) {
      if (error.code == unavailableErrorCode) {
        _markUnsupported();
      } else {
        debugPrint('Could not read the store entitlement.');
      }
    } catch (_) {
      debugPrint('Could not read the store entitlement.');
    }
  }

  Future<void> loadProduct() {
    if (_disposed || !isSupported) return Future<void>.value();
    return _loadingPrice ??= _loadProduct().whenComplete(
      () => _loadingPrice = null,
    );
  }

  Future<void> _loadProduct() async {
    try {
      final price = await _store.loadPrice().timeout(_lookupTimeout);
      if (_disposed || _price == price) return;
      _price = price;
      notifyListeners();
    } on MissingPluginException {
      _markUnsupported();
    } on PlatformException catch (error) {
      if (error.code == unavailableErrorCode) _markUnsupported();
      debugPrint('Could not load the store product.');
    } catch (_) {
      debugPrint('Could not load the store product.');
    }
  }

  Future<PremiumOutcome> purchase() => _runStoreOperation(_store.purchase);

  Future<PremiumOutcome> restore() => _runStoreOperation(_store.restore);

  Future<PremiumOutcome> _runStoreOperation(
    Future<PremiumOutcome> Function() operation,
  ) async {
    if (_disposed || !isSupported) return PremiumOutcome.unavailable;
    if (isBusy || isChecking) return PremiumOutcome.busy;
    _busy = true;
    notifyListeners();
    final revision = _entitlementRevision;
    try {
      final outcome = await operation();
      if (_entitlementRevision == revision) {
        if (outcome == PremiumOutcome.purchased ||
            outcome == PremiumOutcome.restored) {
          _applyEntitlement(true);
        } else if (outcome == PremiumOutcome.notPurchased) {
          _applyEntitlement(false);
        }
      }
      _observeEntitlement();
      return outcome;
    } on MissingPluginException {
      _markUnsupported();
      return PremiumOutcome.unavailable;
    } catch (_) {
      return PremiumOutcome.failed;
    } finally {
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _observeEntitlement() {
    if (_disposed) return;
    // The native bridge replays changes made before Dart started listening.
    _updates ??= _store.entitlementUpdates.listen(
      _applyEntitlement,
      onError: (Object _) =>
          debugPrint('Premium entitlement stream unavailable.'),
    );
  }

  void _applyEntitlement(bool active) {
    if (_disposed) return;
    _entitlementRevision++;
    if (_entitlement == active && _finishedInitialCheck) return;
    _entitlement = active;
    _finishedInitialCheck = true;
    notifyListeners();
  }

  void _markUnsupported() {
    if (_disposed || !isSupported) return;
    _supported = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_updates?.cancel());
    super.dispose();
  }
}

/// Talks to apple/PremiumStoreBridge.swift (StoreKit) or
/// android/.../PremiumStoreBridge.kt (Google Play Billing).
class _NativeStore implements PremiumStore {
  const _NativeStore();

  static const _methods = MethodChannel('simple_calculator/premium');
  static const _entitlements = EventChannel(
    'simple_calculator/premium_entitlement',
  );

  @override
  Stream<bool> get entitlementUpdates => _entitlements
      .receiveBroadcastStream()
      .where((event) => event is bool)
      .cast<bool>();

  @override
  Future<bool> currentEntitlement() async {
    final active = await _methods.invokeMethod<bool>('currentEntitlement');
    if (active == null) {
      throw const FormatException('Missing store entitlement');
    }
    return active;
  }

  @override
  Future<String?> loadPrice() => _methods.invokeMethod<String>('price');

  @override
  Future<PremiumOutcome> purchase() => _outcome('purchase');

  @override
  Future<PremiumOutcome> restore() => _outcome('restore');

  Future<PremiumOutcome> _outcome(String method) async {
    final status = await _methods.invokeMethod<String>(method);
    return PremiumOutcome.values.byName(status ?? PremiumOutcome.failed.name);
  }
}
