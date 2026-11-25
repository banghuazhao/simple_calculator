@preconcurrency import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, @preconcurrency FlutterImplicitEngineDelegate {
  private var premiumStore: PremiumStoreBridge?
  private var quickActionsChannel: FlutterMethodChannel?
  private var pendingShortcut: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
      pendingShortcut = shortcutItem.type
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    if let channel = quickActionsChannel {
      channel.invokeMethod("onShortcut", arguments: shortcutItem.type)
    } else {
      pendingShortcut = shortcutItem.type
    }
    completionHandler(true)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    premiumStore = PremiumStoreBridge(messenger: messenger)

    let channel = FlutterMethodChannel(
      name: "com.appsbay.simple_calculator/quick_actions",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "getInitialShortcut" {
        let initial = self?.pendingShortcut
        self?.pendingShortcut = nil
        result(initial)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    quickActionsChannel = channel
  }
}
