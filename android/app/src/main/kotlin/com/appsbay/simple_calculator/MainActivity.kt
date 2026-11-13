package com.appsbay.simple_calculator

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var premiumStore: PremiumStoreBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        premiumStore?.dispose()
        premiumStore = PremiumStoreBridge(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        premiumStore?.dispose()
        premiumStore = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
