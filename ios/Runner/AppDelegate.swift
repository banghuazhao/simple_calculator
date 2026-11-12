@preconcurrency import Flutter
import StoreKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, @preconcurrency FlutterImplicitEngineDelegate {
  private var premiumStore: PremiumStoreBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    premiumStore = PremiumStoreBridge(messenger: engineBridge.applicationRegistrar.messenger())
  }
}

@MainActor
private final class PremiumStoreBridge: NSObject, @preconcurrency FlutterStreamHandler {
  private static let productID = "com.appsbay.simpleCalculator.premium"

  private var updatesTask: Task<Void, Never>?
  private var eventSink: FlutterEventSink?
  private var entitlement: Bool?
  private var revision = 0
  private var publishedRevision = 0
  private var storeOperationInFlight = false

  init(messenger: FlutterBinaryMessenger) {
    super.init()

    let methods = FlutterMethodChannel(
      name: "simple_calculator/premium", binaryMessenger: messenger)
    methods.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.handle(call, result: result)
    }
    FlutterEventChannel(
      name: "simple_calculator/premium_entitlement", binaryMessenger: messenger
    ).setStreamHandler(self)

    updatesTask = Task { [weak self] in
      for await verification in Transaction.updates {
        guard let self, !Task.isCancelled else { return }
        guard case .verified(let transaction) = verification,
          self.isPremiumProduct(transaction)
        else { continue }
        _ = await self.refreshEntitlement(
          excluding: transaction.revocationDate == nil ? nil : transaction.id)
        await transaction.finish()
      }
    }
  }

  deinit {
    updatesTask?.cancel()
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    if let entitlement { events(entitlement) }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "currentEntitlement":
      Task { result(await refreshEntitlement()) }
    case "price":
      Task {
        do {
          result(try await product()?.displayPrice)
        } catch {
          result(FlutterError(code: "store_unavailable", message: nil, details: nil))
        }
      }
    case "purchase":
      Task { result(await performStoreOperation { try await purchase() }) }
    case "restore":
      Task {
        result(await performStoreOperation {
          try await AppStore.sync()
          return await refreshEntitlement() ? "restored" : "notPurchased"
        })
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func product() async throws -> Product? {
    guard AppStore.canMakePayments else { return nil }
    return try await Product.products(for: [Self.productID]).first {
      $0.id == Self.productID && $0.type == .nonConsumable
    }
  }

  private func purchase() async throws -> String {
    guard let product = try await product() else { return "unavailable" }
    switch try await product.purchase() {
    case .success(let verification):
      guard case .verified(let transaction) = verification,
        isPremiumProduct(transaction), transaction.revocationDate == nil
      else { return "failed" }
      _ = publishEntitlement(true, revision: nextRevision())
      await transaction.finish()
      return "purchased"
    case .pending:
      return "pending"
    case .userCancelled:
      return "cancelled"
    @unknown default:
      return "failed"
    }
  }

  private func performStoreOperation(_ operation: @MainActor () async throws -> String)
    async -> String
  {
    guard !storeOperationInFlight else { return "busy" }
    storeOperationInFlight = true
    defer { storeOperationInFlight = false }
    do {
      return try await operation()
    } catch StoreKitError.userCancelled {
      return "cancelled"
    } catch StoreKitError.notAvailableInStorefront {
      return "unavailable"
    } catch {
      return "failed"
    }
  }

  private func isPremiumProduct(_ transaction: Transaction) -> Bool {
    transaction.productID == Self.productID && transaction.productType == .nonConsumable
  }

  private func refreshEntitlement(excluding revokedTransactionID: UInt64? = nil) async -> Bool {
    let readRevision = nextRevision()
    for await verification in Transaction.currentEntitlements {
      if case .verified(let transaction) = verification,
        isPremiumProduct(transaction), transaction.revocationDate == nil,
        transaction.id != revokedTransactionID
      {
        return publishEntitlement(true, revision: readRevision)
      }
    }
    return publishEntitlement(false, revision: readRevision)
  }

  private func nextRevision() -> Int {
    revision += 1
    return revision
  }

  private func publishEntitlement(_ active: Bool, revision: Int) -> Bool {
    // A transaction or newer StoreKit read may finish while a read is suspended.
    if revision < publishedRevision { return entitlement ?? active }
    publishedRevision = revision
    if entitlement != active {
      entitlement = active
      eventSink?(active)
    }
    return active
  }
}
