// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted.

/// Phone makers whose battery and autostart rules Okapi knows about.
enum OkapiOemBrand {
  /// Xiaomi, Redmi and POCO (MIUI / HyperOS).
  xiaomi,

  /// Samsung (One UI).
  samsung,

  /// OPPO (ColorOS).
  oppo,

  /// realme (realme UI).
  realme,

  /// OnePlus (OxygenOS / ColorOS).
  oneplus,

  /// vivo (Funtouch OS / OriginOS).
  vivo,

  /// iQOO.
  iqoo,

  /// Huawei (EMUI / HarmonyOS).
  huawei,

  /// Honor (MagicOS).
  honor,

  /// Motorola.
  motorola,

  /// Nokia / HMD.
  nokia,

  /// ASUS (ZenUI / ROG UI).
  asus,

  /// TECNO (HiOS).
  tecno,

  /// Infinix (XOS).
  infinix,

  /// itel.
  itel,

  /// Google Pixel.
  google,

  /// Apple (iPhone, iPad).
  apple,

  /// Anything else.
  other;

  /// Brands known to stop apps in the background unless the user allows it
  /// (autostart, battery saver, "sleeping apps").
  bool get restrictsBackground => switch (this) {
        xiaomi ||
        samsung ||
        oppo ||
        realme ||
        oneplus ||
        vivo ||
        iqoo ||
        huawei ||
        honor ||
        asus ||
        tecno ||
        infinix ||
        itel ||
        nokia =>
          true,
        _ => false,
      };

  /// Name shown to users.
  String get displayName => switch (this) {
        xiaomi => 'Xiaomi',
        samsung => 'Samsung',
        oppo => 'OPPO',
        realme => 'realme',
        oneplus => 'OnePlus',
        vivo => 'vivo',
        iqoo => 'iQOO',
        huawei => 'Huawei',
        honor => 'Honor',
        motorola => 'Motorola',
        nokia => 'Nokia',
        asus => 'ASUS',
        tecno => 'TECNO',
        infinix => 'Infinix',
        itel => 'itel',
        google => 'Google',
        apple => 'Apple',
        other => 'Android',
      };
}

/// Hidden system screens Okapi can open on some phones.
enum OkapiOemScreen {
  /// The maker's "Autostart" / "Auto-launch" / "App launch" list.
  autostart,

  /// The maker's battery-saver exception screen, or Android's own
  /// "Battery optimisation" list when the maker has none.
  battery,
}

/// Whether Android may remove this app's permissions when it is unused.
enum OkapiAutoResetStatus {
  /// The feature doesn't exist on this phone (iOS, or Android 5 and below
  /// without Google Play services support).
  notAvailable,

  /// The user turned it off for this app: permissions are kept.
  exempt,

  /// Android may remove permissions after a few months without use.
  enabled,

  /// The system didn't answer.
  unknown;

  /// Decodes the integer sent by the native side.
  static OkapiAutoResetStatus fromCode(int? code) => switch (code) {
        0 => notAvailable,
        1 => exempt,
        2 => enabled,
        _ => unknown,
      };
}

/// Basic facts about the phone, read from the system. Contains nothing that
/// identifies the user or the device.
class OkapiDeviceInfo {
  /// Creates device info.
  const OkapiDeviceInfo({
    required this.platform,
    required this.manufacturer,
    required this.brand,
    required this.model,
    required this.osVersion,
    required this.sdkInt,
    required this.appName,
  });

  /// Placeholder used before the native side answers, and on web/desktop.
  const OkapiDeviceInfo.unknown()
      : platform = 'other',
        manufacturer = '',
        brand = '',
        model = '',
        osVersion = '',
        sdkInt = 0,
        appName = 'this app';

  /// Builds info from the map sent by the native side.
  factory OkapiDeviceInfo.fromMap(Map<Object?, Object?> m) => OkapiDeviceInfo(
        platform: (m['platform'] as String?) ?? 'other',
        manufacturer: (m['manufacturer'] as String?) ?? '',
        brand: (m['brand'] as String?) ?? '',
        model: (m['model'] as String?) ?? '',
        osVersion: (m['osVersion'] as String?) ?? '',
        sdkInt: (m['sdkInt'] as int?) ?? 0,
        appName: ((m['appName'] as String?)?.trim().isNotEmpty ?? false)
            ? (m['appName'] as String).trim()
            : 'this app',
      );

  /// `android`, `ios` or `other`.
  final String platform;

  /// Android `Build.MANUFACTURER` (for example `Xiaomi`), or `Apple`.
  final String manufacturer;

  /// Android `Build.BRAND` (for example `Redmi`), or `Apple`.
  final String brand;

  /// Model name, for example `23049PCD8I`.
  final String model;

  /// OS version, for example `14`.
  final String osVersion;

  /// Android API level (0 on iOS).
  final int sdkInt;

  /// The app's display name, used in texts such as "Keep {app} working".
  final String appName;

  /// Whether this is an Android phone.
  bool get isAndroid => platform == 'android';

  /// Whether this is an iPhone or iPad.
  bool get isIOS => platform == 'ios';

  /// The detected phone maker.
  OkapiOemBrand get oem {
    if (isIOS) return OkapiOemBrand.apple;
    final b = '${brand.toLowerCase()} ${manufacturer.toLowerCase()}';
    bool has(String s) => b.contains(s);
    if (has('xiaomi') || has('redmi') || has('poco')) return OkapiOemBrand.xiaomi;
    if (has('samsung')) return OkapiOemBrand.samsung;
    if (has('oneplus')) return OkapiOemBrand.oneplus;
    if (has('realme')) return OkapiOemBrand.realme;
    if (has('oppo')) return OkapiOemBrand.oppo;
    if (has('iqoo')) return OkapiOemBrand.iqoo;
    if (has('vivo')) return OkapiOemBrand.vivo;
    if (has('honor')) return OkapiOemBrand.honor;
    if (has('huawei')) return OkapiOemBrand.huawei;
    if (has('motorola') || has('moto')) return OkapiOemBrand.motorola;
    if (has('nokia') || has('hmd')) return OkapiOemBrand.nokia;
    if (has('asus')) return OkapiOemBrand.asus;
    if (has('tecno')) return OkapiOemBrand.tecno;
    if (has('infinix')) return OkapiOemBrand.infinix;
    if (has('itel')) return OkapiOemBrand.itel;
    if (has('google')) return OkapiOemBrand.google;
    return OkapiOemBrand.other;
  }

  /// A copy with the maker replaced; used by the debug panel to preview the
  /// guide for other brands.
  OkapiDeviceInfo withBrand(OkapiOemBrand b) => OkapiDeviceInfo(
        platform: 'android',
        manufacturer: b.displayName,
        brand: b.displayName,
        model: model,
        osVersion: osVersion,
        sdkInt: sdkInt == 0 ? 34 : sdkInt,
        appName: appName,
      );

  @override
  String toString() =>
      'OkapiDeviceInfo($platform, $manufacturer/$brand $model, OS $osVersion, '
      'SDK $sdkInt, oem: ${oem.name})';
}

/// Step-by-step instructions for each phone maker. `{app}` is replaced with
/// the app's name. Override any brand through `OkapiStrings.oemSteps`.
const Map<OkapiOemBrand, List<String>> okapiDefaultOemSteps = {
  OkapiOemBrand.xiaomi: [
    'Tap Open settings.',
    'Find {app} in the Autostart list and turn it on.',
    'Then open Settings › Apps › {app} › Battery saver and choose No restrictions.',
  ],
  OkapiOemBrand.samsung: [
    'Tap Open settings.',
    'Open Background usage limits.',
    'Remove {app} from Sleeping apps and Deep sleeping apps.',
    'Add {app} to Never sleeping apps.',
  ],
  OkapiOemBrand.oppo: [
    'Tap Open settings.',
    'Turn on Auto launch for {app}.',
    'Then open Settings › Battery › {app} and allow background activity.',
  ],
  OkapiOemBrand.realme: [
    'Tap Open settings.',
    'Turn on Auto launch for {app}.',
    'Then open Settings › Battery › {app} and allow background activity.',
  ],
  OkapiOemBrand.oneplus: [
    'Tap Open settings.',
    'Turn on Auto launch for {app}.',
    'Then open Settings › Battery › Battery optimisation, choose {app} and select Don\'t optimise.',
  ],
  OkapiOemBrand.vivo: [
    'Tap Open settings.',
    'Turn on Autostart (Background start) for {app}.',
    'Then open Settings › Battery › Background power consumption and allow {app}.',
  ],
  OkapiOemBrand.iqoo: [
    'Tap Open settings.',
    'Turn on Autostart (Background start) for {app}.',
    'Then open Settings › Battery › Background power consumption and allow {app}.',
  ],
  OkapiOemBrand.huawei: [
    'Tap Open settings.',
    'Find {app} in App launch.',
    'Turn off Manage automatically, then turn on Auto-launch, Secondary launch and Run in background.',
  ],
  OkapiOemBrand.honor: [
    'Tap Open settings.',
    'Find {app} in App launch.',
    'Turn off Manage automatically, then turn on Auto-launch, Secondary launch and Run in background.',
  ],
  OkapiOemBrand.asus: [
    'Tap Open settings.',
    'Allow {app} in Auto-start Manager.',
  ],
  OkapiOemBrand.tecno: [
    'Tap Open settings.',
    'Turn on Auto start for {app} in Phone Master.',
    'Then set Battery for {app} to No restrictions.',
  ],
  OkapiOemBrand.infinix: [
    'Tap Open settings.',
    'Turn on Auto start for {app} in Phone Master.',
    'Then set Battery for {app} to No restrictions.',
  ],
  OkapiOemBrand.itel: [
    'Tap Open settings.',
    'Turn on Auto start for {app} in Phone Master.',
    'Then set Battery for {app} to No restrictions.',
  ],
  OkapiOemBrand.nokia: [
    'Tap Open settings.',
    'Turn off battery protection for {app}.',
  ],
  OkapiOemBrand.other: [
    'Tap Open settings.',
    'Choose {app}.',
    'Select Unrestricted (or Don\'t optimise).',
  ],
};
