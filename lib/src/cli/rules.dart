// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Pure Dart: no Flutter imports, so `dart run okapi:doctor` works.

import '../core/permission.dart';

/// How important a declaration is.
enum NeedLevel {
  /// Without it the permission can't be requested (error).
  required,

  /// Needed on some OS versions or for the best experience (warning).
  recommended,

  /// Only for some apps (info).
  optional,
}

/// One declaration. Any one of [names] satisfies it.
class Need {
  /// Creates a need.
  const Need(
    this.names, {
    this.level = NeedLevel.required,
    this.maxSdk,
    this.note,
  });

  /// Acceptable names (manifest permissions or Info.plist keys).
  final List<String> names;

  /// Importance.
  final NeedLevel level;

  /// `android:maxSdkVersion` to write when syncing.
  final int? maxSdk;

  /// Why it matters.
  final String? note;

  /// The name Sync writes.
  String get primary => names.first;
}

const String _a = 'android.permission.';

Need _r(List<String> n, {int? maxSdk, String? note}) =>
    Need([for (final x in n) '$_a$x'], maxSdk: maxSdk, note: note);
Need _rec(List<String> n, {int? maxSdk, String? note}) => Need(
      [for (final x in n) '$_a$x'],
      level: NeedLevel.recommended,
      maxSdk: maxSdk,
      note: note,
    );
Need _opt(List<String> n, {int? maxSdk, String? note}) => Need(
      [for (final x in n) '$_a$x'],
      level: NeedLevel.optional,
      maxSdk: maxSdk,
      note: note,
    );

/// AndroidManifest.xml declarations per permission.
List<Need> androidNeeds(OkapiPermission p) => switch (p) {
      OkapiPermission.camera => [
          _r(['CAMERA']),
        ],
      OkapiPermission.microphone || OkapiPermission.speech => [
          _r(['RECORD_AUDIO']),
        ],
      OkapiPermission.photos => [
          _r(['READ_MEDIA_IMAGES']),
          _rec([
            'READ_MEDIA_VISUAL_USER_SELECTED',
          ], note: 'lets Android 14+ users share selected photos only'),
          _rec(['READ_EXTERNAL_STORAGE'],
              maxSdk: 32, note: 'Android 12 and below'),
        ],
      OkapiPermission.videos => [
          _r(['READ_MEDIA_VIDEO']),
          _rec([
            'READ_MEDIA_VISUAL_USER_SELECTED',
          ], note: 'lets Android 14+ users share selected videos only'),
          _rec(['READ_EXTERNAL_STORAGE'],
              maxSdk: 32, note: 'Android 12 and below'),
        ],
      OkapiPermission.audio => [
          _r(['READ_MEDIA_AUDIO']),
          _rec(['READ_EXTERNAL_STORAGE'],
              maxSdk: 32, note: 'Android 12 and below'),
        ],
      OkapiPermission.storage => [
          _r(['READ_EXTERNAL_STORAGE'], maxSdk: 32),
          _opt(
            ['WRITE_EXTERNAL_STORAGE'],
            maxSdk: 28,
            note: 'writing on Android 9 and below',
          ),
        ],
      OkapiPermission.manageExternalStorage => [
          _r(['MANAGE_EXTERNAL_STORAGE']),
        ],
      OkapiPermission.mediaLocation => [
          _r(['ACCESS_MEDIA_LOCATION']),
        ],
      OkapiPermission.location || OkapiPermission.locationWhenInUse => [
          _r([
            'ACCESS_COARSE_LOCATION',
          ], note: 'Android 12+ ignores a fine-only request'),
          _rec(['ACCESS_FINE_LOCATION'], note: 'precise location'),
        ],
      OkapiPermission.locationAlways => [
          _r(['ACCESS_COARSE_LOCATION']),
          _rec(['ACCESS_FINE_LOCATION'], note: 'precise location'),
          _r(['ACCESS_BACKGROUND_LOCATION']),
        ],
      OkapiPermission.notification => [
          _r(['POST_NOTIFICATIONS']),
        ],
      OkapiPermission.accessNotificationPolicy => [
          _r(['ACCESS_NOTIFICATION_POLICY']),
        ],
      OkapiPermission.contacts => [
          _r(['READ_CONTACTS', 'WRITE_CONTACTS']),
        ],
      OkapiPermission.calendarFullAccess => [
          _r(['READ_CALENDAR']),
          _r(['WRITE_CALENDAR']),
        ],
      OkapiPermission.calendarWriteOnly => [
          _r(['WRITE_CALENDAR']),
        ],
      OkapiPermission.phone => [
          _r([
            'READ_PHONE_STATE',
            'CALL_PHONE',
            'READ_PHONE_NUMBERS',
            'ANSWER_PHONE_CALLS',
            'READ_CALL_LOG',
            'WRITE_CALL_LOG',
            'ADD_VOICEMAIL',
            'USE_SIP',
          ]),
        ],
      OkapiPermission.sms => [
          _r([
            'SEND_SMS',
            'RECEIVE_SMS',
            'READ_SMS',
            'RECEIVE_WAP_PUSH',
            'RECEIVE_MMS',
          ]),
        ],
      OkapiPermission.sensors => [
          _r(['BODY_SENSORS']),
        ],
      OkapiPermission.sensorsAlways => [
          _r(['BODY_SENSORS']),
          _r(['BODY_SENSORS_BACKGROUND']),
        ],
      OkapiPermission.activityRecognition => [
          _r(['ACTIVITY_RECOGNITION']),
        ],
      OkapiPermission.bluetooth => [
          _r(['BLUETOOTH_CONNECT', 'BLUETOOTH_SCAN']),
          _rec(['BLUETOOTH_SCAN'], note: 'finding new devices'),
        ],
      OkapiPermission.bluetoothScan => [
          _r(['BLUETOOTH_SCAN']),
        ],
      OkapiPermission.bluetoothConnect => [
          _r(['BLUETOOTH_CONNECT']),
        ],
      OkapiPermission.bluetoothAdvertise => [
          _r(['BLUETOOTH_ADVERTISE']),
        ],
      OkapiPermission.nearbyWifiDevices => [
          _r(['NEARBY_WIFI_DEVICES']),
        ],
      OkapiPermission.ignoreBatteryOptimizations => [
          _r(['REQUEST_IGNORE_BATTERY_OPTIMIZATIONS']),
        ],
      OkapiPermission.systemAlertWindow => [
          _r(['SYSTEM_ALERT_WINDOW']),
        ],
      OkapiPermission.requestInstallPackages => [
          _r(['REQUEST_INSTALL_PACKAGES']),
        ],
      OkapiPermission.scheduleExactAlarm => [
          _r(['SCHEDULE_EXACT_ALARM', 'USE_EXACT_ALARM']),
        ],
      OkapiPermission.photosAddOnly ||
      OkapiPermission.mediaLibrary ||
      OkapiPermission.criticalAlerts ||
      OkapiPermission.reminders ||
      OkapiPermission.appTrackingTransparency ||
      OkapiPermission.backgroundRefresh =>
        const [],
    };

/// Info.plist keys per permission.
List<Need> iosNeeds(OkapiPermission p) => switch (p) {
      OkapiPermission.camera => const [
          Need(['NSCameraUsageDescription']),
        ],
      OkapiPermission.microphone => const [
          Need(['NSMicrophoneUsageDescription']),
        ],
      OkapiPermission.speech => const [
          Need(['NSSpeechRecognitionUsageDescription']),
          Need(
            ['NSMicrophoneUsageDescription'],
            level: NeedLevel.recommended,
            note: 'speech recognition usually records audio',
          ),
        ],
      OkapiPermission.photos || OkapiPermission.videos => const [
          Need(['NSPhotoLibraryUsageDescription']),
        ],
      OkapiPermission.photosAddOnly => const [
          Need(['NSPhotoLibraryAddUsageDescription']),
        ],
      OkapiPermission.mediaLibrary => const [
          Need(['NSAppleMusicUsageDescription']),
        ],
      OkapiPermission.location || OkapiPermission.locationWhenInUse => const [
          Need(['NSLocationWhenInUseUsageDescription']),
        ],
      OkapiPermission.locationAlways => const [
          Need(['NSLocationWhenInUseUsageDescription']),
          Need(['NSLocationAlwaysAndWhenInUseUsageDescription']),
        ],
      OkapiPermission.contacts => const [
          Need(['NSContactsUsageDescription']),
        ],
      OkapiPermission.calendarFullAccess => const [
          Need(['NSCalendarsFullAccessUsageDescription']),
          Need(
            ['NSCalendarsUsageDescription'],
            level: NeedLevel.recommended,
            note: 'iOS 16 and below',
          ),
        ],
      OkapiPermission.calendarWriteOnly => const [
          Need([
            'NSCalendarsWriteOnlyAccessUsageDescription',
            'NSCalendarsFullAccessUsageDescription',
          ]),
          Need(
            ['NSCalendarsUsageDescription'],
            level: NeedLevel.recommended,
            note: 'iOS 16 and below',
          ),
        ],
      OkapiPermission.reminders => const [
          Need(['NSRemindersFullAccessUsageDescription']),
          Need(
            ['NSRemindersUsageDescription'],
            level: NeedLevel.recommended,
            note: 'iOS 16 and below',
          ),
        ],
      OkapiPermission.sensors || OkapiPermission.activityRecognition => const [
          Need(['NSMotionUsageDescription']),
        ],
      OkapiPermission.bluetooth ||
      OkapiPermission.bluetoothScan ||
      OkapiPermission.bluetoothConnect ||
      OkapiPermission.bluetoothAdvertise =>
        const [
          Need(['NSBluetoothAlwaysUsageDescription']),
        ],
      OkapiPermission.appTrackingTransparency => const [
          Need(['NSUserTrackingUsageDescription']),
        ],
      _ => const [],
    };

/// iOS compile flag families (see README "App Store tips").
const Map<String, List<OkapiPermission>> iosFamilies = {
  'CAMERA': [OkapiPermission.camera],
  'MICROPHONE': [OkapiPermission.microphone],
  'PHOTOS': [
    OkapiPermission.photos,
    OkapiPermission.videos,
    OkapiPermission.photosAddOnly,
  ],
  'LOCATION': [
    OkapiPermission.location,
    OkapiPermission.locationWhenInUse,
    OkapiPermission.locationAlways,
  ],
  'NOTIFICATIONS': [
    OkapiPermission.notification,
    OkapiPermission.criticalAlerts,
  ],
  'CONTACTS': [OkapiPermission.contacts],
  'CALENDAR': [
    OkapiPermission.calendarFullAccess,
    OkapiPermission.calendarWriteOnly,
    OkapiPermission.reminders,
  ],
  'SPEECH': [OkapiPermission.speech],
  'MEDIA_LIBRARY': [OkapiPermission.mediaLibrary],
  'TRACKING': [OkapiPermission.appTrackingTransparency],
  'SENSORS': [OkapiPermission.sensors, OkapiPermission.activityRecognition],
  'BLUETOOTH': [
    OkapiPermission.bluetooth,
    OkapiPermission.bluetoothScan,
    OkapiPermission.bluetoothConnect,
    OkapiPermission.bluetoothAdvertise,
  ],
};

/// Google Play policies that apply to a manifest permission.
const Map<String, String> playRestricted = {
  '${_a}SEND_SMS': 'SMS and Call Log policy',
  '${_a}RECEIVE_SMS': 'SMS and Call Log policy',
  '${_a}READ_SMS': 'SMS and Call Log policy',
  '${_a}RECEIVE_WAP_PUSH': 'SMS and Call Log policy',
  '${_a}RECEIVE_MMS': 'SMS and Call Log policy',
  '${_a}READ_CALL_LOG': 'SMS and Call Log policy',
  '${_a}WRITE_CALL_LOG': 'SMS and Call Log policy',
  '${_a}PROCESS_OUTGOING_CALLS': 'SMS and Call Log policy',
  '${_a}MANAGE_EXTERNAL_STORAGE': 'All files access policy',
  '${_a}ACCESS_BACKGROUND_LOCATION': 'Background location policy',
  '${_a}REQUEST_INSTALL_PACKAGES': 'Request install packages policy',
  '${_a}QUERY_ALL_PACKAGES': 'Package visibility (QUERY_ALL_PACKAGES) policy',
  '${_a}SCHEDULE_EXACT_ALARM': 'Exact alarm policy',
  '${_a}USE_EXACT_ALARM': 'Exact alarm policy',
  '${_a}READ_MEDIA_IMAGES': 'Photo and video permissions policy',
  '${_a}READ_MEDIA_VIDEO': 'Photo and video permissions policy',
  '${_a}BODY_SENSORS_BACKGROUND': 'Health apps policy',
  '${_a}REQUEST_IGNORE_BATTERY_OPTIMIZATIONS':
      'Battery optimisation exemption policy',
};

/// Example usage texts Sync puts in placeholders.
const Map<String, String> iosExamples = {
  'NSCameraUsageDescription': 'Scan QR codes and take profile photos.',
  'NSMicrophoneUsageDescription': 'Record voice notes for your friends.',
  'NSSpeechRecognitionUsageDescription': 'Turn what you say into search text.',
  'NSPhotoLibraryUsageDescription': 'Choose photos to share in chats.',
  'NSPhotoLibraryAddUsageDescription': 'Save tickets to your photo library.',
  'NSAppleMusicUsageDescription': 'Play songs from your music library.',
  'NSLocationWhenInUseUsageDescription': 'Show stores within 5 km of you.',
  'NSLocationAlwaysAndWhenInUseUsageDescription':
      'Remind you about a shop when you arrive nearby.',
  'NSContactsUsageDescription': 'Find friends who already use the app.',
  'NSCalendarsFullAccessUsageDescription':
      'Show your events next to your tasks.',
  'NSCalendarsWriteOnlyAccessUsageDescription':
      'Add your bookings to your calendar.',
  'NSCalendarsUsageDescription': 'Add your bookings to your calendar.',
  'NSRemindersFullAccessUsageDescription': 'Turn your tasks into reminders.',
  'NSRemindersUsageDescription': 'Turn your tasks into reminders.',
  'NSMotionUsageDescription': 'Count your steps during workouts.',
  'NSBluetoothAlwaysUsageDescription': 'Connect to your fitness band.',
  'NSUserTrackingUsageDescription': 'Show you ads that match your interests.',
};

/// Every manifest permission Okapi knows about.
Set<String> get knownAndroidNames => {
      for (final p in OkapiPermission.values)
        for (final n in androidNeeds(p)) ...n.names,
    };
