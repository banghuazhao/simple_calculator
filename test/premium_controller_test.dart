import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simple_calculator/premium/premium_controller.dart';

class _FakeStore implements PremiumStore {
  final updates = StreamController<bool>.broadcast();
  Future<bool> Function() entitlement = () async => false;
  Future<PremiumOutcome> Function() buy = () async => PremiumOutcome.purchased;
  Future<PremiumOutcome> Function() sync = () async => PremiumOutcome.restored;
  int lookupCount = 0;
  int purchaseCount = 0;
  int restoreCount = 0;

  @override
  Stream<bool> get entitlementUpdates => updates.stream;

  @override
  Future<bool> currentEntitlement() {
    lookupCount++;
    return entitlement();
  }

  @override
  Future<String?> loadPrice() async => 'NZ\$9.99';

  @override
  Future<PremiumOutcome> purchase() {
    purchaseCount++;
    return buy();
  }

  @override
  Future<PremiumOutcome> restore() {
    restoreCount++;
    return sync();
  }
}

void main() {
  late _FakeStore store;
  late PremiumController controller;

  setUp(() {
    store = _FakeStore();
    controller = PremiumController(store: store, supported: true);
  });

  tearDown(() async {
    controller.dispose();
    await store.updates.close();
  });

  Future<void> flushUpdates() => Future<void>.delayed(Duration.zero);

  test(
    'startup with a verified purchase suppresses ads until revocation',
    () async {
      final entitlement = Completer<bool>();
      store.entitlement = () => entitlement.future;
      expect(controller.isChecking, isTrue);
      expect(controller.allowsAds, isFalse);

      final initialization = controller.initialize();
      expect(identical(initialization, controller.initialize()), isTrue);
      entitlement.complete(true);
      await initialization;
      await controller.loadProduct();
      expect(controller.isChecking, isFalse);
      expect(controller.isPremium, isTrue);
      expect(controller.allowsAds, isFalse);
      expect(controller.price, 'NZ\$9.99');
      expect(store.lookupCount, 1);

      store.updates.add(false);
      await flushUpdates();
      expect(controller.isPremium, isFalse);
      expect(controller.allowsAds, isTrue);
    },
  );

  test(
    'pending and cancelled purchases wait for a verified entitlement',
    () async {
      await controller.initialize();
      expect(controller.allowsAds, isTrue);
      store.buy = () async => PremiumOutcome.cancelled;
      expect(await controller.purchase(), PremiumOutcome.cancelled);
      store.buy = () async => PremiumOutcome.pending;
      expect(await controller.purchase(), PremiumOutcome.pending);
      expect(controller.isPremium, isFalse);

      store.updates.add(true);
      await flushUpdates();
      expect(controller.isPremium, isTrue);
      expect(controller.allowsAds, isFalse);
    },
  );

  test(
    'purchase and restore are serialized and restore can revoke access',
    () async {
      await controller.initialize();
      final transaction = Completer<PremiumOutcome>();
      store.buy = () => transaction.future;
      final purchase = controller.purchase();
      expect(controller.isBusy, isTrue);
      expect(await controller.purchase(), PremiumOutcome.busy);
      expect(await controller.restore(), PremiumOutcome.busy);
      expect(store.purchaseCount, 1);
      expect(store.restoreCount, 0);

      transaction.complete(PremiumOutcome.purchased);
      expect(await purchase, PremiumOutcome.purchased);
      expect(controller.isPremium, isTrue);
      expect(controller.isBusy, isFalse);

      store.sync = () async => PremiumOutcome.notPurchased;
      expect(await controller.restore(), PremiumOutcome.notPurchased);
      expect(controller.allowsAds, isTrue);

      store.sync = () async => PremiumOutcome.restored;
      expect(await controller.restore(), PremiumOutcome.restored);
      expect(controller.isPremium, isTrue);
      expect(controller.allowsAds, isFalse);
    },
  );

  test(
    'a newer StoreKit update wins over an earlier entitlement read',
    () async {
      await controller.initialize();
      final priorRead = Completer<bool>();
      store.entitlement = () => priorRead.future;
      final reading = controller.refreshEntitlement();
      store.updates.add(true);
      await flushUpdates();
      priorRead.complete(false);
      await reading;
      expect(controller.isPremium, isTrue);
    },
  );

  test(
    'a timed out startup check allows use while awaiting ad eligibility',
    () async {
      final entitlement = Completer<bool>();
      store.entitlement = () => entitlement.future;
      final slowController = PremiumController(
        store: store,
        supported: true,
        lookupTimeout: Duration.zero,
      );
      addTearDown(slowController.dispose);

      await slowController.initialize();
      expect(slowController.isChecking, isFalse);
      expect(slowController.allowsAds, isFalse);
      entitlement.complete(false);
      await flushUpdates();
      expect(slowController.allowsAds, isTrue);
    },
  );

  test('missing native bridge leaves the basic calculator usable', () async {
    store.entitlement = () async => throw MissingPluginException();
    await controller.initialize();
    expect(controller.isSupported, isFalse);
    expect(controller.isChecking, isFalse);
    expect(controller.allowsAds, isTrue);
    expect(await controller.purchase(), PremiumOutcome.unavailable);
    expect(store.updates.hasListener, isFalse);
    expect(store.purchaseCount, 0);
  });

  test(
    'device without Google Play billing hides Premium and keeps ads',
    () async {
      store.entitlement = () async =>
          throw PlatformException(code: PremiumController.unavailableErrorCode);
      await controller.initialize();
      expect(controller.isSupported, isFalse);
      expect(controller.isChecking, isFalse);
      expect(controller.allowsAds, isTrue);
      expect(await controller.purchase(), PremiumOutcome.unavailable);
      expect(store.purchaseCount, 0);
    },
  );

  test('transient store errors keep waiting for a definitive answer', () async {
    store.entitlement = () async =>
        throw PlatformException(code: 'store_unavailable');
    await controller.initialize();
    expect(controller.isSupported, isTrue);
    expect(controller.isChecking, isFalse);
    expect(controller.allowsAds, isFalse);
  });
}
