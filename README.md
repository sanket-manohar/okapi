<p align="center">
  <img src="https://raw.githubusercontent.com/sanket-manohar/okapi/main/assets/banner.png" alt="Okapi: the complete permission manager for Flutter" width="100%">
</p>

<p align="center">
  <b>Ask once. Ask right. Never get stuck.</b><br>
  The complete permission manager for Flutter on Android and iOS.
</p>

<p align="center">
  <a href="https://pub.dev/packages/okapi"><img src="https://img.shields.io/pub/v/okapi.svg?label=pub.dev&color=5A2A1E" alt="pub.dev"></a>
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20iOS-5A2A1E" alt="Android | iOS">
  <img src="https://img.shields.io/badge/license-BSD--3--Clause-5A2A1E" alt="License">
</p>

---

**Okapi** checks, requests and *guides* users through every Android and iOS permission. It ships the whole flow most apps rebuild by hand: a friendly explanation before the system dialog, a retry after a refusal, a clear path to Settings when a permission is blocked, and an automatic re-check when the user comes back. All of it with beautiful, fully customisable UI, or your own widgets.

```dart
final result = await Okapi.ask(context, OkapiPermission.camera);
if (result.isGranted) openCamera();
```

## Why Okapi

| Common problem | What Okapi does |
|---|---|
| The one-shot system dialog is wasted because users don't know why you ask | Shows a rationale screen first, so "Not now" costs nothing |
| "Permanently denied" apps get stuck forever | Detects it, explains how to fix it, opens Settings and re-checks on return |
| Android reports "permanently denied" when the user just dismissed the dialog | Compares the rationale flag before and after each request to tell them apart |
| `A request for permissions is already running` crashes | Every request and flow is queued automatically |
| iOS crashes when an `Info.plist` key is missing; Android fails silently | Okapi checks first and throws an `OkapiException` with the exact lines to paste |
| Background location requested in the wrong order | Foreground first, then background, handled for you |
| The ATT dialog never shows on app launch | Okapi waits until the app is active |
| Location or Bluetooth is switched off | Okapi notices and offers to turn it on |
| Status goes stale after the user changes Settings | Every known permission is re-checked when the app resumes, with a live stream |
| Packages declare permissions you never use | Okapi declares **none**; you add only what you need |
| Hard to test | `FakeOkapiPlatform` for unit tests and a debug panel to simulate any state on a device |
| Missing or extra manifest / Info.plist entries found only after a store rejection | `dart run okapi:doctor` checks everything, `dart run okapi:sync` writes it for you |
| Notifications and alarms die on Xiaomi, vivo, OPPO, Samsung and other phones | A brand-aware guide opens the right hidden autostart and battery screens |
| Android silently removes permissions from apps unused for a few months | Okapi spots removed permissions and offers to turn auto-reset off |
| Apps nag users until they refuse forever | An on-device ask policy: cooldowns, first-launch skip, per-session limit |
| Code juggles many permissions for one feature | Ask for a feature; Okapi returns full, partial or unavailable |

Also included: 37 permissions, a ready-made Privacy Center screen, Android special app-access screens, iOS limited/provisional states, Hindi and Marathi translations, an Apple privacy manifest, zero third-party dependencies.

## Contents

1. [Install](#install)
2. [Platform setup](#platform-setup)
3. [Quick start](#quick-start)
4. [Statuses](#statuses)
5. [Guided flows](#guided-flows)
6. [Low-level API](#low-level-api)
7. [Customise the UI](#customise-the-ui)
8. [Ready-made widgets](#ready-made-widgets)
9. [Ask for features](#ask-for-features)
10. [Ask policy](#ask-policy)
11. [Background reliability on Indian phones](#background-reliability-on-indian-phones)
12. [Auto-reset protection](#auto-reset-protection)
13. [Privacy Center](#privacy-center)
14. [Okapi Doctor and Okapi Sync](#okapi-doctor-and-okapi-sync)
15. [Debug panel](#debug-panel)
16. [Testing](#testing)
17. [Permission reference](#permission-reference)
18. [App Store and Play tips](#app-store-and-play-tips)
19. [Troubleshooting](#troubleshooting)
20. [Legal](#legal)

## Install

```yaml
dependencies:
  okapi: ^1.0.0
```

```bash
flutter pub get
```

Requires Flutter 3.27+, Android 5.0+ (API 21), iOS 12+.

## Platform setup

### Android

Add only the permissions you use to `android/app/src/main/AndroidManifest.xml`, above `<application>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

Set `compileSdk` to at least 35 in `android/app/build.gradle`. See the [Permission reference](#permission-reference) for every name. Not sure? Call `OkapiDeclarations.hint(OkapiPermission.photos, isIOS: false)` to print the exact lines.

### iOS

Add a usage description for each permission to `ios/Runner/Info.plist`. Write real, specific reasons: Apple rejects vague ones.

```xml
<key>NSCameraUsageDescription</key>
<string>Scan receipts and take profile photos.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Show stores near you.</string>
```

Optional but recommended: strip the APIs you don't use (see [App Store tips](#app-store-and-play-tips)).

## Quick start

```dart
import 'package:okapi/okapi.dart';

void main() {
  Okapi.configure(const OkapiConfig()); // Optional: sensible defaults.
  runApp(const MyApp());
}

// In any widget:
Future<void> scan(BuildContext context) async {
  final result = await Okapi.ask(
    context,
    OkapiPermission.camera,
    reason: 'We use the camera to scan your receipts.',
  );
  if (result.isGranted) {
    // Start scanning.
  }
}
```

## Statuses

| `OkapiStatus` | Meaning | `canProceed` |
|---|---|---|
| `granted` | Fully allowed | ✅ |
| `limited` | Partly allowed (selected photos, approximate location, limited contacts) | ✅ |
| `provisional` | iOS quiet notifications | ✅ |
| `notApplicable` | No permission needed on this platform/version | ✅ |
| `denied` | Not allowed yet; you can ask | ❌ |
| `permanentlyDenied` | Can only be changed in Settings | ❌ |
| `restricted` | Blocked by parental/MDM controls; the user can't change it | ❌ |

Use `status.canProceed` for "can I use the feature now?".

## Guided flows

### One permission

```dart
final r = await Okapi.ask(context, OkapiPermission.location);

final message = switch (r.outcome) {
  OkapiOutcome.granted => 'Ready',
  OkapiOutcome.dismissedRationale => 'Tapped "Not now" on Okapi\'s screen',
  OkapiOutcome.denied => 'Refused in the system dialog',
  OkapiOutcome.permanentlyDenied => 'Blocked; did not go to Settings',
  OkapiOutcome.settingsReturnedDenied => 'Went to Settings, still off',
  OkapiOutcome.restricted => 'Blocked by device restrictions',
  OkapiOutcome.serviceDisabled => 'Location / Bluetooth is switched off',
  OkapiOutcome.deferredByPolicy => 'Postponed by the ask policy',
};
```

The flow: declared? → service on? → already granted? → rationale → system dialog → retry → Settings → re-check on return. Every step can be turned off:

```dart
await Okapi.ask(
  context,
  OkapiPermission.microphone,
  rationaleMode: OkapiRationaleMode.whenRecommended,
  maxRetries: 0,
  offerSettings: true,
  settingsRightAfterRefusal: false,
  checkService: false,
);
```

### Several permissions

```dart
final results = await Okapi.askAll(context, [
  OkapiPermission.camera,
  OkapiPermission.microphone,
], reasons: {
  OkapiPermission.camera: 'See each other on video calls.',
  OkapiPermission.microphone: 'Hear each other on calls.',
});
```

One explanation lists them all, the system dialogs follow one by one, and blocked ones share one Settings prompt.

## Low-level API

```dart
final s = await Okapi.status(OkapiPermission.contacts);
final r = await Okapi.request(OkapiPermission.contacts);
final m = await Okapi.requestMany([OkapiPermission.camera, OkapiPermission.photos]);
final why = await Okapi.shouldShowRationale(OkapiPermission.camera); // Android
final svc = await Okapi.serviceStatus(OkapiPermission.location);
await Okapi.openAppSettings();
await Okapi.openServiceSettings(OkapiPermission.bluetooth);

Okapi.watch(OkapiPermission.notification).listen((s) => print(s));
Okapi.statusChanges.listen((change) => print(change));
```

## Customise the UI

### Theme

Okapi blends into your app's `ColorScheme` by default. Pick a preset or tweak anything:

```dart
Okapi.configure(OkapiConfig(
  theme: OkapiThemeData.okapiDark().copyWith(radius: 20, blurSigma: 10),
));
```

Presets: `fromColorScheme`, `okapiLight`, `okapiDark`, `mono`. You can also add `OkapiThemeData` to `ThemeData.extensions` or wrap a subtree in `OkapiTheme`.

Replace the icon badge with any widget (Lottie, image, illustration):

```dart
OkapiThemeData.okapiLight().copyWith(
  visualBuilder: (context, permission, theme) =>
      Image.asset('assets/${permission.name}.png', height: 120),
)
```

### Presentation style

```dart
OkapiConfig(presenter: const OkapiSheetPresenter());      // Default bottom sheet
OkapiConfig(presenter: const OkapiDialogPresenter());     // Centred dialog
OkapiConfig(presenter: const OkapiFullScreenPresenter()); // Full page
OkapiConfig(presenter: const OkapiNoUiPresenter());       // Logic only, no Okapi screens
OkapiConfig(presenter: const OkapiMixedPresenter(byKind: {
  OkapiPromptKind.rationale: OkapiFullScreenPresenter(),
  OkapiPromptKind.settings: OkapiDialogPresenter(),
}));
```

### Your own widgets, Okapi's logic

```dart
Okapi.configure(OkapiConfig(
  presenter: OkapiCustomPresenter(
    style: OkapiPresentationStyle.dialog,
    builder: (context, prompt, c) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(c.iconOf(prompt.permission), size: 48),
        Text(prompt.title),
        Text(prompt.message),
        FilledButton(onPressed: c.accept, child: Text(prompt.primaryLabel)),
        if (prompt.secondaryLabel != null)
          TextButton(onPressed: c.decline, child: Text(prompt.secondaryLabel!)),
      ],
    ),
  ),
));
```

The `OkapiPromptController` gives you `accept()`, `decline()`, `openSettings()`, `status()`, `nameOf()`, `iconOf()`, `strings` and `theme`. Use `builders: {OkapiPromptKind.settings: ...}` to customise only some screens, `wrapInFrame: false` to draw the whole container, or `OkapiFunctionPresenter` to show your own route entirely.

### Text and languages

```dart
Okapi.configure(const OkapiConfig(strings: OkapiStrings.hindi)); // or .marathi

Okapi.configure(OkapiConfig(
  strings: OkapiStrings(
    permissionReasons: {OkapiPermission.camera: 'Scan QR codes to pay.'},
    rationaleAllow: 'Sounds good',
  ),
  promptOverride: (p) => p.kind == OkapiPromptKind.settings
      ? p.copyWith(title: 'One quick switch in Settings')
      : p,
));
```

Templates support `{permission}`, `{reason}` and `{service}`.

### Analytics hooks

```dart
class MyObserver extends OkapiObserver {
  @override
  void onResult(OkapiResult r) => analytics.log('perm_${r.permission.name}', r.outcome.name);
}
Okapi.configure(OkapiConfig(observers: [MyObserver()]));
```

## Ready-made widgets

```dart
// Show the child only when allowed; otherwise a polished "Allow" card.
OkapiPermissionGate(
  permission: OkapiPermission.camera,
  reason: 'Point at a QR code to pay.',
  child: const ScannerView(),
);

// Build anything from the live status.
OkapiPermissionBuilder(
  permission: OkapiPermission.notification,
  builder: (context, status, ask) => SwitchListTile(
    title: const Text('Notifications'),
    value: status?.canProceed ?? false,
    onChanged: (_) => ask(),
  ),
);

// A row with icon, name, reason and an Allow button or status chip.
const OkapiPermissionTile(permission: OkapiPermission.contacts);

// A full onboarding screen.
OkapiOnboarding(
  permissions: const [OkapiPermission.notification, OkapiPermission.location],
  requiredPermissions: const [OkapiPermission.notification],
  onComplete: (statuses) => Navigator.of(context).pushReplacementNamed('/home'),
);
```

## Ask for features

Describe what a feature needs; Okapi asks in one flow, marks optional permissions, and tells you how much can run.

```dart
const videoCall = OkapiFeature(
  id: 'video_call',
  name: 'Video calls',
  required: [OkapiPermission.camera, OkapiPermission.microphone],
  optional: [OkapiPermission.bluetoothConnect],
);

final r = await Okapi.askFeature(context, videoCall);
switch (r.level) {
  case OkapiFeatureLevel.full:        startCall();
  case OkapiFeatureLevel.partial:     startCall(headset: false);
  case OkapiFeatureLevel.unavailable: showWhyCallsNeedCamera();
}
```

Also: `Okapi.featureStatus(feature)` (no UI), `OkapiFeatureGate(feature:, child:, partialChild:)` and `OkapiFeatureBuilder`.

## Ask policy

Stop nagging with rules that run on the device only:

```dart
Okapi.configure(const OkapiConfig(askPolicy: OkapiAskPolicy.recommended));
```

`recommended` skips the first launch, waits 2 days after "Not now", 7 days after a refusal, 14 days after the user declined Settings, and allows 2 Okapi prompts per session. Tune any rule with `OkapiAskPolicy(...)` or `.copyWith(...)`. A postponed flow returns `OkapiOutcome.deferredByPolicy` with the reason in `result.policy`. When the user explicitly asks (taps a switch), pass `force: true`.

## Background reliability on Indian phones

Xiaomi, Redmi, POCO, vivo, iQOO, OPPO, realme, OnePlus, Samsung, TECNO, Infinix, itel, Huawei, Honor, ASUS and Nokia phones can stop apps in the background, so notifications and alarms arrive late or never. Okapi detects the brand, shows brand-specific steps, opens the right hidden autostart or battery screen (with safe fallbacks), and asks the user to confirm.

```dart
final r = await Okapi.askBackgroundReliability(
  context,
  reason: 'So your medicine reminders ring on time.',
);
if (r.ready) scheduleReminders();
```

Ask at a meaningful moment (after the user creates their first reminder), not at launch. Phones don't let apps read the autostart switch, so `autostartConfirmed` is the user's answer. Declare `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` if your app qualifies under Play policy to also handle Android's battery optimisation directly. Low level: `Okapi.deviceInfo()`, `Okapi.oemScreens()`, `Okapi.openOemScreen(...)`, `Okapi.backgroundStatus()`, `Okapi.needsBackgroundSetup()`. Override the steps per brand with `OkapiStrings(oemSteps: {...})`.

## Auto-reset protection

Android removes permissions from apps that aren't opened for a few months. Okapi remembers which permissions were allowed, spots removed ones, and offers to turn auto-reset off:

```dart
// Gentle: only when something was actually removed.
await Okapi.protectFromAutoReset(context, onlyIfRevoked: true);

final removed = await Okapi.revokedSinceLastLaunch();
final status = await Okapi.autoResetStatus(); // enabled, exempt, notAvailable
```

## Privacy Center

A ready-made screen for your app's settings: features and permissions with live status and reasons, Allow and Manage buttons, plus background and auto-reset cards on Android.

```dart
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => OkapiPrivacyCenter(
    features: [videoCall],
    permissions: [OkapiPermission.notification],
    onOpenPrivacyPolicy: () => openMyPolicyPage(),
  ),
));
```

Set `asPage: false` to embed it in your own page.

## Okapi Doctor and Okapi Sync

Run these from your app folder.

```bash
dart run okapi:doctor          # check everything
dart run okapi:sync --dry-run  # preview the fixes
dart run okapi:sync            # write them
```

**Doctor** scans `lib/` for `OkapiPermission` usage and reports:

- permissions missing from AndroidManifest.xml or Info.plist, with the exact lines to paste;
- declared permissions your code never asks for;
- Google Play restricted permissions (SMS, call log, all files, background location, exact alarms, photos and videos...);
- vague or placeholder iOS usage texts Apple tends to reject;
- iOS permission APIs that are compiled in but unused, or excluded but used;
- `compileSdk` and iOS deployment target problems.

Add `--json` for CI and `--strict` to fail on warnings.

**Sync** writes what's missing into a marked region (`okapi:begin` / `okapi:end`) of AndroidManifest.xml, Info.plist and the Podfile. It never touches anything outside that region, keeps the Info.plist texts you edit, and removes entries when you stop using a permission. iOS texts start as `TODO:` placeholders; Doctor reports them until you replace them.

If your code chooses permissions at runtime (`OkapiPermission.values`, `.byName`), list them in pubspec.yaml so both tools can see them:

```yaml
okapi:
  permissions: [contacts, calendarFullAccess]
  ios_keep: [BLUETOOTH]   # never exclude these iOS APIs
  manage_podfile: true
```

## Debug panel

Simulate any permission state on a real device, without reinstalling or resetting the phone:

```dart
MaterialApp(
  builder: (context, child) => OkapiDebugPanel(child: child!),
);
```

A draggable button opens the panel. Set any permission to granted, denied, blocked, limited or restricted; switch Location or Bluetooth off; make the system dialog "allow"; preview the background guide for Xiaomi, Samsung, vivo and more; simulate auto-reset; and clear the ask history. It is active only in debug builds and returns your app untouched in profile and release builds.

## Testing

```dart
import 'package:okapi/okapi.dart';
import 'package:okapi/testing.dart';

setUp(() {
  OkapiPlatform.instance = FakeOkapiPlatform(
    statuses: {OkapiPermission.camera: OkapiStatus.denied},
    requestResults: {OkapiPermission.camera: OkapiStatus.granted},
  );
});
```

## Permission reference

| `OkapiPermission` | Android manifest | iOS Info.plist |
|---|---|---|
| `camera` | `CAMERA` | `NSCameraUsageDescription` |
| `microphone` | `RECORD_AUDIO` | `NSMicrophoneUsageDescription` |
| `speech` | `RECORD_AUDIO` | `NSSpeechRecognitionUsageDescription` |
| `photos` | `READ_MEDIA_IMAGES`, `READ_MEDIA_VISUAL_USER_SELECTED`, `READ_EXTERNAL_STORAGE` (max 32) | `NSPhotoLibraryUsageDescription` |
| `photosAddOnly` | n/a | `NSPhotoLibraryAddUsageDescription` |
| `videos` | `READ_MEDIA_VIDEO`, `READ_EXTERNAL_STORAGE` (max 32) | `NSPhotoLibraryUsageDescription` |
| `audio` | `READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE` (max 32) | n/a |
| `storage` | `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE` (max 28) | n/a |
| `manageExternalStorage` | `MANAGE_EXTERNAL_STORAGE` (special) | n/a |
| `mediaLocation` | `ACCESS_MEDIA_LOCATION` | n/a |
| `mediaLibrary` | n/a | `NSAppleMusicUsageDescription` |
| `location`, `locationWhenInUse` | `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | `NSLocationWhenInUseUsageDescription` |
| `locationAlways` | + `ACCESS_BACKGROUND_LOCATION` | + `NSLocationAlwaysAndWhenInUseUsageDescription` |
| `notification` | `POST_NOTIFICATIONS` | none |
| `criticalAlerts` | n/a | none (needs Apple entitlement) |
| `accessNotificationPolicy` | `ACCESS_NOTIFICATION_POLICY` (special) | n/a |
| `contacts` | `READ_CONTACTS`, `WRITE_CONTACTS` | `NSContactsUsageDescription` |
| `calendarFullAccess` | `READ_CALENDAR`, `WRITE_CALENDAR` | `NSCalendarsFullAccessUsageDescription` |
| `calendarWriteOnly` | `WRITE_CALENDAR` | `NSCalendarsWriteOnlyAccessUsageDescription` |
| `reminders` | n/a | `NSRemindersFullAccessUsageDescription` |
| `phone` | `READ_PHONE_STATE`, `CALL_PHONE`, … (any declared) | n/a |
| `sms` | `SEND_SMS`, `READ_SMS`, … (any declared) | n/a |
| `sensors` | `BODY_SENSORS` | `NSMotionUsageDescription` |
| `sensorsAlways` | + `BODY_SENSORS_BACKGROUND` | n/a |
| `activityRecognition` | `ACTIVITY_RECOGNITION` | `NSMotionUsageDescription` |
| `bluetooth` | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` | `NSBluetoothAlwaysUsageDescription` |
| `bluetoothScan` / `Connect` / `Advertise` | the matching `BLUETOOTH_*` | `NSBluetoothAlwaysUsageDescription` |
| `nearbyWifiDevices` | `NEARBY_WIFI_DEVICES` | n/a |
| `appTrackingTransparency` | n/a | `NSUserTrackingUsageDescription` |
| `ignoreBatteryOptimizations` | `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (special) | n/a |
| `systemAlertWindow` | `SYSTEM_ALERT_WINDOW` (special) | n/a |
| `requestInstallPackages` | `REQUEST_INSTALL_PACKAGES` (special) | n/a |
| `scheduleExactAlarm` | `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM` (special) | n/a |
| `backgroundRefresh` | n/a | none (read-only) |

"n/a" returns `OkapiStatus.notApplicable`. "Special" opens a system screen; Okapi re-checks when the user returns.

## App Store and Play tips

**iOS: exclude APIs you don't use.** Apple may flag apps that link permission APIs without a matching usage description. Okapi compiles every family by default; exclude the rest in `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    if target.name == 'okapi'
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] =
          '$(inherited) OKAPI_EXCLUDE_CONTACTS OKAPI_EXCLUDE_CALENDAR OKAPI_EXCLUDE_SPEECH'
      end
    end
  end
end
```

Flags: `OKAPI_EXCLUDE_CAMERA`, `_MICROPHONE`, `_PHOTOS`, `_LOCATION`, `_NOTIFICATIONS`, `_CONTACTS`, `_CALENDAR`, `_SPEECH`, `_MEDIA_LIBRARY`, `_TRACKING`, `_SENSORS`, `_BLUETOOTH`. Excluded permissions return `notApplicable`.

**Google Play:** SMS, call log, all-files access, background location, exact alarms and install-packages are restricted. Declare them only if your app qualifies, and complete Play Console's declarations.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `OkapiException(not_declared)` | Paste the lines from the message into the manifest / Info.plist, then do a full rebuild (not hot reload). |
| `no_activity` on Android | Ask after the first frame, from a visible screen. |
| Always `permanentlyDenied` on iOS after one refusal | That's iOS: it only ever shows the dialog once. Okapi guides the user to Settings. |
| `storage` is `notApplicable` on Android 13+ | Use `photos`, `videos` or `audio` instead. |
| Background location never asked | Ask `locationWhenInUse` first, or just ask `locationAlways`: Okapi orders it for you. |
| ATT dialog doesn't appear | Make sure `NSUserTrackingUsageDescription` is set; Okapi already waits for the app to be active. |

## Legal

- **License:** [BSD 3-Clause](LICENSE). Free to use in any app, including commercial apps. Keep the copyright notice when you redistribute the code.
- **Name and logo:** the BSD license covers the code only. A fork or modified copy must use a different name and logo and must not claim to be the official Okapi. See [TRADEMARKS.md](TRADEMARKS.md).
- **Terms:** [TERMS.md](TERMS.md).
- **Disclaimer:** Okapi is strictly a development package, not a decision-maker. It never decides which permissions an app requests, never accesses user data, and is not responsible for any permission requested or any data breach involving an app that uses it. Provided "as is", without any guarantee of results. See [DISCLAIMER.md](DISCLAIMER.md).
- **Privacy:** Okapi collects nothing. See [PRIVACY.md](PRIVACY.md).
- **Security:** see [SECURITY.md](SECURITY.md). **Contributing:** see [CONTRIBUTING.md](CONTRIBUTING.md).

Copyright © 2026 Sanket Santosh Vidya Manohar. "Okapi" and the Okapi logo are trademarks of Sanket Santosh Vidya Manohar.

## Author

**Sanket Santosh Vidya Manohar**

- Website: [sanketmanohar.com](https://sanketmanohar.com/)
- GitHub: [@sanket-manohar](https://github.com/sanket-manohar)
- pub.dev: [sanketmanohar.com packages](https://pub.dev/publishers/sanketmanohar.com/packages)
- Visual Studio Marketplace: [sanket-manohar](https://marketplace.visualstudio.com/publishers/sanket-manohar)

---

<p align="center">Okapi v1.0.0 · Made by <a href="https://sanketmanohar.com/">Sanket Santosh Vidya Manohar</a></p>
