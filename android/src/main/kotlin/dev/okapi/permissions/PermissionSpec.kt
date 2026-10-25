// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package dev.okapi.permissions

import android.Manifest
import android.os.Build

/** Status codes shared with Dart (see OkapiStatus.fromCode). */
object Codes {
    const val DENIED = 0
    const val GRANTED = 1
    const val RESTRICTED = 2
    const val LIMITED = 3
    const val PERMANENTLY_DENIED = 4
    const val PROVISIONAL = 5
    const val NOT_APPLICABLE = 6
}

/** The special "app access" screens Android uses instead of a dialog. */
enum class SpecialKind {
    MANAGE_STORAGE,
    BATTERY,
    OVERLAY,
    INSTALL_PACKAGES,
    NOTIFICATION_POLICY,
    EXACT_ALARM,
}

/** How one Okapi permission maps to Android on the running OS version. */
sealed class Spec {
    /** Doesn't exist on this OS version or platform. */
    object NotApplicable : Spec()

    /** Granted automatically at install time on this OS version. */
    object AlwaysGranted : Spec()

    /** Notifications below Android 13: read-only system switch. */
    object LegacyNotification : Spec()

    /**
     * Normal runtime permissions.
     *
     * @param names the manifest permissions this maps to.
     * @param anyOf when true, declaring any one of [names] is enough and only
     *   the declared ones are requested.
     * @param optional extra permissions requested only if declared.
     * @param foreground prerequisites that must be granted first (background
     *   location, background body sensors).
     */
    data class Runtime(
        val names: List<String>,
        val anyOf: Boolean = false,
        val optional: List<String> = emptyList(),
        val foreground: List<String> = emptyList(),
    ) : Spec()

    /** A special app-access settings screen. */
    data class Special(
        val kind: SpecialKind,
        val names: List<String>,
    ) : Spec()
}

object PermissionSpec {
    private val sdk get() = Build.VERSION.SDK_INT

    private const val FINE = Manifest.permission.ACCESS_FINE_LOCATION
    private const val COARSE = Manifest.permission.ACCESS_COARSE_LOCATION
    private const val READ_STORAGE = Manifest.permission.READ_EXTERNAL_STORAGE
    private const val VISUAL_SELECTED =
        "android.permission.READ_MEDIA_VISUAL_USER_SELECTED"

    /** Names that decide "full" location access when declared. */
    const val LOCATION_FINE = FINE
    const val LOCATION_COARSE = COARSE
    const val READ_MEDIA_IMAGES = "android.permission.READ_MEDIA_IMAGES"
    const val READ_MEDIA_VIDEO = "android.permission.READ_MEDIA_VIDEO"
    const val VISUAL_USER_SELECTED = VISUAL_SELECTED

    fun of(permission: String): Spec = when (permission) {
        "camera" -> Spec.Runtime(listOf(Manifest.permission.CAMERA))

        "microphone", "speech" ->
            Spec.Runtime(listOf(Manifest.permission.RECORD_AUDIO))

        "photos" -> if (sdk >= 33) {
            Spec.Runtime(
                listOf(READ_MEDIA_IMAGES),
                optional = if (sdk >= 34) listOf(VISUAL_SELECTED) else emptyList(),
            )
        } else Spec.Runtime(listOf(READ_STORAGE))

        "videos" -> if (sdk >= 33) {
            Spec.Runtime(
                listOf(READ_MEDIA_VIDEO),
                optional = if (sdk >= 34) listOf(VISUAL_SELECTED) else emptyList(),
            )
        } else Spec.Runtime(listOf(READ_STORAGE))

        "audio" -> if (sdk >= 33) {
            Spec.Runtime(listOf("android.permission.READ_MEDIA_AUDIO"))
        } else Spec.Runtime(listOf(READ_STORAGE))

        "storage" -> if (sdk >= 33) Spec.NotApplicable else Spec.Runtime(
            listOf(READ_STORAGE),
            optional = if (sdk <= 28) {
                listOf(Manifest.permission.WRITE_EXTERNAL_STORAGE)
            } else emptyList(),
        )

        "manageExternalStorage" -> if (sdk >= 30) {
            Spec.Special(
                SpecialKind.MANAGE_STORAGE,
                listOf("android.permission.MANAGE_EXTERNAL_STORAGE"),
            )
        } else Spec.NotApplicable

        "mediaLocation" -> if (sdk >= 29) {
            Spec.Runtime(listOf("android.permission.ACCESS_MEDIA_LOCATION"))
        } else Spec.AlwaysGranted

        "location", "locationWhenInUse" ->
            Spec.Runtime(listOf(FINE, COARSE), anyOf = true)

        "locationAlways" -> if (sdk >= 29) {
            Spec.Runtime(
                listOf("android.permission.ACCESS_BACKGROUND_LOCATION"),
                foreground = listOf(FINE, COARSE),
            )
        } else Spec.Runtime(listOf(FINE, COARSE), anyOf = true)

        "notification" -> if (sdk >= 33) {
            Spec.Runtime(listOf("android.permission.POST_NOTIFICATIONS"))
        } else Spec.LegacyNotification

        "accessNotificationPolicy" -> Spec.Special(
            SpecialKind.NOTIFICATION_POLICY,
            listOf(Manifest.permission.ACCESS_NOTIFICATION_POLICY),
        )

        "contacts" -> Spec.Runtime(
            listOf(Manifest.permission.READ_CONTACTS, Manifest.permission.WRITE_CONTACTS),
            anyOf = true,
        )

        "calendarFullAccess" -> Spec.Runtime(
            listOf(Manifest.permission.READ_CALENDAR, Manifest.permission.WRITE_CALENDAR),
        )

        "calendarWriteOnly" ->
            Spec.Runtime(listOf(Manifest.permission.WRITE_CALENDAR))

        "phone" -> Spec.Runtime(
            buildList {
                add(Manifest.permission.READ_PHONE_STATE)
                add(Manifest.permission.CALL_PHONE)
                if (sdk >= 26) {
                    add("android.permission.READ_PHONE_NUMBERS")
                    add("android.permission.ANSWER_PHONE_CALLS")
                }
                add(Manifest.permission.READ_CALL_LOG)
                add(Manifest.permission.WRITE_CALL_LOG)
                add(Manifest.permission.ADD_VOICEMAIL)
                add(Manifest.permission.USE_SIP)
            },
            anyOf = true,
        )

        "sms" -> Spec.Runtime(
            listOf(
                Manifest.permission.SEND_SMS,
                Manifest.permission.RECEIVE_SMS,
                Manifest.permission.READ_SMS,
                Manifest.permission.RECEIVE_WAP_PUSH,
                Manifest.permission.RECEIVE_MMS,
            ),
            anyOf = true,
        )

        "sensors" -> Spec.Runtime(listOf(Manifest.permission.BODY_SENSORS))

        "sensorsAlways" -> if (sdk >= 33) {
            Spec.Runtime(
                listOf("android.permission.BODY_SENSORS_BACKGROUND"),
                foreground = listOf(Manifest.permission.BODY_SENSORS),
            )
        } else Spec.NotApplicable

        "activityRecognition" -> if (sdk >= 29) {
            Spec.Runtime(listOf("android.permission.ACTIVITY_RECOGNITION"))
        } else Spec.AlwaysGranted

        "bluetooth" -> if (sdk >= 31) {
            Spec.Runtime(
                listOf(
                    "android.permission.BLUETOOTH_SCAN",
                    "android.permission.BLUETOOTH_CONNECT",
                ),
                anyOf = true,
            )
        } else Spec.AlwaysGranted

        "bluetoothScan" -> if (sdk >= 31) {
            Spec.Runtime(listOf("android.permission.BLUETOOTH_SCAN"))
        } else Spec.AlwaysGranted

        "bluetoothConnect" -> if (sdk >= 31) {
            Spec.Runtime(listOf("android.permission.BLUETOOTH_CONNECT"))
        } else Spec.AlwaysGranted

        "bluetoothAdvertise" -> if (sdk >= 31) {
            Spec.Runtime(listOf("android.permission.BLUETOOTH_ADVERTISE"))
        } else Spec.AlwaysGranted

        "nearbyWifiDevices" -> if (sdk >= 33) {
            Spec.Runtime(listOf("android.permission.NEARBY_WIFI_DEVICES"))
        } else Spec.NotApplicable

        "ignoreBatteryOptimizations" -> Spec.Special(
            SpecialKind.BATTERY,
            listOf(Manifest.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS),
        )

        "systemAlertWindow" -> Spec.Special(
            SpecialKind.OVERLAY,
            listOf(Manifest.permission.SYSTEM_ALERT_WINDOW),
        )

        "requestInstallPackages" -> if (sdk >= 26) {
            Spec.Special(
                SpecialKind.INSTALL_PACKAGES,
                listOf("android.permission.REQUEST_INSTALL_PACKAGES"),
            )
        } else Spec.NotApplicable

        "scheduleExactAlarm" -> if (sdk >= 31) {
            Spec.Special(
                SpecialKind.EXACT_ALARM,
                listOf(
                    "android.permission.SCHEDULE_EXACT_ALARM",
                    "android.permission.USE_EXACT_ALARM",
                ),
            )
        } else Spec.AlwaysGranted

        // iOS-only permissions.
        else -> Spec.NotApplicable
    }

    /** Whether [permission] is a location permission (fine vs coarse logic). */
    fun isLocation(permission: String) =
        permission == "location" ||
            permission == "locationWhenInUse" ||
            (permission == "locationAlways" && sdk < 29)

    /** Whether [permission] can be "selected photos only" on Android 14+. */
    fun isVisualMedia(permission: String) =
        (permission == "photos" || permission == "videos") && sdk >= 34
}
