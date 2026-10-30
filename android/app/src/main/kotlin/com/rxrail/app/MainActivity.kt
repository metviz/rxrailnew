package com.rxrail.app

import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Adds an OEM-survival MethodChannel on top of the default Flutter activity.
 *
 * Battery-optimization exemption (Doze) is handled in Dart via
 * flutter_foreground_task. THIS layer handles the OEM-specific "app sleep"
 * managers (Samsung "deep sleeping apps", Xiaomi autostart, Huawei protected
 * apps, etc.) that battery-opt exemption does NOT cover and which are the real
 * reason a foreground service gets frozen on those phones.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "com.rxrail.app/oem_survival"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getManufacturer" ->
                        result.success(Build.MANUFACTURER.lowercase())
                    "openAutoStartSettings" ->
                        result.success(openAutoStartSettings())
                    "openAppDetailsSettings" ->
                        result.success(openAppDetailsSettings())
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Tries OEM "auto-start / protected app / never-sleeping" screens in order.
     * Each is wrapped because these activities are frequently non-exported and
     * throw at launch. Falls back to the app's own details page so the user is
     * never left staring at a dead button. Returns true if anything launched.
     */
    private fun openAutoStartSettings(): Boolean {
        // Samsung's app-power / never-sleeping screens are gated behind a
        // privileged permission (READ_SEARCH_INDEXABLES) no 3rd-party app can
        // hold, so attempting them always fails. Go straight to the App info
        // page, whose Battery → "Allow background activity" toggle is reachable.
        if (Build.MANUFACTURER.equals("samsung", ignoreCase = true)) {
            return openAppDetailsSettings()
        }
        for (intent in oemAutoStartIntents()) {
            if (tryStart(intent)) return true
        }
        return openAppDetailsSettings()
    }

    private fun openAppDetailsSettings(): Boolean {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return tryStart(intent)
    }

    private fun tryStart(intent: Intent): Boolean {
        return try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }

    /** Known OEM auto-start activities (sourced from the dontkillmyapp list). */
    private fun oemAutoStartIntents(): List<Intent> {
        val components = listOf(
            // Samsung — Device Care
            "com.samsung.android.lool" to
                "com.samsung.android.sm.ui.battery.BatteryActivity",
            "com.samsung.android.sm" to
                "com.samsung.android.sm.ui.battery.BatteryActivity",
            // Xiaomi / MIUI
            "com.miui.securitycenter" to
                "com.miui.permcenter.autostart.AutoStartManagementActivity",
            // Huawei
            "com.huawei.systemmanager" to
                "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            "com.huawei.systemmanager" to
                "com.huawei.systemmanager.optimize.process.ProtectActivity",
            // Oppo / ColorOS
            "com.coloros.safecenter" to
                "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            "com.oppo.safe" to
                "com.oppo.safe.permission.startup.StartupAppListActivity",
            // Vivo
            "com.vivo.permissionmanager" to
                "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
            "com.iqoo.secure" to
                "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
            // OnePlus
            "com.oneplus.security" to
                "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
            // Letv
            "com.letv.android.letvsafe" to
                "com.letv.android.letvsafe.AutobootManageActivity",
            // Asus
            "com.asus.mobilemanager" to
                "com.asus.mobilemanager.entry.FunctionActivity",
        )
        return components.map { (pkg, cls) ->
            Intent().apply { component = ComponentName(pkg, cls) }
        }
    }
}
