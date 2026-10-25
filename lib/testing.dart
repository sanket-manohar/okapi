// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Test helpers. Use [FakeOkapiPlatform] to unit-test permission logic and
/// widget-test Okapi's UI without a device.
///
/// ```dart
/// final fake = FakeOkapiPlatform(
///   statuses: {OkapiPermission.camera: OkapiStatus.denied},
///   requestResults: {OkapiPermission.camera: OkapiStatus.granted},
/// );
/// OkapiPlatform.instance = fake;
/// ```
library;

import 'okapi.dart';

/// An in-memory [OkapiPlatform] for tests.
class FakeOkapiPlatform extends OkapiPlatform {
  /// Creates a fake. Unlisted permissions start as [OkapiStatus.denied].
  FakeOkapiPlatform({
    Map<OkapiPermission, OkapiStatus> statuses = const {},
    Map<OkapiPermission, OkapiStatus> requestResults = const {},
    Map<OkapiPermission, OkapiServiceStatus> services = const {},
    Set<OkapiPermission> undeclared = const {},
    Map<OkapiPermission, bool> rationale = const {},
    Map<String, String> store = const {},
    this.device = const OkapiDeviceInfo.unknown(),
    Set<OkapiOemScreen> oemScreens = const {},
    this.autoReset = OkapiAutoResetStatus.notAvailable,
    this.onAutoResetSettingsReturn,
  })  : store = Map.of(store),
        oemScreens = Set.of(oemScreens),
        statuses = Map.of(statuses),
        requestResults = Map.of(requestResults),
        services = Map.of(services),
        undeclared = Set.of(undeclared),
        rationale = Map.of(rationale);

  /// Current statuses (mutable).
  final Map<OkapiPermission, OkapiStatus> statuses;

  /// What each request returns. Unlisted: the current status.
  final Map<OkapiPermission, OkapiStatus> requestResults;

  /// Service states.
  final Map<OkapiPermission, OkapiServiceStatus> services;

  /// Permissions treated as missing from the manifest / Info.plist.
  final Set<OkapiPermission> undeclared;

  /// shouldShowRationale answers.
  final Map<OkapiPermission, bool> rationale;

  /// The on-device store (mutable).
  final Map<String, String> store;

  /// What [deviceInfo] returns.
  OkapiDeviceInfo device;

  /// Phone-maker screens that "exist".
  final Set<OkapiOemScreen> oemScreens;

  /// Every phone-maker screen opened, in order.
  final List<OkapiOemScreen> openedOemScreens = [];

  /// What [autoResetStatus] returns.
  OkapiAutoResetStatus autoReset;

  /// Applied when auto-reset settings are opened.
  OkapiAutoResetStatus? onAutoResetSettingsReturn;

  /// How many times auto-reset settings were opened.
  int autoResetSettingsOpened = 0;

  /// Every request made, in order.
  final List<List<OkapiPermission>> requests = [];

  /// How many times app settings were opened.
  int settingsOpened = 0;

  /// Status to apply when settings are opened (simulates the user flipping
  /// the switch). `null` leaves statuses unchanged.
  Map<OkapiPermission, OkapiStatus>? onSettingsReturn;

  @override
  Future<OkapiStatus> checkStatus(OkapiPermission permission) async =>
      statuses[permission] ?? OkapiStatus.denied;

  @override
  Future<Map<OkapiPermission, OkapiStatus>> request(
    List<OkapiPermission> permissions, {
    Map<String, Object?> options = const {},
  }) async {
    requests.add(List.of(permissions));
    for (final p in permissions) {
      statuses[p] =
          requestResults[p] ?? statuses[p] ?? OkapiStatus.denied;
    }
    return {for (final p in permissions) p: statuses[p]!};
  }

  @override
  Future<bool> shouldShowRationale(OkapiPermission permission) async =>
      rationale[permission] ?? false;

  @override
  Future<OkapiServiceStatus> checkServiceStatus(
          OkapiPermission permission) async =>
      services[permission] ??
      (permission.hasService
          ? OkapiServiceStatus.enabled
          : OkapiServiceStatus.notApplicable);

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    onSettingsReturn?.forEach((p, s) => statuses[p] = s);
    return false; // Don't wait for a lifecycle resume in tests.
  }

  @override
  Future<bool> openServiceSettings(OkapiPermission permission) async => false;

  @override
  Future<bool> isDeclared(OkapiPermission permission) async =>
      !undeclared.contains(permission);

  @override
  Future<Map<String, String>> loadStore() async => Map.of(store);

  @override
  Future<void> writeStore(String key, String? value) async {
    if (value == null) {
      store.remove(key);
    } else {
      store[key] = value;
    }
  }

  @override
  Future<OkapiDeviceInfo> deviceInfo() async => device;

  @override
  Future<Set<OkapiOemScreen>> availableOemScreens() async => Set.of(oemScreens);

  @override
  Future<bool> openOemScreen(OkapiOemScreen screen) async {
    if (!oemScreens.contains(screen)) return false;
    openedOemScreens.add(screen);
    return false; // Don't wait for a lifecycle resume in tests.
  }

  @override
  Future<OkapiAutoResetStatus> autoResetStatus() async => autoReset;

  @override
  Future<bool> openAutoResetSettings() async {
    autoResetSettingsOpened++;
    autoReset = onAutoResetSettingsReturn ?? autoReset;
    return false;
  }
}

/// A ready-made Android phone for tests.
OkapiDeviceInfo fakeAndroidDevice({
  OkapiOemBrand brand = OkapiOemBrand.xiaomi,
  int sdkInt = 34,
  String appName = 'Test App',
}) =>
    OkapiDeviceInfo(
      platform: 'android',
      manufacturer: brand.displayName,
      brand: brand.displayName,
      model: 'Test',
      osVersion: '14',
      sdkInt: sdkInt,
      appName: appName,
    );
