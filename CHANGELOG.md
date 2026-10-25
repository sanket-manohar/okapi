## 1.0.0 — 2026-10-25

First release of Okapi.

**Permissions**
- 37 permissions across Android and iOS, including Android special app access
  (overlay, battery, exact alarms, all files, install apps, Do Not Disturb).
- Guided `Okapi.ask` and `Okapi.askAll` flows: rationale, system dialog,
  retry, Settings guidance and automatic re-check on return.
- Accurate permanent-denial detection on Android (dismissed dialogs are not
  treated as "don't ask again").
- Declaration checks with copy-paste fixes, automatic request queueing,
  foreground-before-background ordering, ATT "wait until active",
  Location/Bluetooth service checks.
- Live `statusChanges` and `watch` streams; re-check on app resume.

**Smarter asking**
- Feature-based asking: `OkapiFeature`, `Okapi.askFeature`,
  `Okapi.featureStatus`, `OkapiFeatureGate`, `OkapiFeatureBuilder`, with
  full / partial / unavailable levels and optional permissions.
- Ask policy (`OkapiAskPolicy`): first-launch skip, cooldowns after
  "Not now", refusal and declined Settings, per-session limit, `force` to
  bypass. New outcome `OkapiOutcome.deferredByPolicy`.

**Reliability**
- Background reliability guide for Xiaomi, Samsung, OPPO, realme, OnePlus,
  vivo, iQOO, Huawei, Honor, ASUS, TECNO, Infinix, itel and Nokia: brand
  detection, brand-specific steps, hidden autostart/battery screens with safe
  fallbacks, user confirmation.
- Auto-reset protection: `Okapi.autoResetStatus`, `protectFromAutoReset`,
  `revokedSinceLastLaunch`.

**UI**
- Presenters: bottom sheet, dialog, full screen, mixed, no-UI, function and
  fully custom (`OkapiCustomPresenter` with a controller).
- Widgets: `OkapiPermissionGate`, `OkapiPermissionBuilder`,
  `OkapiPermissionTile`, `OkapiStatusChip`, `OkapiOnboarding`,
  `OkapiPrivacyCenter`, `OkapiStepList`, `OkapiTag`.
- `OkapiThemeData` with light, dark, mono and app-derived presets.
- English, Hindi and Marathi strings.

**Developer tools**
- `dart run okapi:doctor`: checks manifest, Info.plist, Podfile, Play
  restricted permissions, vague iOS texts; `--json` and `--strict` for CI.
- `dart run okapi:sync`: writes missing declarations into a managed region;
  `--dry-run`, `--with-optional`, `--no-podfile`, `--ios-keep`.
- `OkapiDebugPanel`: simulate any permission state on a device (debug builds
  only); `OkapiDevOverrides` / `OkapiDevPlatform`.
- `FakeOkapiPlatform` and `fakeAndroidDevice` for tests.

**Privacy and legal**
- Apple privacy manifest; zero third-party dependencies; no network calls.
- Released under the BSD 3-Clause license with a Trademark Policy for the
  Okapi name and logo, plus Terms of Use, Legal Disclaimer, Privacy Notice and Trademark Policy.
