// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted. "Okapi" is a trademark of Sanket Santosh Vidya Manohar.

package dev.okapi.permissions

import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.bluetooth.BluetoothManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Okapi Android plugin.
 *
 * Highlights compared with typical permission plugins:
 *  - Only requests permissions your manifest actually declares, and tells you
 *    exactly what to add when something is missing.
 *  - Tells "permanently denied" apart from "dialog dismissed" by comparing
 *    the rationale flag before and after each request.
 *  - Handles background location / body sensors in the order Android
 *    requires (foreground first).
 *  - Handles special app-access screens (overlay, battery, exact alarms, all
 *    files, install apps, Do Not Disturb) and re-checks when the user returns.
 */
class OkapiPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener,
    PluginRegistry.ActivityResultListener {

    companion object {
        private const val CHANNEL = "dev.okapi/permissions"
        private const val REQ_RUNTIME = 0x0CA1
        private const val REQ_SPECIAL = 0x0CA2
        private const val PREFS = "dev.okapi.permissions"
        private const val KEY_ASKED = "asked"
    }

    private var channel: MethodChannel? = null
    private var context: Context? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private val extras = OkapiExtras({ context }, { activity })

    // ── State of the request currently running ───────────────────────────
    private var pendingResult: MethodChannel.Result? = null
    private val queue = ArrayDeque<String>()
    private val results = HashMap<String, Int>()
    private var current: String? = null
    private var foregroundStage = false
    private var requestedNow: List<String> = emptyList()
    private val rationaleBefore = HashMap<String, Boolean>()
    private val askedBefore = HashMap<String, Boolean>()

    // ── Flutter plumbing ─────────────────────────────────────────────────

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler(this)
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) = attach(binding)
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        attach(binding)

    override fun onDetachedFromActivityForConfigChanges() = detach()
    override fun onDetachedFromActivity() = detach()

    private fun attach(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addRequestPermissionsResultListener(this)
        binding.addActivityResultListener(this)
    }

    private fun detach() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context
        if (ctx == null) {
            result.error("native_error", "Okapi is not attached to an engine.", null)
            return
        }
        try {
            when (call.method) {
                "checkStatus" -> result.success(status(call.arguments as String))
                "request" -> startRequest(call, result)
                "shouldShowRationale" -> result.success(
                    shouldShowRationale(call.arguments as String)
                )
                "checkServiceStatus" -> result.success(
                    serviceStatus(call.arguments as String)
                )
                "openAppSettings" -> result.success(openAppSettings())
                "openServiceSettings" -> result.success(
                    openServiceSettings(call.arguments as String)
                )
                "isDeclared" -> result.success(isDeclared(call.arguments as String))
                "loadStore" -> result.success(extras.loadStore())
                "writeStore" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as Map<String, Any?>
                    extras.writeStore(args["key"] as String, args["value"] as String?)
                    result.success(null)
                }
                "deviceInfo" -> result.success(extras.deviceInfo())
                "availableOemScreens" -> result.success(extras.availableScreens())
                "openOemScreen" -> result.success(extras.openScreen(call.arguments as String))
                "autoResetStatus" -> extras.autoResetStatus(result)
                "openAutoResetSettings" -> result.success(extras.openAutoResetSettings())
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("native_error", e.message ?: e.toString(), null)
        }
    }

    // ── Manifest helpers ─────────────────────────────────────────────────

    private val declared: Set<String> by lazy {
        val ctx = context ?: return@lazy emptySet()
        try {
            val info = if (Build.VERSION.SDK_INT >= 33) {
                ctx.packageManager.getPackageInfo(
                    ctx.packageName,
                    PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong()),
                )
            } else {
                @Suppress("DEPRECATION")
                ctx.packageManager.getPackageInfo(ctx.packageName, PackageManager.GET_PERMISSIONS)
            }
            info.requestedPermissions?.toSet() ?: emptySet()
        } catch (e: Exception) {
            emptySet()
        }
    }

    private fun declaredOf(names: List<String>) = names.filter { it in declared }

    private fun isDeclared(permission: String): Boolean = when (val spec = PermissionSpec.of(permission)) {
        is Spec.Runtime -> {
            val main = if (spec.anyOf) declaredOf(spec.names).isNotEmpty()
            else spec.names.all { it in declared }
            val fg = spec.foreground.isEmpty() || declaredOf(spec.foreground).isNotEmpty()
            main && fg
        }
        is Spec.Special -> declaredOf(spec.names).isNotEmpty()
        else -> true
    }

    private fun toRequest(spec: Spec.Runtime): List<String> =
        declaredOf(spec.names) + declaredOf(spec.optional)

    // ── "Asked before" memory (to detect permanent denial) ───────────────

    private val prefs: SharedPreferences?
        get() = context?.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    private fun wasAsked(name: String) =
        prefs?.getStringSet(KEY_ASKED, emptySet())?.contains(name) == true

    private fun setAsked(name: String, asked: Boolean) {
        val p = prefs ?: return
        val set = HashSet(p.getStringSet(KEY_ASKED, emptySet()) ?: emptySet())
        val changed = if (asked) set.add(name) else set.remove(name)
        if (changed) p.edit().putStringSet(KEY_ASKED, set).apply()
    }

    private fun isGranted(name: String): Boolean {
        val ctx = context ?: return false
        return ContextCompat.checkSelfPermission(ctx, name) == PackageManager.PERMISSION_GRANTED
    }

    private fun rationale(name: String): Boolean {
        val a = activity ?: return false
        return ActivityCompat.shouldShowRequestPermissionRationale(a, name)
    }

    /** State of one manifest permission when nothing was just requested. */
    private fun checkName(name: String): Int {
        if (isGranted(name)) {
            // If the user later revokes it in Settings, Android lets us ask
            // again, so forget that we asked before.
            setAsked(name, false)
            return Codes.GRANTED
        }
        return if (activity != null && wasAsked(name) && !rationale(name)) {
            Codes.PERMANENTLY_DENIED
        } else Codes.DENIED
    }

    /** State of one manifest permission right after a request. */
    private fun decide(name: String, granted: Boolean): Int {
        if (granted) {
            setAsked(name, false)
            return Codes.GRANTED
        }
        val after = rationale(name)
        val before = rationaleBefore[name] ?: false
        val asked = askedBefore[name] ?: false
        return when {
            after -> {
                setAsked(name, true); Codes.DENIED
            }
            // First ever ask and still no rationale: the user dismissed the
            // dialog without choosing. Not a permanent denial.
            !asked && !before -> Codes.DENIED
            else -> {
                setAsked(name, true); Codes.PERMANENTLY_DENIED
            }
        }
    }

    // ── Status ───────────────────────────────────────────────────────────

    private fun status(permission: String): Int =
        statusWith(permission) { checkName(it) }

    private fun statusWith(permission: String, stateOf: (String) -> Int): Int =
        when (val spec = PermissionSpec.of(permission)) {
            Spec.NotApplicable -> Codes.NOT_APPLICABLE
            Spec.AlwaysGranted -> Codes.GRANTED
            Spec.LegacyNotification ->
                if (notificationsEnabled()) Codes.GRANTED else Codes.PERMANENTLY_DENIED
            is Spec.Special -> if (specialGranted(spec)) Codes.GRANTED else Codes.DENIED
            is Spec.Runtime -> runtimeStatus(permission, spec, stateOf)
        }

    private fun runtimeStatus(
        permission: String,
        spec: Spec.Runtime,
        stateOf: (String) -> Int,
    ): Int {
        if (spec.foreground.isNotEmpty()) {
            val fg = declaredOf(spec.foreground)
            if (fg.none { isGranted(it) }) return aggregate(fg.map { checkName(it) })
        }

        val names = toRequest(spec)
        if (names.isEmpty()) return Codes.DENIED

        if (PermissionSpec.isLocation(permission)) {
            val fineDeclared = PermissionSpec.LOCATION_FINE in declared
            val fine = if (fineDeclared) stateOf(PermissionSpec.LOCATION_FINE) else null
            val coarse = if (PermissionSpec.LOCATION_COARSE in declared) {
                stateOf(PermissionSpec.LOCATION_COARSE)
            } else null
            return when {
                fine == Codes.GRANTED -> Codes.GRANTED
                coarse == Codes.GRANTED -> if (fineDeclared) Codes.LIMITED else Codes.GRANTED
                else -> aggregate(listOfNotNull(fine, coarse))
            }
        }

        if (PermissionSpec.isVisualMedia(permission)) {
            val mainName = spec.names.first()
            val main = stateOf(mainName)
            if (main == Codes.GRANTED) return Codes.GRANTED
            if (PermissionSpec.VISUAL_USER_SELECTED in declared &&
                isGranted(PermissionSpec.VISUAL_USER_SELECTED)
            ) return Codes.LIMITED
            return main
        }

        return aggregate(declaredOf(spec.names).ifEmpty { names }.map(stateOf))
    }

    private fun aggregate(states: List<Int>): Int = when {
        states.isEmpty() -> Codes.DENIED
        states.all { it == Codes.GRANTED } -> Codes.GRANTED
        states.any { it == Codes.GRANTED } -> Codes.LIMITED
        states.any { it == Codes.PERMANENTLY_DENIED } -> Codes.PERMANENTLY_DENIED
        else -> Codes.DENIED
    }

    private fun notificationsEnabled(): Boolean {
        val ctx = context ?: return false
        return NotificationManagerCompat.from(ctx).areNotificationsEnabled()
    }

    private fun specialGranted(spec: Spec.Special): Boolean {
        val ctx = context ?: return false
        return when (spec.kind) {
            SpecialKind.MANAGE_STORAGE ->
                Build.VERSION.SDK_INT >= 30 && Environment.isExternalStorageManager()
            SpecialKind.BATTERY -> if (Build.VERSION.SDK_INT < 23) true else {
                val pm = ctx.getSystemService(Context.POWER_SERVICE) as PowerManager
                pm.isIgnoringBatteryOptimizations(ctx.packageName)
            }
            SpecialKind.OVERLAY ->
                Build.VERSION.SDK_INT < 23 || Settings.canDrawOverlays(ctx)
            SpecialKind.INSTALL_PACKAGES ->
                Build.VERSION.SDK_INT >= 26 && ctx.packageManager.canRequestPackageInstalls()
            SpecialKind.NOTIFICATION_POLICY -> if (Build.VERSION.SDK_INT < 23) true else {
                val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.isNotificationPolicyAccessGranted
            }
            SpecialKind.EXACT_ALARM -> {
                if (Build.VERSION.SDK_INT < 31) true
                else {
                    val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                    am.canScheduleExactAlarms()
                }
            }
        }
    }

    private fun shouldShowRationale(permission: String): Boolean {
        val spec = PermissionSpec.of(permission) as? Spec.Runtime ?: return false
        return toRequest(spec).any { rationale(it) }
    }

    // ── Services ─────────────────────────────────────────────────────────

    private fun serviceStatus(permission: String): Int {
        val ctx = context ?: return 2
        return when {
            permission.startsWith("location") -> {
                val lm = ctx.getSystemService(Context.LOCATION_SERVICE) as? LocationManager
                    ?: return 0
                if (LocationManagerCompat.isLocationEnabled(lm)) 1 else 0
            }
            permission.startsWith("bluetooth") -> try {
                val bm = ctx.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val adapter = bm?.adapter ?: return 2 // No Bluetooth hardware.
                if (adapter.isEnabled) 1 else 0
            } catch (e: SecurityException) {
                2
            }
            else -> 2
        }
    }

    private fun openServiceSettings(permission: String): Boolean {
        val action = when {
            permission.startsWith("location") -> Settings.ACTION_LOCATION_SOURCE_SETTINGS
            permission.startsWith("bluetooth") -> Settings.ACTION_BLUETOOTH_SETTINGS
            else -> return openAppSettings()
        }
        return launch(Intent(action)) || openAppSettings()
    }

    private fun appSettingsIntent(): Intent {
        val pkg = context?.packageName ?: ""
        return Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", pkg, null),
        )
    }

    private fun openAppSettings(): Boolean = launch(appSettingsIntent())

    private fun launch(intent: Intent): Boolean {
        val a = activity
        return try {
            if (a != null) {
                a.startActivity(intent)
            } else {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context?.startActivity(intent) ?: return false
            }
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    // ── Requests ─────────────────────────────────────────────────────────

    private fun startRequest(call: MethodCall, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error(
                "already_running",
                "Okapi: a permission request is already running. " +
                    "Use Okapi.requestMany or await the previous call.",
                null,
            )
            return
        }
        if (activity == null) {
            result.error(
                "no_activity",
                "Okapi: no foreground Activity. Request permissions while your " +
                    "app is visible (for example after the first frame).",
                null,
            )
            return
        }
        @Suppress("UNCHECKED_CAST")
        val args = call.arguments as Map<String, Any?>
        @Suppress("UNCHECKED_CAST")
        val permissions = args["permissions"] as List<String>

        for (p in permissions) {
            if (!isDeclared(p)) {
                result.error(
                    "not_declared",
                    "Okapi: \"$p\" is not declared in AndroidManifest.xml. " +
                        "See OkapiDeclarations.android(OkapiPermission.$p) for the lines to add.",
                    mapOf("permission" to p),
                )
                return
            }
        }

        pendingResult = result
        results.clear()
        queue.clear()
        queue.addAll(permissions)
        next()
    }

    private fun next() {
        val p = queue.removeFirstOrNull()
        if (p == null) {
            val r = pendingResult
            pendingResult = null
            current = null
            r?.success(HashMap(results))
            return
        }
        current = p
        foregroundStage = false

        val now = status(p)
        if (now == Codes.GRANTED || now == Codes.NOT_APPLICABLE) {
            results[p] = now
            next()
            return
        }

        when (val spec = PermissionSpec.of(p)) {
            is Spec.Runtime -> {
                val fg = declaredOf(spec.foreground)
                if (fg.isNotEmpty() && fg.none { isGranted(it) }) {
                    foregroundStage = true
                    askRuntime(fg)
                } else {
                    askRuntime(toRequest(spec))
                }
            }
            is Spec.Special -> askSpecial(spec)
            else -> {
                // Legacy notifications and similar cannot be requested.
                results[p] = now
                next()
            }
        }
    }

    private fun askRuntime(names: List<String>) {
        val a = activity
        if (a == null || names.isEmpty()) {
            results[current!!] = status(current!!)
            next()
            return
        }
        requestedNow = names
        rationaleBefore.clear()
        askedBefore.clear()
        for (n in names) {
            rationaleBefore[n] = rationale(n)
            askedBefore[n] = wasAsked(n)
        }
        ActivityCompat.requestPermissions(a, names.toTypedArray(), REQ_RUNTIME)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQ_RUNTIME || pendingResult == null) return false
        val p = current ?: return false

        val decisions = HashMap<String, Int>()
        for (n in requestedNow) {
            val i = permissions.indexOf(n)
            val granted = i >= 0 && i < grantResults.size &&
                grantResults[i] == PackageManager.PERMISSION_GRANTED
            decisions[n] = decide(n, granted)
        }
        val stateOf: (String) -> Int = { decisions[it] ?: checkName(it) }

        if (foregroundStage) {
            foregroundStage = false
            if (requestedNow.any { decisions[it] == Codes.GRANTED }) {
                // Foreground granted: now ask for the background permission.
                val spec = PermissionSpec.of(p) as Spec.Runtime
                askRuntime(toRequest(spec))
                return true
            }
            results[p] = aggregate(requestedNow.map(stateOf))
            next()
            return true
        }

        results[p] = statusWith(p, stateOf)
        next()
        return true
    }

    private fun askSpecial(spec: Spec.Special) {
        val a = activity ?: run {
            results[current!!] = Codes.DENIED
            next()
            return
        }
        val pkg = Uri.parse("package:${a.packageName}")
        val intent = when (spec.kind) {
            SpecialKind.MANAGE_STORAGE ->
                Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, pkg)
            SpecialKind.BATTERY ->
                Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, pkg)
            SpecialKind.OVERLAY ->
                Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, pkg)
            SpecialKind.INSTALL_PACKAGES ->
                Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES, pkg)
            SpecialKind.NOTIFICATION_POLICY ->
                Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            SpecialKind.EXACT_ALARM ->
                Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, pkg)
        }
        try {
            a.startActivityForResult(intent, REQ_SPECIAL)
        } catch (e: ActivityNotFoundException) {
            try {
                // Some OEMs hide the dedicated screen; fall back to app details.
                a.startActivityForResult(appSettingsIntent(), REQ_SPECIAL)
            } catch (e2: ActivityNotFoundException) {
                results[current!!] = Codes.DENIED
                next()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        // Dart re-checks auto-reset when the app resumes; just consume it.
        if (requestCode == OkapiExtras.REQ_AUTO_RESET) return true
        if (requestCode != REQ_SPECIAL || pendingResult == null) return false
        val p = current ?: return false
        results[p] = status(p)
        next()
        return true
    }
}
