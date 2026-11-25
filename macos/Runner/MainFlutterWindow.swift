import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var premiumStore: PremiumStoreBridge?
  private var windowChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    // AppKit loads the main window nib on the main thread.
    MainActor.assumeIsolated {
      let flutterViewController = FlutterViewController()
      let windowFrame = frame
      contentViewController = flutterViewController
      setFrame(windowFrame, display: true)

      RegisterGeneratedPlugins(registry: flutterViewController)
      let messenger = flutterViewController.engine.binaryMessenger
      premiumStore = PremiumStoreBridge(messenger: messenger)

      let channel = FlutterMethodChannel(
        name: "com.appsbay.simple_calculator/window",
        binaryMessenger: messenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(false)
          return
        }
        switch call.method {
        case "setAlwaysOnTop":
          let enabled = (call.arguments as? Bool) ?? false
          self.level = enabled ? .floating : .normal
          result(enabled)
        case "isAlwaysOnTop":
          result(self.level == .floating)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
      windowChannel = channel
    }

    super.awakeFromNib()
  }
}
