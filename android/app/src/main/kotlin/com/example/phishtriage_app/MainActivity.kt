package com.example.phishtriage_app

import android.Manifest
import android.app.role.RoleManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges Android features to Flutter over the "phishtriage/native" channel:
 *  - text shared to PhishTriage (Share menu) or selected text ("Check with PhishTriage")
 *  - taps on call-warning notifications
 *  - call protection (call screening role, offline list, block setting, recent callers)
 */
class MainActivity : FlutterActivity() {
    companion object {
        const val CHANNEL = "phishtriage/native"
        const val EXTRA_OPEN = "phishtriage_open"
        const val EXTRA_NUMBER = "phishtriage_number"
        private const val REQ_ROLE = 4101
        private const val REQ_NOTIFY = 4102
    }

    private var channel: MethodChannel? = null
    private var pendingShare: String? = null
    private var pendingOpen: Map<String, String>? = null
    private var roleResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        readIntent(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getSharedText" -> { result.success(pendingShare); pendingShare = null }
                        "getPendingOpen" -> { result.success(pendingOpen); pendingOpen = null }
                        "getCallProtectionStatus" -> result.success(status())
                        "requestCallScreeningRole" -> requestRole(result)
                        "requestNotificationPermission" -> {
                            if (Build.VERSION.SDK_INT >= 33 && !notificationsAllowed()) {
                                requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQ_NOTIFY)
                            }
                            result.success(null)
                        }
                        "setBlockHighRisk" -> {
                            CallStore.setBlockHighRisk(this@MainActivity, call.arguments as Boolean)
                            result.success(null)
                        }
                        "updateBlocklist" -> {
                            CallStore.saveList(this@MainActivity, call.arguments as String)
                            result.success(CallStore.listCount(this@MainActivity))
                        }
                        "getRecentCalls" -> result.success(CallStore.recent(this@MainActivity))
                        "clearRecentCalls" -> { CallStore.clearRecent(this@MainActivity); result.success(null) }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("native_error", e.message, null)
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        readIntent(intent)
        pendingShare?.let { channel?.invokeMethod("sharedText", it); pendingShare = null }
        pendingOpen?.let { channel?.invokeMethod("open", it); pendingOpen = null }
    }

    private fun readIntent(intent: Intent?) {
        if (intent == null) return
        when (intent.action) {
            Intent.ACTION_SEND -> if (intent.type?.startsWith("text/") == true) {
                val text = listOfNotNull(
                    intent.getStringExtra(Intent.EXTRA_SUBJECT),
                    intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
                ).joinToString("\n").trim()
                if (text.isNotEmpty()) pendingShare = text
            }
            Intent.ACTION_PROCESS_TEXT -> {
                val text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()?.trim()
                if (!text.isNullOrEmpty()) pendingShare = text
            }
        }
        val open = intent.getStringExtra(EXTRA_OPEN)
        val number = intent.getStringExtra(EXTRA_NUMBER)
        if (open != null && number != null) {
            pendingOpen = mapOf("action" to open, "number" to number)
            intent.removeExtra(EXTRA_OPEN)
        }
    }

    private fun notificationsAllowed(): Boolean =
        Build.VERSION.SDK_INT < 33 ||
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED

    private fun roleHeld(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val rm = getSystemService(RoleManager::class.java) ?: return false
        return rm.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) && rm.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
    }

    private fun status(): Map<String, Any?> = mapOf(
        "supported" to (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q),
        "roleHeld" to roleHeld(),
        "notificationsAllowed" to notificationsAllowed(),
        "blockHighRisk" to CallStore.blockHighRisk(this),
        "listCount" to CallStore.listCount(this),
        "listUpdatedAt" to CallStore.listUpdatedAt(this),
    )

    private fun requestRole(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.success(false); return
        }
        if (roleHeld()) {
            result.success(true); return
        }
        val rm = getSystemService(RoleManager::class.java)
        if (rm == null || !rm.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
            result.success(false); return
        }
        roleResult = result
        @Suppress("DEPRECATION")
        startActivityForResult(rm.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING), REQ_ROLE)
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQ_ROLE) {
            roleResult?.success(roleHeld())
            roleResult = null
        }
    }
}
