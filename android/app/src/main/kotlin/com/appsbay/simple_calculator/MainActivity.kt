package com.appsbay.simple_calculator

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var premiumStore: PremiumStoreBridge? = null
    private var quickActionsChannel: MethodChannel? = null
    private var pendingShortcut: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        premiumStore?.dispose()
        premiumStore = PremiumStoreBridge(this, messenger)

        pendingShortcut = intent?.getStringExtra("shortcut_action")
        val channel = MethodChannel(messenger, "com.appsbay.simple_calculator/quick_actions")
        channel.setMethodCallHandler { call, result ->
            if (call.method == "getInitialShortcut") {
                val action = pendingShortcut
                pendingShortcut = null
                result.success(action)
            } else {
                result.notImplemented()
            }
        }
        quickActionsChannel = channel
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val action = intent.getStringExtra("shortcut_action")
        if (!action.isNullOrEmpty()) {
            quickActionsChannel?.invokeMethod("onShortcut", action)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        quickActionsChannel?.setMethodCallHandler(null)
        quickActionsChannel = null
        premiumStore?.dispose()
        premiumStore = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
