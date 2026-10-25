// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.okapi.permissions

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat
import androidx.core.content.IntentCompat
import androidx.core.content.PackageManagerCompat
import androidx.core.content.UnusedAppRestrictionsConstants
import io.flutter.plugin.common.MethodChannel

/**
 * On-device store, device info, phone-maker (OEM) screens and Android's
 * "Pause app activity if unused" (auto-reset) support.
 *
 * OEM screens are tried in order and only opened when the system confirms
 * the activity exists and is exported, so a wrong guess never crashes.
 */
internal class OkapiExtras(
    private val context: () -> Context?,
    private val activity: () -> Activity?,
) {
    companion object {
        private const val STORE = "dev.okapi.store"
        const val REQ_AUTO_RESET = 0x0CA3

        /** Autostart / auto-launch screens, most common first. */
        private val AUTOSTART = listOf(
            // Xiaomi, Redmi, POCO (MIUI / HyperOS)
            "com.miui.securitycenter" to "com.miui.permcenter.autostart.AutoStartManagementActivity",
            // OPPO, realme, newer OnePlus (ColorOS)
            "com.coloros.safecenter" to "com.coloros.safecenter.permission.startup.StartupAppListActivity",
            "com.coloros.safecenter" to "com.coloros.safecenter.startupapp.StartupAppListActivity",
            "com.oppo.safe" to "com.oppo.safe.permission.startup.StartupAppListActivity",
            // OnePlus (OxygenOS)
            "com.oneplus.security" to "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity",
            // vivo, iQOO
            "com.vivo.permissionmanager" to "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
            "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager",
            "com.iqoo.secure" to "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity",
            // Huawei, Honor
            "com.huawei.systemmanager" to "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            "com.huawei.systemmanager" to "com.huawei.systemmanager.optimize.process.ProtectActivity",
            "com.huawei.systemmanager" to "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity",
            "com.hihonor.systemmanager" to "com.hihonor.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
            // ASUS
            "com.asus.mobilemanager" to "com.asus.mobilemanager.autostart.AutoStartActivity",
            "com.asus.mobilemanager" to "com.asus.mobilemanager.entry.FunctionActivity",
            // TECNO, Infinix, itel (Transsion)
            "com.transsion.phonemaster" to "com.cyin.himgr.autostart.AutoStartActivity",
        )

        /** Battery-saver exception screens. */
        private val BATTERY = listOf(
            // Samsung
            "com.samsung.android.lool" to "com.samsung.android.sm.battery.ui.BatteryActivity",
            "com.samsung.android.lool" to "com.samsung.android.sm.ui.battery.BatteryActivity",
            "com.samsung.android.sm" to "com.samsung.android.sm.ui.battery.BatteryActivity",
            // Huawei
            "com.huawei.systemmanager" to "com.huawei.systemmanager.power.ui.HwPowerManagerActivity",
            // Nokia
            "com.evenwell.powersaving.g3" to "com.evenwell.powersaving.g3.exception.PowerSaverExceptionActivity",
        )
    }

    // ── Store ────────────────────────────────────────────────────────────

    fun loadStore(): Map<String, String> {
        val ctx = context() ?: return emptyMap()
        return ctx.getSharedPreferences(STORE, Context.MODE_PRIVATE).all
            .mapNotNull { (k, v) -> (v as? String)?.let { k to it } }
            .toMap()
    }

    fun writeStore(key: String, value: String?) {
        val ctx = context() ?: return
        val editor = ctx.getSharedPreferences(STORE, Context.MODE_PRIVATE).edit()
        if (value == null) editor.remove(key) else editor.putString(key, value)
        editor.apply()
    }

    // ── Device ───────────────────────────────────────────────────────────

    fun deviceInfo(): Map<String, Any> {
        val ctx = context()
        val label = try {
            ctx?.applicationInfo?.loadLabel(ctx.packageManager)?.toString() ?: ""
        } catch (e: Exception) {
            ""
        }
        return mapOf(
            "platform" to "android",
            "manufacturer" to (Build.MANUFACTURER ?: ""),
            "brand" to (Build.BRAND ?: ""),
            "model" to (Build.MODEL ?: ""),
            "osVersion" to (Build.VERSION.RELEASE ?: ""),
            "sdkInt" to Build.VERSION.SDK_INT,
            "appName" to label,
        )
    }

    // ── OEM screens ──────────────────────────────────────────────────────

    private fun explicit(pkg: String, cls: String) =
        Intent().setComponent(ComponentName(pkg, cls))

    private fun autostartIntents(): List<Intent> =
        AUTOSTART.map { (p, c) -> explicit(p, c) }

    private fun batteryIntents(): List<Intent> {
        val ctx = context() ?: return emptyList()
        val list = mutableListOf<Intent>()
        // Xiaomi: per-app battery saver ("No restrictions").
        list += explicit(
            "com.miui.powerkeeper",
            "com.miui.powerkeeper.ui.HiddenAppsConfigActivity",
        ).putExtra("package_name", ctx.packageName)
            .putExtra("package_label", deviceInfo()["appName"] as? String ?: "")
        list += BATTERY.map { (p, c) -> explicit(p, c) }
        // Android's own list (no permission needed).
        if (Build.VERSION.SDK_INT >= 23) {
            list += Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        }
        return list
    }

    private fun resolvable(intent: Intent): Boolean {
        val ctx = context() ?: return false
        return try {
            val pm = ctx.packageManager
            val info = if (Build.VERSION.SDK_INT >= 33) {
                pm.resolveActivity(
                    intent,
                    PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()),
                )
            } else {
                @Suppress("DEPRECATION")
                pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
            }
            info?.activityInfo?.exported == true
        } catch (e: Exception) {
            false
        }
    }

    fun availableScreens(): List<String> = buildList {
        if (autostartIntents().any { resolvable(it) }) add("autostart")
        if (batteryIntents().any { resolvable(it) }) add("battery")
    }

    fun openScreen(kind: String): Boolean {
        val intents = when (kind) {
            "autostart" -> autostartIntents()
            "battery" -> batteryIntents()
            else -> return false
        }
        for (intent in intents) {
            if (!resolvable(intent)) continue
            if (start(intent)) return true
        }
        return false
    }

    private fun start(intent: Intent): Boolean {
        return try {
            val a = activity()
            if (a != null) {
                a.startActivity(intent)
            } else {
                val ctx = context() ?: return false
                ctx.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            }
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: SecurityException) {
            // Some OEM screens are protected on some firmware; try the next.
            false
        }
    }

    // ── Auto-reset (unused app restrictions) ─────────────────────────────

    /** 0 not available, 1 exempt, 2 enabled, 3 unknown. */
    fun autoResetStatus(result: MethodChannel.Result) {
        val ctx = context()
        if (ctx == null) {
            result.success(3)
            return
        }
        try {
            val future = PackageManagerCompat.getUnusedAppRestrictionsStatus(ctx)
            future.addListener({
                val code = try {
                    when (future.get()) {
                        UnusedAppRestrictionsConstants.FEATURE_NOT_AVAILABLE -> 0
                        UnusedAppRestrictionsConstants.DISABLED -> 1
                        UnusedAppRestrictionsConstants.API_30_BACKPORT,
                        UnusedAppRestrictionsConstants.API_30,
                        UnusedAppRestrictionsConstants.API_31 -> 2
                        else -> 3
                    }
                } catch (e: Exception) {
                    3
                }
                result.success(code)
            }, ContextCompat.getMainExecutor(ctx))
        } catch (e: Exception) {
            result.success(3)
        }
    }

    fun openAutoResetSettings(): Boolean {
        val ctx = context() ?: return false
        val a = activity() ?: return false
        return try {
            val intent = IntentCompat.createManageUnusedAppRestrictionsIntent(ctx, ctx.packageName)
            // The AndroidX docs require startActivityForResult for this intent.
            a.startActivityForResult(intent, REQ_AUTO_RESET)
            true
        } catch (e: Exception) {
            // Feature not available on this phone: fall back to app details.
            try {
                a.startActivity(
                    Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", ctx.packageName, null),
                    ),
                )
                true
            } catch (e2: Exception) {
                false
            }
        }
    }
}
