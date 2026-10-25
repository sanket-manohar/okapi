// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The platforms a permission is meaningful on.
enum OkapiPlatformSupport {
  /// Requested at runtime on Android and iOS.
  both,

  /// Only exists on Android. Always `notApplicable` on iOS.
  androidOnly,

  /// Only exists on iOS. Always `notApplicable` on Android.
  iosOnly,
}

/// Whether a permission is a normal runtime dialog or a "special" system
/// screen the user has to toggle manually (Android special app access).
enum OkapiRequestKind {
  /// Shows the standard system permission dialog.
  runtimeDialog,

  /// Opens a dedicated system settings screen (for example
  /// "Display over other apps"). Okapi re-checks when the user comes back.
  specialSettingsScreen,

  /// Cannot be requested by the app at all; the status can only be read
  /// (for example iOS Background App Refresh).
  readOnly,
}

/// Every permission Okapi can check and request.
///
/// The [name] of each value is the exact identifier sent to the native side,
/// so never rename values without updating the Kotlin and Swift code.
enum OkapiPermission {
  // ── Camera & audio ───────────────────────────────────────────────────────
  /// Camera. Android `CAMERA`, iOS `NSCameraUsageDescription`.
  camera(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Microphone. Android `RECORD_AUDIO`, iOS `NSMicrophoneUsageDescription`.
  microphone(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Speech recognition. Android `RECORD_AUDIO`,
  /// iOS `NSSpeechRecognitionUsageDescription`.
  speech(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  // ── Media & storage ──────────────────────────────────────────────────────
  /// Photos. Android 13+ `READ_MEDIA_IMAGES` (14+ also handles the
  /// "selected photos only" choice as [OkapiStatus.limited]), older Android
  /// `READ_EXTERNAL_STORAGE`. iOS read/write photo library.
  photos(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// iOS add-only photo library access (save images without reading).
  photosAddOnly(OkapiPlatformSupport.iosOnly, OkapiRequestKind.runtimeDialog),

  /// Videos. Android 13+ `READ_MEDIA_VIDEO`; iOS uses the photo library.
  videos(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Audio files. Android 13+ `READ_MEDIA_AUDIO`.
  /// On iOS use [mediaLibrary] for the Apple Music library.
  audio(OkapiPlatformSupport.androidOnly, OkapiRequestKind.runtimeDialog),

  /// Legacy shared storage. Android 12 and below only
  /// (`READ_EXTERNAL_STORAGE`, plus `WRITE_EXTERNAL_STORAGE` up to Android 9).
  /// On Android 13+ this is `notApplicable`: use [photos], [videos], [audio].
  storage(OkapiPlatformSupport.androidOnly, OkapiRequestKind.runtimeDialog),

  /// "All files access" (Android 11+ `MANAGE_EXTERNAL_STORAGE`).
  /// Google Play restricts this permission; only request it if your app
  /// qualifies under Play policy.
  manageExternalStorage(
      OkapiPlatformSupport.androidOnly, OkapiRequestKind.specialSettingsScreen),

  /// Location metadata inside photos (Android 10+ `ACCESS_MEDIA_LOCATION`).
  mediaLocation(OkapiPlatformSupport.androidOnly, OkapiRequestKind.runtimeDialog),

  /// Apple Music / media library (iOS `NSAppleMusicUsageDescription`).
  mediaLibrary(OkapiPlatformSupport.iosOnly, OkapiRequestKind.runtimeDialog),

  // ── Location ─────────────────────────────────────────────────────────────
  /// Foreground location. Same as [locationWhenInUse].
  location(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Foreground location. Android fine + coarse; "approximate only" is
  /// reported as [OkapiStatus.limited]. iOS when-in-use (reduced accuracy is
  /// reported as [OkapiStatus.limited]).
  locationWhenInUse(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Background location. Android 10+ `ACCESS_BACKGROUND_LOCATION` (the user
  /// must grant foreground location first; Okapi enforces this order).
  /// iOS "Always".
  locationAlways(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  // ── Notifications ────────────────────────────────────────────────────────
  /// Notifications. Android 13+ `POST_NOTIFICATIONS`; below 13 the status is
  /// read from the system notification switch. iOS alert/badge/sound;
  /// provisional authorisation is reported as [OkapiStatus.provisional].
  notification(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// iOS critical alerts (requires an Apple entitlement).
  criticalAlerts(OkapiPlatformSupport.iosOnly, OkapiRequestKind.runtimeDialog),

  /// Do Not Disturb access (Android `ACCESS_NOTIFICATION_POLICY`).
  accessNotificationPolicy(
      OkapiPlatformSupport.androidOnly, OkapiRequestKind.specialSettingsScreen),

  // ── Personal data ────────────────────────────────────────────────────────
  /// Contacts. Android `READ_CONTACTS`/`WRITE_CONTACTS`; iOS contacts
  /// (iOS 18 "limited contacts" is reported as [OkapiStatus.limited]).
  contacts(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Full calendar access (read + write). iOS 17+ full access.
  calendarFullAccess(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Write-only calendar access (add events without reading). iOS 17+.
  calendarWriteOnly(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// iOS Reminders.
  reminders(OkapiPlatformSupport.iosOnly, OkapiRequestKind.runtimeDialog),

  // ── Phone & SMS ──────────────────────────────────────────────────────────
  /// Phone. Android `READ_PHONE_STATE`, `CALL_PHONE` and related, whichever
  /// your manifest declares.
  phone(OkapiPlatformSupport.androidOnly, OkapiRequestKind.runtimeDialog),

  /// SMS. Android `SEND_SMS`, `READ_SMS`, `RECEIVE_SMS`, whichever your
  /// manifest declares. Google Play restricts SMS permissions.
  sms(OkapiPlatformSupport.androidOnly, OkapiRequestKind.runtimeDialog),

  // ── Sensors & activity ───────────────────────────────────────────────────
  /// Body sensors (Android `BODY_SENSORS`); iOS motion & fitness.
  sensors(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Body sensors in the background (Android 13+ `BODY_SENSORS_BACKGROUND`).
  sensorsAlways(OkapiPlatformSupport.androidOnly, OkapiRequestKind.runtimeDialog),

  /// Physical activity. Android 10+ `ACTIVITY_RECOGNITION`;
  /// iOS motion & fitness.
  activityRecognition(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  // ── Bluetooth & nearby ───────────────────────────────────────────────────
  /// Bluetooth. Android 12+ scan + connect; iOS Bluetooth.
  bluetooth(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Android 12+ `BLUETOOTH_SCAN`. On iOS this maps to [bluetooth].
  bluetoothScan(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Android 12+ `BLUETOOTH_CONNECT`. On iOS this maps to [bluetooth].
  bluetoothConnect(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Android 12+ `BLUETOOTH_ADVERTISE`. On iOS this maps to [bluetooth].
  bluetoothAdvertise(OkapiPlatformSupport.both, OkapiRequestKind.runtimeDialog),

  /// Android 13+ `NEARBY_WIFI_DEVICES`.
  nearbyWifiDevices(OkapiPlatformSupport.androidOnly, OkapiRequestKind.runtimeDialog),

  // ── Privacy & tracking ───────────────────────────────────────────────────
  /// iOS 14+ App Tracking Transparency. Okapi automatically waits until the
  /// app is active before asking, which avoids the common "dialog never
  /// shows" bug.
  appTrackingTransparency(
      OkapiPlatformSupport.iosOnly, OkapiRequestKind.runtimeDialog),

  // ── Android special app access ───────────────────────────────────────────
  /// Ignore battery optimisations
  /// (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`).
  ignoreBatteryOptimizations(
      OkapiPlatformSupport.androidOnly, OkapiRequestKind.specialSettingsScreen),

  /// Display over other apps (`SYSTEM_ALERT_WINDOW`).
  systemAlertWindow(
      OkapiPlatformSupport.androidOnly, OkapiRequestKind.specialSettingsScreen),

  /// Install unknown apps (`REQUEST_INSTALL_PACKAGES`).
  requestInstallPackages(
      OkapiPlatformSupport.androidOnly, OkapiRequestKind.specialSettingsScreen),

  /// Exact alarms (Android 12+ `SCHEDULE_EXACT_ALARM`).
  scheduleExactAlarm(
      OkapiPlatformSupport.androidOnly, OkapiRequestKind.specialSettingsScreen),

  // ── iOS read-only ────────────────────────────────────────────────────────
  /// iOS Background App Refresh. Read-only: apps cannot request it.
  backgroundRefresh(OkapiPlatformSupport.iosOnly, OkapiRequestKind.readOnly);

  const OkapiPermission(this.support, this.requestKind);

  /// Platforms where this permission exists.
  final OkapiPlatformSupport support;

  /// How the permission is obtained.
  final OkapiRequestKind requestKind;

  /// Whether this permission has a related system service that can be
  /// switched off globally (Location Services, Bluetooth).
  bool get hasService => switch (this) {
        location ||
        locationWhenInUse ||
        locationAlways ||
        bluetooth ||
        bluetoothScan ||
        bluetoothConnect ||
        bluetoothAdvertise =>
          true,
        _ => false,
      };
}
