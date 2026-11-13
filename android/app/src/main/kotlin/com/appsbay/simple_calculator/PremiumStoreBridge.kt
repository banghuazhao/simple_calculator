package com.appsbay.simple_calculator

import android.app.Activity
import android.os.Handler
import android.os.Looper
import com.android.billingclient.api.AcknowledgePurchaseParams
import com.android.billingclient.api.BillingClient
import com.android.billingclient.api.BillingClient.BillingResponseCode
import com.android.billingclient.api.BillingClient.ProductType
import com.android.billingclient.api.BillingClientStateListener
import com.android.billingclient.api.BillingFlowParams
import com.android.billingclient.api.BillingResult
import com.android.billingclient.api.PendingPurchasesParams
import com.android.billingclient.api.ProductDetails
import com.android.billingclient.api.Purchase
import com.android.billingclient.api.PurchasesUpdatedListener
import com.android.billingclient.api.QueryProductDetailsParams
import com.android.billingclient.api.QueryPurchasesParams
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Google Play Billing counterpart of apple/PremiumStoreBridge.swift.
 * Speaks the same channel protocol, so PremiumController is store-agnostic.
 */
class PremiumStoreBridge(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, PurchasesUpdatedListener {

    companion object {
        const val PRODUCT_ID = "premium"
        private const val UNAVAILABLE_CODE = "billing_unavailable"
    }

    private val main = Handler(Looper.getMainLooper())
    private val methods = MethodChannel(messenger, "simple_calculator/premium")
    private val events = EventChannel(messenger, "simple_calculator/premium_entitlement")
    private val client: BillingClient = BillingClient.newBuilder(activity)
        .setListener(this)
        .enablePendingPurchases(
            PendingPurchasesParams.newBuilder().enableOneTimeProducts().build()
        )
        .enableAutoServiceReconnection()
        .build()

    private var eventSink: EventChannel.EventSink? = null
    private var entitlement: Boolean? = null
    private var revision = 0
    private var publishedRevision = 0
    private var operationInFlight = false
    private var pendingPurchase: ((String) -> Unit)? = null
    private var connecting = false
    private val connectionWaiters = mutableListOf<(BillingResult) -> Unit>()
    private var disposed = false

    init {
        methods.setMethodCallHandler(this)
        events.setStreamHandler(this)
    }

    fun dispose() {
        disposed = true
        methods.setMethodCallHandler(null)
        events.setStreamHandler(null)
        pendingPurchase?.invoke("failed")
        pendingPurchase = null
        client.endConnection()
    }

    // region Flutter channels

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
        entitlement?.let { events.success(it) }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "currentEntitlement" -> withConnection(
                onReady = { refreshEntitlement { result.success(it) } },
                onError = { result.unavailable(it) },
            )

            "price" -> withConnection(
                onReady = {
                    loadProduct { details, error ->
                        if (error != null) {
                            result.error("store_unavailable", error.debugMessage, null)
                        } else {
                            result.success(details?.oneTimePurchaseOfferDetails?.formattedPrice)
                        }
                    }
                },
                onError = { result.unavailable(it) },
            )

            "purchase" -> performOperation(result) { finish -> purchase(finish) }
            "restore" -> performOperation(result) { finish ->
                refreshEntitlement { active -> finish(if (active) "restored" else "notPurchased") }
            }

            else -> result.notImplemented()
        }
    }

    private fun MethodChannel.Result.unavailable(billing: BillingResult) {
        if (isUnsupported(billing)) {
            error(UNAVAILABLE_CODE, billing.debugMessage, null)
        } else {
            error("store_unavailable", billing.debugMessage, null)
        }
    }

    // endregion

    // region Billing operations

    private fun performOperation(
        result: MethodChannel.Result,
        operation: (finish: (String) -> Unit) -> Unit,
    ) {
        if (operationInFlight) {
            result.success("busy")
            return
        }
        operationInFlight = true
        var finished = false
        val finish: (String) -> Unit = { outcome ->
            if (!finished) {
                finished = true
                operationInFlight = false
                result.success(outcome)
            }
        }
        withConnection(
            onReady = { operation(finish) },
            onError = { finish(if (isUnsupported(it)) "unavailable" else "failed") },
        )
    }

    private fun purchase(finish: (String) -> Unit) {
        loadProduct { details, error ->
            if (error != null || details == null) {
                finish(if (error == null || isUnsupported(error)) "unavailable" else "failed")
                return@loadProduct
            }
            val params = BillingFlowParams.newBuilder()
                .setProductDetailsParamsList(
                    listOf(
                        BillingFlowParams.ProductDetailsParams.newBuilder()
                            .setProductDetails(details)
                            .build()
                    )
                )
                .build()
            pendingPurchase = finish
            val launch = client.launchBillingFlow(activity, params)
            if (launch.responseCode != BillingResponseCode.OK) {
                pendingPurchase = null
                finish(outcomeFor(launch))
            }
        }
    }

    override fun onPurchasesUpdated(billing: BillingResult, purchases: MutableList<Purchase>?) {
        onMain {
            val finish = pendingPurchase
            pendingPurchase = null
            when (billing.responseCode) {
                BillingResponseCode.OK -> {
                    val premium = purchases.orEmpty().filter(::isPremium)
                    premium.forEach(::acknowledgeIfNeeded)
                    when {
                        premium.any { it.purchaseState == Purchase.PurchaseState.PURCHASED } -> {
                            publish(true, nextRevision())
                            finish?.invoke("purchased")
                        }

                        premium.any { it.purchaseState == Purchase.PurchaseState.PENDING } ->
                            finish?.invoke("pending")

                        else -> finish?.invoke("failed")
                    }
                }

                BillingResponseCode.ITEM_ALREADY_OWNED -> refreshEntitlement { active ->
                    finish?.invoke(if (active) "restored" else "failed")
                }

                else -> finish?.invoke(outcomeFor(billing))
            }
        }
    }

    private fun loadProduct(callback: (ProductDetails?, BillingResult?) -> Unit) {
        val params = QueryProductDetailsParams.newBuilder()
            .setProductList(
                listOf(
                    QueryProductDetailsParams.Product.newBuilder()
                        .setProductId(PRODUCT_ID)
                        .setProductType(ProductType.INAPP)
                        .build()
                )
            )
            .build()
        client.queryProductDetailsAsync(params) { billing, queried ->
            onMain {
                if (billing.responseCode != BillingResponseCode.OK) {
                    callback(null, billing)
                } else {
                    callback(
                        queried.productDetailsList.firstOrNull { it.productId == PRODUCT_ID },
                        null,
                    )
                }
            }
        }
    }

    private fun refreshEntitlement(callback: (Boolean) -> Unit) {
        val readRevision = nextRevision()
        val params = QueryPurchasesParams.newBuilder().setProductType(ProductType.INAPP).build()
        client.queryPurchasesAsync(params) { billing, purchases ->
            onMain {
                if (billing.responseCode != BillingResponseCode.OK) {
                    // Keep the last known answer rather than revoking on a transient error.
                    callback(entitlement ?: false)
                    return@onMain
                }
                val premium = purchases.filter(::isPremium)
                premium.forEach(::acknowledgeIfNeeded)
                val active = premium.any { it.purchaseState == Purchase.PurchaseState.PURCHASED }
                callback(publish(active, readRevision))
            }
        }
    }

    private fun acknowledgeIfNeeded(purchase: Purchase) {
        // Unacknowledged purchases are refunded by Google Play after three days.
        if (purchase.purchaseState != Purchase.PurchaseState.PURCHASED || purchase.isAcknowledged) {
            return
        }
        val params = AcknowledgePurchaseParams.newBuilder()
            .setPurchaseToken(purchase.purchaseToken)
            .build()
        client.acknowledgePurchase(params) { }
    }

    // endregion

    // region Connection and helpers

    private fun withConnection(onReady: () -> Unit, onError: (BillingResult) -> Unit) {
        if (client.isReady) {
            onReady()
            return
        }
        connectionWaiters += { billing ->
            if (billing.responseCode == BillingResponseCode.OK) onReady() else onError(billing)
        }
        if (connecting) return
        connecting = true
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(billing: BillingResult) {
                onMain {
                    connecting = false
                    val waiters = connectionWaiters.toList()
                    connectionWaiters.clear()
                    waiters.forEach { it(billing) }
                }
            }

            override fun onBillingServiceDisconnected() {
                // enableAutoServiceReconnection() re-establishes the connection on the next call.
            }
        })
    }

    private fun isPremium(purchase: Purchase) = purchase.products.contains(PRODUCT_ID)

    private fun isUnsupported(billing: BillingResult) = when (billing.responseCode) {
        BillingResponseCode.BILLING_UNAVAILABLE,
        BillingResponseCode.FEATURE_NOT_SUPPORTED -> true

        else -> false
    }

    private fun outcomeFor(billing: BillingResult) = when (billing.responseCode) {
        BillingResponseCode.USER_CANCELED -> "cancelled"
        BillingResponseCode.BILLING_UNAVAILABLE,
        BillingResponseCode.FEATURE_NOT_SUPPORTED,
        BillingResponseCode.ITEM_UNAVAILABLE -> "unavailable"

        else -> "failed"
    }

    private fun nextRevision(): Int {
        revision += 1
        return revision
    }

    private fun publish(active: Boolean, revision: Int): Boolean {
        // A purchase update or newer read may land while an older read is in flight.
        if (revision < publishedRevision) return entitlement ?: active
        publishedRevision = revision
        if (entitlement != active) {
            entitlement = active
            eventSink?.success(active)
        }
        return active
    }

    private fun onMain(block: () -> Unit) {
        val guarded = { if (!disposed) block() }
        if (Looper.myLooper() == Looper.getMainLooper()) guarded() else main.post(guarded)
    }

    // endregion
}
