// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted.

import 'package:flutter/material.dart';

import '../core/permission.dart';
import '../core/status.dart';

/// The Material icon Okapi uses for each permission.
IconData okapiIconFor(OkapiPermission p) => switch (p) {
      OkapiPermission.camera => Icons.photo_camera_rounded,
      OkapiPermission.microphone => Icons.mic_rounded,
      OkapiPermission.speech => Icons.record_voice_over_rounded,
      OkapiPermission.photos ||
      OkapiPermission.photosAddOnly =>
        Icons.photo_library_rounded,
      OkapiPermission.videos => Icons.video_library_rounded,
      OkapiPermission.audio ||
      OkapiPermission.mediaLibrary =>
        Icons.library_music_rounded,
      OkapiPermission.storage ||
      OkapiPermission.manageExternalStorage =>
        Icons.folder_rounded,
      OkapiPermission.mediaLocation => Icons.add_location_alt_rounded,
      OkapiPermission.location ||
      OkapiPermission.locationWhenInUse =>
        Icons.location_on_rounded,
      OkapiPermission.locationAlways => Icons.share_location_rounded,
      OkapiPermission.notification => Icons.notifications_active_rounded,
      OkapiPermission.criticalAlerts => Icons.notification_important_rounded,
      OkapiPermission.accessNotificationPolicy =>
        Icons.do_not_disturb_on_rounded,
      OkapiPermission.contacts => Icons.contacts_rounded,
      OkapiPermission.calendarFullAccess ||
      OkapiPermission.calendarWriteOnly =>
        Icons.calendar_month_rounded,
      OkapiPermission.reminders => Icons.checklist_rounded,
      OkapiPermission.phone => Icons.call_rounded,
      OkapiPermission.sms => Icons.sms_rounded,
      OkapiPermission.sensors ||
      OkapiPermission.sensorsAlways =>
        Icons.monitor_heart_rounded,
      OkapiPermission.activityRecognition => Icons.directions_walk_rounded,
      OkapiPermission.bluetooth ||
      OkapiPermission.bluetoothScan ||
      OkapiPermission.bluetoothConnect ||
      OkapiPermission.bluetoothAdvertise =>
        Icons.bluetooth_rounded,
      OkapiPermission.nearbyWifiDevices => Icons.wifi_rounded,
      OkapiPermission.appTrackingTransparency => Icons.ads_click_rounded,
      OkapiPermission.ignoreBatteryOptimizations =>
        Icons.battery_charging_full_rounded,
      OkapiPermission.systemAlertWindow => Icons.picture_in_picture_rounded,
      OkapiPermission.requestInstallPackages => Icons.install_mobile_rounded,
      OkapiPermission.scheduleExactAlarm => Icons.alarm_rounded,
      OkapiPermission.backgroundRefresh => Icons.sync_rounded,
    };

/// The icon Okapi uses for each status.
IconData okapiStatusIcon(OkapiStatus s) => switch (s) {
      OkapiStatus.granted => Icons.check_circle_rounded,
      OkapiStatus.limited => Icons.adjust_rounded,
      OkapiStatus.provisional => Icons.notifications_paused_rounded,
      OkapiStatus.denied => Icons.radio_button_unchecked_rounded,
      OkapiStatus.permanentlyDenied => Icons.block_rounded,
      OkapiStatus.restricted => Icons.lock_rounded,
      OkapiStatus.notApplicable => Icons.remove_circle_outline_rounded,
    };
