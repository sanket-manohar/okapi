// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'permission.dart';

/// What each permission needs in AndroidManifest.xml and Info.plist.
///
/// Okapi checks these at runtime and throws an [OkapiException] with the exact
/// fix if something is missing, instead of silently failing (Android) or
/// crashing (iOS).
class OkapiDeclarations {
  OkapiDeclarations._();

  /// `<uses-permission>` names needed on Android. Empty when none are needed.
  static List<String> android(OkapiPermission p) => switch (p) {
        OkapiPermission.camera => const ['android.permission.CAMERA'],
        OkapiPermission.microphone ||
        OkapiPermission.speech =>
          const ['android.permission.RECORD_AUDIO'],
        OkapiPermission.photos => const [
            'android.permission.READ_MEDIA_IMAGES',
            'android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
            'android.permission.READ_EXTERNAL_STORAGE (maxSdkVersion="32")',
          ],
        OkapiPermission.videos => const [
            'android.permission.READ_MEDIA_VIDEO',
            'android.permission.READ_EXTERNAL_STORAGE (maxSdkVersion="32")',
          ],
        OkapiPermission.audio => const [
            'android.permission.READ_MEDIA_AUDIO',
            'android.permission.READ_EXTERNAL_STORAGE (maxSdkVersion="32")',
          ],
        OkapiPermission.storage => const [
            'android.permission.READ_EXTERNAL_STORAGE',
            'android.permission.WRITE_EXTERNAL_STORAGE (maxSdkVersion="28")',
          ],
        OkapiPermission.manageExternalStorage => const [
            'android.permission.MANAGE_EXTERNAL_STORAGE',
          ],
        OkapiPermission.mediaLocation => const [
            'android.permission.ACCESS_MEDIA_LOCATION',
          ],
        OkapiPermission.location || OkapiPermission.locationWhenInUse => const [
            'android.permission.ACCESS_FINE_LOCATION',
            'android.permission.ACCESS_COARSE_LOCATION',
          ],
        OkapiPermission.locationAlways => const [
            'android.permission.ACCESS_FINE_LOCATION',
            'android.permission.ACCESS_COARSE_LOCATION',
            'android.permission.ACCESS_BACKGROUND_LOCATION',
          ],
        OkapiPermission.notification => const [
            'android.permission.POST_NOTIFICATIONS',
          ],
        OkapiPermission.accessNotificationPolicy => const [
            'android.permission.ACCESS_NOTIFICATION_POLICY',
          ],
        OkapiPermission.contacts => const [
            'android.permission.READ_CONTACTS',
            'android.permission.WRITE_CONTACTS',
          ],
        OkapiPermission.calendarFullAccess => const [
            'android.permission.READ_CALENDAR',
            'android.permission.WRITE_CALENDAR',
          ],
        OkapiPermission.calendarWriteOnly => const [
            'android.permission.WRITE_CALENDAR',
          ],
        OkapiPermission.phone => const [
            'android.permission.READ_PHONE_STATE',
            'android.permission.CALL_PHONE (optional)',
            'android.permission.READ_PHONE_NUMBERS (optional)',
          ],
        OkapiPermission.sms => const [
            'android.permission.SEND_SMS',
            'android.permission.READ_SMS (optional)',
            'android.permission.RECEIVE_SMS (optional)',
          ],
        OkapiPermission.sensors => const ['android.permission.BODY_SENSORS'],
        OkapiPermission.sensorsAlways => const [
            'android.permission.BODY_SENSORS',
            'android.permission.BODY_SENSORS_BACKGROUND',
          ],
        OkapiPermission.activityRecognition => const [
            'android.permission.ACTIVITY_RECOGNITION',
          ],
        OkapiPermission.bluetooth => const [
            'android.permission.BLUETOOTH_SCAN',
            'android.permission.BLUETOOTH_CONNECT',
          ],
        OkapiPermission.bluetoothScan => const [
            'android.permission.BLUETOOTH_SCAN',
          ],
        OkapiPermission.bluetoothConnect => const [
            'android.permission.BLUETOOTH_CONNECT',
          ],
        OkapiPermission.bluetoothAdvertise => const [
            'android.permission.BLUETOOTH_ADVERTISE',
          ],
        OkapiPermission.nearbyWifiDevices => const [
            'android.permission.NEARBY_WIFI_DEVICES',
          ],
        OkapiPermission.ignoreBatteryOptimizations => const [
            'android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
          ],
        OkapiPermission.systemAlertWindow => const [
            'android.permission.SYSTEM_ALERT_WINDOW',
          ],
        OkapiPermission.requestInstallPackages => const [
            'android.permission.REQUEST_INSTALL_PACKAGES',
          ],
        OkapiPermission.scheduleExactAlarm => const [
            'android.permission.SCHEDULE_EXACT_ALARM',
          ],
        OkapiPermission.photosAddOnly ||
        OkapiPermission.mediaLibrary ||
        OkapiPermission.criticalAlerts ||
        OkapiPermission.reminders ||
        OkapiPermission.appTrackingTransparency ||
        OkapiPermission.backgroundRefresh =>
          const [],
      };

  /// Info.plist keys needed on iOS. Empty when none are needed.
  static List<String> ios(OkapiPermission p) => switch (p) {
        OkapiPermission.camera => const ['NSCameraUsageDescription'],
        OkapiPermission.microphone => const ['NSMicrophoneUsageDescription'],
        OkapiPermission.speech => const [
            'NSSpeechRecognitionUsageDescription',
          ],
        OkapiPermission.photos ||
        OkapiPermission.videos =>
          const ['NSPhotoLibraryUsageDescription'],
        OkapiPermission.photosAddOnly => const [
            'NSPhotoLibraryAddUsageDescription',
          ],
        OkapiPermission.mediaLibrary => const ['NSAppleMusicUsageDescription'],
        OkapiPermission.location || OkapiPermission.locationWhenInUse => const [
            'NSLocationWhenInUseUsageDescription',
          ],
        OkapiPermission.locationAlways => const [
            'NSLocationWhenInUseUsageDescription',
            'NSLocationAlwaysAndWhenInUseUsageDescription',
          ],
        OkapiPermission.contacts => const ['NSContactsUsageDescription'],
        OkapiPermission.calendarFullAccess => const [
            'NSCalendarsFullAccessUsageDescription (iOS 17+)',
            'NSCalendarsUsageDescription (iOS 16 and below)',
          ],
        OkapiPermission.calendarWriteOnly => const [
            'NSCalendarsWriteOnlyAccessUsageDescription (iOS 17+)',
            'NSCalendarsUsageDescription (iOS 16 and below)',
          ],
        OkapiPermission.reminders => const [
            'NSRemindersFullAccessUsageDescription (iOS 17+)',
            'NSRemindersUsageDescription (iOS 16 and below)',
          ],
        OkapiPermission.sensors ||
        OkapiPermission.activityRecognition =>
          const ['NSMotionUsageDescription'],
        OkapiPermission.bluetooth ||
        OkapiPermission.bluetoothScan ||
        OkapiPermission.bluetoothConnect ||
        OkapiPermission.bluetoothAdvertise =>
          const ['NSBluetoothAlwaysUsageDescription'],
        OkapiPermission.appTrackingTransparency => const [
            'NSUserTrackingUsageDescription',
          ],
        _ => const [],
      };

  /// A ready-to-paste fix for a missing declaration.
  static String hint(OkapiPermission p, {required bool isIOS}) {
    if (isIOS) {
      final keys = ios(p);
      if (keys.isEmpty) return '${p.name} needs no Info.plist entry.';
      final lines = keys
          .map((k) => k.split(' ').first)
          .toSet()
          .map((k) => '  <key>$k</key>\n  <string>Explain why you need it</string>')
          .join('\n');
      return 'Okapi: "${p.name}" is not declared in ios/Runner/Info.plist.\n'
          'Add inside <dict>:\n$lines';
    }
    final names = android(p);
    if (names.isEmpty) return '${p.name} needs no AndroidManifest entry.';
    final lines = names.map((n) {
      final parts = n.split(' ');
      final extra = parts.length > 1 && parts[1].startsWith('(maxSdk')
          ? ' android:${parts[1].replaceAll('(', '').replaceAll(')', '')}'
          : '';
      final note = n.contains('(optional)') ? '  <!-- optional -->' : '';
      return '  <uses-permission android:name="${parts.first}"$extra />$note';
    }).join('\n');
    return 'Okapi: "${p.name}" is not declared in '
        'android/app/src/main/AndroidManifest.xml.\n'
        'Add above <application>:\n$lines';
  }
}
