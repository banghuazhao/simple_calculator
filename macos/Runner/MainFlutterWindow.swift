import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var premiumStore: PremiumStoreBridge?

  override func awakeFromNib() {
    // AppKit loads the main window nib on the main thread.
    MainActor.assumeIsolated {
      let flutterViewController = FlutterViewController()
      let windowFrame = frame
      contentViewController = flutterViewController
      setFrame(windowFrame, display: true)

      RegisterGeneratedPlugins(registry: flutterViewController)
      premiumStore = PremiumStoreBridge(messenger: flutterViewController.engine.binaryMessenger)
    }

    super.awakeFromNib()
  }
}
