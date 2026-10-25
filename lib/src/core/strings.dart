// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'device.dart';
import 'permission.dart';

/// Every piece of text Okapi shows. Ships with English, Hindi and Marathi.
///
/// Override any text by passing your own instance to `OkapiConfig.strings`,
/// or extend this class to add a new language.
class OkapiStrings {
  /// Creates a set of strings. Every argument is optional; anything you leave
  /// out falls back to English.
  const OkapiStrings({
    this.permissionNames = const {},
    this.permissionReasons = const {},
    this.rationaleTitle = 'Allow {permission}?',
    this.rationaleMessage = '{reason}',
    this.rationaleAllow = 'Continue',
    this.rationaleNotNow = 'Not now',
    this.deniedTitle = '{permission} is needed',
    this.deniedMessage = 'Without {permission}, this feature can\'t work. Would you like to try again?',
    this.deniedRetry = 'Try again',
    this.deniedCancel = 'Cancel',
    this.settingsTitle = 'Turn on {permission} in Settings',
    this.settingsMessage =
        '{permission} was turned off for this app. Open Settings, tap '
        'Permissions, and allow {permission}.',
    this.settingsOpen = 'Open Settings',
    this.settingsCancel = 'Not now',
    this.serviceTitle = '{service} is off',
    this.serviceMessage =
        'Turn on {service} on your device to use this feature.',
    this.serviceOpen = 'Turn on',
    this.serviceCancel = 'Cancel',
    this.restrictedTitle = '{permission} is restricted',
    this.restrictedMessage =
        'This permission is blocked by device restrictions (such as Screen '
        'Time or a work profile) and can\'t be changed here.',
    this.restrictedOk = 'OK',
    this.multiTitle = 'A few permissions to get started',
    this.multiMessage = 'Here is what this app needs and why.',
    this.multiAllow = 'Allow all',
    this.multiNotNow = 'Not now',
    this.statusGranted = 'Allowed',
    this.statusDenied = 'Not allowed',
    this.statusPermanentlyDenied = 'Blocked',
    this.statusRestricted = 'Restricted',
    this.statusLimited = 'Limited',
    this.statusProvisional = 'Quiet',
    this.statusNotApplicable = 'Not needed',
    this.allowButton = 'Allow',
    this.continueButton = 'Continue',
    this.stepSettings = 'Settings',
    this.stepPermissions = 'Permissions',
    this.locationService = 'Location Services',
    this.bluetoothService = 'Bluetooth',
    this.featureTitle = 'To use {feature}',
    this.featureMessage = 'Allow the following so {feature} works.',
    this.optionalLabel = 'Optional',
    this.backgroundTitle = 'Keep {app} working in the background',
    this.backgroundMessage = 'Your {brand} phone may pause {app} to save battery. Follow these steps so notifications and reminders arrive on time.',
    this.backgroundOpen = 'Open settings',
    this.backgroundNotNow = 'Not now',
    this.backgroundConfirmTitle = 'Did you turn it on?',
    this.backgroundConfirmMessage = 'Phones don\'t let apps check this setting. Did you allow {app} to start and run in the background?',
    this.backgroundConfirmYes = 'Yes, it\'s on',
    this.backgroundConfirmNo = 'Not yet',
    this.autoResetTitle = 'Keep {app}\'s permissions',
    this.autoResetMessage = 'Android removes permissions from apps you don\'t open for a few months. Turn this off so {app} keeps working.',
    this.autoResetRevokedMessage = 'Android removed {list} because {app} wasn\'t used for a while. Turn off auto-reset so it doesn\'t happen again.',
    this.autoResetSteps = const [
      'Tap Open settings.',
      'Turn off "Pause app activity if unused" (on some phones: "Remove permissions if app isn\'t used").',
    ],
    this.autoResetOpen = 'Open settings',
    this.autoResetNotNow = 'Not now',
    this.oemSteps = const {},
    this.privacyTitle = 'Privacy & permissions',
    this.privacyIntro = 'See what this app can access and why. You can change any of these at any time.',
    this.privacyFeatures = 'Features',
    this.privacyPermissions = 'Permissions',
    this.privacyBackground = 'Background activity',
    this.privacyBackgroundBody = '{brand} phones may pause apps to save battery. Allow {app} so reminders arrive on time.',
    this.privacyBackgroundAction = 'Set up',
    this.privacyAutoReset = 'Unused app protection',
    this.privacyAutoResetOn = 'Android may remove permissions if you don\'t open the app for a few months.',
    this.privacyAutoResetOff =
        'Permissions are kept even if you don\'t use the app for a while.',
    this.privacyAutoResetAction = 'Keep permissions',
    this.privacyProtected = 'Protected',
    this.privacyManageAll = 'Manage all in Settings',
    this.privacyPolicy = 'Privacy policy',
    this.manageButton = 'Manage',
    this.levelFull = 'On',
    this.levelPartial = 'Partly on',
    this.levelOff = 'Off',
  });

  /// Overrides for permission display names.
  final Map<OkapiPermission, String> permissionNames;

  /// Overrides for the "why we need it" sentence per permission.
  final Map<OkapiPermission, String> permissionReasons;

  // Templates. `{permission}`, `{reason}` and `{service}` are replaced.
  /// Rationale title template.
  final String rationaleTitle;

  /// Rationale message template.
  final String rationaleMessage;

  /// Rationale primary button.
  final String rationaleAllow;

  /// Rationale secondary button.
  final String rationaleNotNow;

  /// Denied title template.
  final String deniedTitle;

  /// Denied message template.
  final String deniedMessage;

  /// Denied primary button.
  final String deniedRetry;

  /// Denied secondary button.
  final String deniedCancel;

  /// Settings title template.
  final String settingsTitle;

  /// Settings message template.
  final String settingsMessage;

  /// Settings primary button.
  final String settingsOpen;

  /// Settings secondary button.
  final String settingsCancel;

  /// Service-disabled title template.
  final String serviceTitle;

  /// Service-disabled message template.
  final String serviceMessage;

  /// Service-disabled primary button.
  final String serviceOpen;

  /// Service-disabled secondary button.
  final String serviceCancel;

  /// Restricted title template.
  final String restrictedTitle;

  /// Restricted message template.
  final String restrictedMessage;

  /// Restricted button.
  final String restrictedOk;

  /// Multi-permission title.
  final String multiTitle;

  /// Multi-permission subtitle.
  final String multiMessage;

  /// Multi-permission primary button.
  final String multiAllow;

  /// Multi-permission secondary button.
  final String multiNotNow;

  /// Status label.
  final String statusGranted;

  /// Status label.
  final String statusDenied;

  /// Status label.
  final String statusPermanentlyDenied;

  /// Status label.
  final String statusRestricted;

  /// Status label.
  final String statusLimited;

  /// Status label.
  final String statusProvisional;

  /// Status label.
  final String statusNotApplicable;

  /// Generic allow button (tiles, gates).
  final String allowButton;

  /// Generic continue button (onboarding).
  final String continueButton;

  /// First crumb of the "Settings › Permissions › X" hint.
  final String stepSettings;

  /// Second crumb of the "Settings › Permissions › X" hint.
  final String stepPermissions;

  /// Name of the location service.
  final String locationService;

  /// Name of the Bluetooth service.
  final String bluetoothService;

  /// Feature prompt title. `{feature}` is replaced.
  final String featureTitle;

  /// Feature prompt message.
  final String featureMessage;

  /// Tag for optional permissions.
  final String optionalLabel;

  /// Background guide title. `{app}` and `{brand}` are replaced.
  final String backgroundTitle;

  /// Background guide message.
  final String backgroundMessage;

  /// Background guide primary button.
  final String backgroundOpen;

  /// Background guide secondary button.
  final String backgroundNotNow;

  /// Confirmation title after returning from the maker's screen.
  final String backgroundConfirmTitle;

  /// Confirmation message.
  final String backgroundConfirmMessage;

  /// Confirmation primary button.
  final String backgroundConfirmYes;

  /// Confirmation secondary button.
  final String backgroundConfirmNo;

  /// Auto-reset title.
  final String autoResetTitle;

  /// Auto-reset message.
  final String autoResetMessage;

  /// Auto-reset message when permissions were already removed. `{list}` is
  /// replaced with their names.
  final String autoResetRevokedMessage;

  /// Auto-reset steps.
  final List<String> autoResetSteps;

  /// Auto-reset primary button.
  final String autoResetOpen;

  /// Auto-reset secondary button.
  final String autoResetNotNow;

  /// Per-brand steps that replace [okapiDefaultOemSteps].
  final Map<OkapiOemBrand, List<String>> oemSteps;

  /// Privacy Center title.
  final String privacyTitle;

  /// Privacy Center intro.
  final String privacyIntro;

  /// Privacy Center section.
  final String privacyFeatures;

  /// Privacy Center section.
  final String privacyPermissions;

  /// Privacy Center card title.
  final String privacyBackground;

  /// Privacy Center card text.
  final String privacyBackgroundBody;

  /// Privacy Center card button.
  final String privacyBackgroundAction;

  /// Privacy Center card title.
  final String privacyAutoReset;

  /// Privacy Center text when auto-reset is on.
  final String privacyAutoResetOn;

  /// Privacy Center text when the app is protected.
  final String privacyAutoResetOff;

  /// Privacy Center button.
  final String privacyAutoResetAction;

  /// Privacy Center chip.
  final String privacyProtected;

  /// Privacy Center footer button.
  final String privacyManageAll;

  /// Privacy Center footer link.
  final String privacyPolicy;

  /// "Manage" button for granted permissions.
  final String manageButton;

  /// Feature level label.
  final String levelFull;

  /// Feature level label.
  final String levelPartial;

  /// Feature level label.
  final String levelOff;

  /// Steps for [brand], with `{app}` filled.
  List<String> stepsFor(OkapiOemBrand brand, String app) =>
      (oemSteps[brand] ??
              okapiDefaultOemSteps[brand] ??
              okapiDefaultOemSteps[OkapiOemBrand.other]!)
          .map((t) => t.replaceAll('{app}', app))
          .toList();

  /// Replaces `{key}` placeholders in [template] with [values].
  String fillWith(String template, Map<String, String> values) {
    var out = template;
    values.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out;
  }

  /// Display name for a permission.
  String nameOf(OkapiPermission p) =>
      permissionNames[p] ?? _defaultNames[p] ?? p.name;

  /// Reason sentence for a permission.
  String reasonOf(OkapiPermission p) =>
      permissionReasons[p] ??
      _defaultReasons[p] ??
      'This app needs ${nameOf(p).toLowerCase()} access for this feature.';

  /// Name of the service behind a permission.
  String serviceOf(OkapiPermission p) =>
      p.name.startsWith('bluetooth') ? bluetoothService : locationService;

  /// Fills `{permission}`, `{reason}` and `{service}` in [template].
  String fill(String template, OkapiPermission p) => template
      .replaceAll('{permission}', nameOf(p))
      .replaceAll('{reason}', reasonOf(p))
      .replaceAll('{service}', serviceOf(p));

  /// English (default).
  static const OkapiStrings english = OkapiStrings();

  /// Hindi.
  static const OkapiStrings hindi = OkapiStrings(
    permissionNames: _hiNames,
    rationaleTitle: '{permission} की अनुमति दें?',
    rationaleAllow: 'आगे बढ़ें',
    rationaleNotNow: 'अभी नहीं',
    deniedTitle: '{permission} ज़रूरी है',
    deniedMessage: '{permission} के बिना यह फ़ीचर काम नहीं करेगा। क्या आप फिर से कोशिश करना चाहेंगे?',
    deniedRetry: 'फिर से कोशिश करें',
    deniedCancel: 'रद्द करें',
    settingsTitle: 'सेटिंग्स में {permission} चालू करें',
    settingsMessage: 'इस ऐप के लिए {permission} बंद है। सेटिंग्स खोलें, अनुमतियाँ (Permissions) पर टैप करें और {permission} चालू करें।',
    settingsOpen: 'सेटिंग्स खोलें',
    settingsCancel: 'अभी नहीं',
    serviceTitle: '{service} बंद है',
    serviceMessage: 'इस फ़ीचर के लिए अपने डिवाइस पर {service} चालू करें।',
    serviceOpen: 'चालू करें',
    serviceCancel: 'रद्द करें',
    restrictedTitle: '{permission} प्रतिबंधित है',
    restrictedMessage: 'यह अनुमति डिवाइस प्रतिबंधों (जैसे Screen Time या वर्क प्रोफ़ाइल) के कारण बंद है और यहाँ से बदली नहीं जा सकती।',
    restrictedOk: 'ठीक है',
    multiTitle: 'शुरू करने के लिए कुछ अनुमतियाँ',
    multiMessage: 'ऐप को क्या चाहिए और क्यों, यहाँ देखें।',
    multiAllow: 'सभी की अनुमति दें',
    multiNotNow: 'अभी नहीं',
    statusGranted: 'अनुमति है',
    statusDenied: 'अनुमति नहीं',
    statusPermanentlyDenied: 'ब्लॉक',
    statusRestricted: 'प्रतिबंधित',
    statusLimited: 'सीमित',
    statusProvisional: 'शांत',
    statusNotApplicable: 'ज़रूरी नहीं',
    allowButton: 'अनुमति दें',
    continueButton: 'आगे बढ़ें',
    stepSettings: 'सेटिंग्स',
    stepPermissions: 'अनुमतियाँ',
    locationService: 'लोकेशन सेवाएँ',
    bluetoothService: 'ब्लूटूथ',
    featureTitle: '{feature} इस्तेमाल करने के लिए',
    featureMessage: '{feature} चलाने के लिए ये अनुमतियाँ दें।',
    optionalLabel: 'वैकल्पिक',
    backgroundTitle: '{app} को बैकग्राउंड में चालू रखें',
    backgroundMessage: 'आपका {brand} फ़ोन बैटरी बचाने के लिए {app} को रोक सकता है। नोटिफ़िकेशन और रिमाइंडर समय पर पाने के लिए ये स्टेप्स अपनाएँ।',
    backgroundOpen: 'सेटिंग्स खोलें',
    backgroundNotNow: 'अभी नहीं',
    backgroundConfirmTitle: 'क्या आपने इसे चालू किया?',
    backgroundConfirmMessage: 'फ़ोन ऐप्स को यह सेटिंग जाँचने नहीं देते। क्या आपने {app} को बैकग्राउंड में चलने की अनुमति दी?',
    backgroundConfirmYes: 'हाँ, चालू है',
    backgroundConfirmNo: 'अभी नहीं',
    autoResetTitle: '{app} की अनुमतियाँ बनाए रखें',
    autoResetMessage: 'कुछ महीनों तक न खोले गए ऐप्स की अनुमतियाँ Android हटा देता है। {app} ठीक से चलता रहे, इसके लिए इसे बंद करें।',
    autoResetRevokedMessage: '{app} कुछ समय इस्तेमाल न होने से Android ने {list} हटा दिया। दोबारा ऐसा न हो, इसके लिए ऑटो-रीसेट बंद करें।',
    autoResetSteps: [
      'सेटिंग्स खोलें पर टैप करें।',
      '"Pause app activity if unused" (या "Remove permissions if app isn\'t used") बंद करें।',
    ],
    autoResetOpen: 'सेटिंग्स खोलें',
    autoResetNotNow: 'अभी नहीं',
    privacyTitle: 'प्राइवेसी और अनुमतियाँ',
    privacyIntro: 'देखें कि यह ऐप क्या एक्सेस कर सकता है और क्यों। आप इन्हें कभी भी बदल सकते हैं।',
    privacyFeatures: 'फ़ीचर',
    privacyPermissions: 'अनुमतियाँ',
    privacyBackground: 'बैकग्राउंड गतिविधि',
    privacyBackgroundBody: '{brand} फ़ोन बैटरी बचाने के लिए ऐप्स रोक सकते हैं। रिमाइंडर समय पर पाने के लिए {app} को अनुमति दें।',
    privacyBackgroundAction: 'सेट करें',
    privacyAutoReset: 'अनयूज़्ड ऐप सुरक्षा',
    privacyAutoResetOn:
        'कुछ महीने ऐप न खोलने पर Android अनुमतियाँ हटा सकता है।',
    privacyAutoResetOff:
        'ऐप कुछ समय इस्तेमाल न होने पर भी अनुमतियाँ बनी रहेंगी।',
    privacyAutoResetAction: 'अनुमतियाँ बनाए रखें',
    privacyProtected: 'सुरक्षित',
    privacyManageAll: 'सेटिंग्स में सब मैनेज करें',
    privacyPolicy: 'प्राइवेसी पॉलिसी',
    manageButton: 'मैनेज करें',
    levelFull: 'चालू',
    levelPartial: 'आंशिक',
    levelOff: 'बंद',
  );

  /// Marathi.
  static const OkapiStrings marathi = OkapiStrings(
    permissionNames: _mrNames,
    rationaleTitle: '{permission} ची परवानगी द्यायची?',
    rationaleAllow: 'पुढे जा',
    rationaleNotNow: 'आत्ता नको',
    deniedTitle: '{permission} आवश्यक आहे',
    deniedMessage:
        '{permission} शिवाय हे फीचर चालणार नाही. पुन्हा प्रयत्न करायचा का?',
    deniedRetry: 'पुन्हा प्रयत्न करा',
    deniedCancel: 'रद्द करा',
    settingsTitle: 'सेटिंग्जमध्ये {permission} सुरू करा',
    settingsMessage: 'या ॲपसाठी {permission} बंद आहे. सेटिंग्ज उघडा, परवानग्या (Permissions) वर टॅप करा आणि {permission} सुरू करा.',
    settingsOpen: 'सेटिंग्ज उघडा',
    settingsCancel: 'आत्ता नको',
    serviceTitle: '{service} बंद आहे',
    serviceMessage: 'हे फीचर वापरण्यासाठी डिव्हाइसवर {service} सुरू करा.',
    serviceOpen: 'सुरू करा',
    serviceCancel: 'रद्द करा',
    restrictedTitle: '{permission} प्रतिबंधित आहे',
    restrictedMessage: 'ही परवानगी डिव्हाइसवरील निर्बंधांमुळे (जसे Screen Time किंवा वर्क प्रोफाइल) बंद आहे आणि इथून बदलता येत नाही.',
    restrictedOk: 'ठीक आहे',
    multiTitle: 'सुरुवात करण्यासाठी काही परवानग्या',
    multiMessage: 'ॲपला काय हवे आहे आणि का, ते इथे पहा.',
    multiAllow: 'सर्वांना परवानगी द्या',
    multiNotNow: 'आत्ता नको',
    statusGranted: 'परवानगी आहे',
    statusDenied: 'परवानगी नाही',
    statusPermanentlyDenied: 'ब्लॉक',
    statusRestricted: 'प्रतिबंधित',
    statusLimited: 'मर्यादित',
    statusProvisional: 'शांत',
    statusNotApplicable: 'गरज नाही',
    allowButton: 'परवानगी द्या',
    continueButton: 'पुढे जा',
    stepSettings: 'सेटिंग्ज',
    stepPermissions: 'परवानग्या',
    locationService: 'लोकेशन सेवा',
    bluetoothService: 'ब्लूटूथ',
    featureTitle: '{feature} वापरण्यासाठी',
    featureMessage: '{feature} चालण्यासाठी या परवानग्या द्या.',
    optionalLabel: 'ऐच्छिक',
    backgroundTitle: '{app} बॅकग्राउंडमध्ये चालू ठेवा',
    backgroundMessage: 'तुमचा {brand} फोन बॅटरी वाचवण्यासाठी {app} थांबवू शकतो. नोटिफिकेशन आणि रिमाइंडर वेळेवर मिळण्यासाठी या स्टेप्स करा.',
    backgroundOpen: 'सेटिंग्ज उघडा',
    backgroundNotNow: 'आत्ता नको',
    backgroundConfirmTitle: 'तुम्ही हे सुरू केले का?',
    backgroundConfirmMessage: 'फोन ॲप्सना ही सेटिंग तपासू देत नाहीत. तुम्ही {app} ला बॅकग्राउंडमध्ये चालण्याची परवानगी दिली का?',
    backgroundConfirmYes: 'हो, सुरू आहे',
    backgroundConfirmNo: 'अजून नाही',
    autoResetTitle: '{app} च्या परवानग्या टिकवा',
    autoResetMessage: 'काही महिने न उघडलेल्या ॲप्सच्या परवानग्या Android काढून टाकतो. {app} नीट चालण्यासाठी हे बंद करा.',
    autoResetRevokedMessage: '{app} काही काळ न वापरल्यामुळे Android ने {list} काढून टाकले. पुन्हा असे होऊ नये म्हणून ऑटो-रीसेट बंद करा.',
    autoResetSteps: [
      'सेटिंग्ज उघडा वर टॅप करा.',
      '"Pause app activity if unused" (किंवा "Remove permissions if app isn\'t used") बंद करा.',
    ],
    autoResetOpen: 'सेटिंग्ज उघडा',
    autoResetNotNow: 'आत्ता नको',
    privacyTitle: 'प्रायव्हसी आणि परवानग्या',
    privacyIntro:
        'हे ॲप काय ॲक्सेस करू शकते आणि का, ते पहा. तुम्ही हे कधीही बदलू शकता.',
    privacyFeatures: 'फीचर्स',
    privacyPermissions: 'परवानग्या',
    privacyBackground: 'बॅकग्राउंड ॲक्टिव्हिटी',
    privacyBackgroundBody: '{brand} फोन बॅटरी वाचवण्यासाठी ॲप्स थांबवू शकतात. रिमाइंडर वेळेवर मिळण्यासाठी {app} ला परवानगी द्या.',
    privacyBackgroundAction: 'सेट करा',
    privacyAutoReset: 'न वापरलेल्या ॲपचे संरक्षण',
    privacyAutoResetOn: 'काही महिने ॲप न उघडल्यास Android परवानग्या काढू शकतो.',
    privacyAutoResetOff: 'ॲप काही काळ न वापरले तरी परवानग्या टिकून राहतील.',
    privacyAutoResetAction: 'परवानग्या टिकवा',
    privacyProtected: 'सुरक्षित',
    privacyManageAll: 'सेटिंग्जमध्ये सर्व मॅनेज करा',
    privacyPolicy: 'प्रायव्हसी पॉलिसी',
    manageButton: 'मॅनेज करा',
    levelFull: 'सुरू',
    levelPartial: 'अंशतः',
    levelOff: 'बंद',
  );
}

const Map<OkapiPermission, String> _defaultNames = {
  OkapiPermission.camera: 'Camera',
  OkapiPermission.microphone: 'Microphone',
  OkapiPermission.speech: 'Speech recognition',
  OkapiPermission.photos: 'Photos',
  OkapiPermission.photosAddOnly: 'Save to Photos',
  OkapiPermission.videos: 'Videos',
  OkapiPermission.audio: 'Music & audio',
  OkapiPermission.storage: 'Storage',
  OkapiPermission.manageExternalStorage: 'All files access',
  OkapiPermission.mediaLocation: 'Photo locations',
  OkapiPermission.mediaLibrary: 'Media library',
  OkapiPermission.location: 'Location',
  OkapiPermission.locationWhenInUse: 'Location',
  OkapiPermission.locationAlways: 'Background location',
  OkapiPermission.notification: 'Notifications',
  OkapiPermission.criticalAlerts: 'Critical alerts',
  OkapiPermission.accessNotificationPolicy: 'Do Not Disturb access',
  OkapiPermission.contacts: 'Contacts',
  OkapiPermission.calendarFullAccess: 'Calendar',
  OkapiPermission.calendarWriteOnly: 'Add to Calendar',
  OkapiPermission.reminders: 'Reminders',
  OkapiPermission.phone: 'Phone',
  OkapiPermission.sms: 'SMS',
  OkapiPermission.sensors: 'Body sensors',
  OkapiPermission.sensorsAlways: 'Background body sensors',
  OkapiPermission.activityRecognition: 'Physical activity',
  OkapiPermission.bluetooth: 'Bluetooth',
  OkapiPermission.bluetoothScan: 'Nearby devices',
  OkapiPermission.bluetoothConnect: 'Nearby devices',
  OkapiPermission.bluetoothAdvertise: 'Nearby devices',
  OkapiPermission.nearbyWifiDevices: 'Nearby Wi-Fi devices',
  OkapiPermission.appTrackingTransparency: 'Tracking',
  OkapiPermission.ignoreBatteryOptimizations: 'Unrestricted battery',
  OkapiPermission.systemAlertWindow: 'Display over other apps',
  OkapiPermission.requestInstallPackages: 'Install apps',
  OkapiPermission.scheduleExactAlarm: 'Alarms & reminders',
  OkapiPermission.backgroundRefresh: 'Background refresh',
};

const Map<OkapiPermission, String> _defaultReasons = {
  OkapiPermission.camera: 'We use your camera to take photos and scan codes.',
  OkapiPermission.microphone: 'We use your microphone to record audio.',
  OkapiPermission.speech: 'We turn your voice into text.',
  OkapiPermission.photos: 'Choose photos to share or upload.',
  OkapiPermission.photosAddOnly: 'Save images to your photo library.',
  OkapiPermission.videos: 'Choose videos to share or upload.',
  OkapiPermission.audio: 'Play and pick audio files from your device.',
  OkapiPermission.storage: 'Read and save files on your device.',
  OkapiPermission.location: 'Show what\'s near you.',
  OkapiPermission.locationWhenInUse: 'Show what\'s near you.',
  OkapiPermission.locationAlways:
      'Keep location features working when the app is closed.',
  OkapiPermission.notification: 'Get updates and reminders you care about.',
  OkapiPermission.contacts: 'Find friends who already use the app.',
  OkapiPermission.calendarFullAccess: 'Show and add events to your calendar.',
  OkapiPermission.calendarWriteOnly: 'Add events to your calendar.',
  OkapiPermission.bluetooth: 'Connect to nearby devices.',
  OkapiPermission.bluetoothScan: 'Find and connect to nearby devices.',
  OkapiPermission.bluetoothConnect: 'Find and connect to nearby devices.',
  OkapiPermission.appTrackingTransparency:
      'Show you more relevant content and ads.',
};

const Map<OkapiPermission, String> _hiNames = {
  OkapiPermission.camera: 'कैमरा',
  OkapiPermission.microphone: 'माइक्रोफ़ोन',
  OkapiPermission.photos: 'फ़ोटो',
  OkapiPermission.videos: 'वीडियो',
  OkapiPermission.location: 'लोकेशन',
  OkapiPermission.locationWhenInUse: 'लोकेशन',
  OkapiPermission.locationAlways: 'बैकग्राउंड लोकेशन',
  OkapiPermission.notification: 'नोटिफ़िकेशन',
  OkapiPermission.contacts: 'कॉन्टैक्ट्स',
  OkapiPermission.calendarFullAccess: 'कैलेंडर',
  OkapiPermission.bluetooth: 'ब्लूटूथ',
  OkapiPermission.storage: 'स्टोरेज',
  OkapiPermission.phone: 'फ़ोन',
  OkapiPermission.sms: 'SMS',
};

const Map<OkapiPermission, String> _mrNames = {
  OkapiPermission.camera: 'कॅमेरा',
  OkapiPermission.microphone: 'मायक्रोफोन',
  OkapiPermission.photos: 'फोटो',
  OkapiPermission.videos: 'व्हिडिओ',
  OkapiPermission.location: 'लोकेशन',
  OkapiPermission.locationWhenInUse: 'लोकेशन',
  OkapiPermission.locationAlways: 'बॅकग्राउंड लोकेशन',
  OkapiPermission.notification: 'नोटिफिकेशन',
  OkapiPermission.contacts: 'संपर्क',
  OkapiPermission.calendarFullAccess: 'कॅलेंडर',
  OkapiPermission.bluetooth: 'ब्लूटूथ',
  OkapiPermission.storage: 'स्टोरेज',
  OkapiPermission.phone: 'फोन',
  OkapiPermission.sms: 'SMS',
};
