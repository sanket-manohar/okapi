// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/device.dart';
import '../core/permission.dart';
import '../core/status.dart';

/// The bridge between Dart and the native Android/iOS code.
///
/// You normally never touch this. Replace [instance] with a fake in tests
/// (see `package:okapi/testing.dart`).
abstract class OkapiPlatform {
  /// The active implementation. Replace it with a fake in tests or with a
  /// custom platform.
  static OkapiPlatform instance = MethodChannelOkapi();

  /// Current status without showing any UI.
  Future<OkapiStatus> checkStatus(OkapiPermission permission);

  /// Shows the system dialog (or special settings screen) for each
  /// permission and returns the resulting statuses.
  Future<Map<OkapiPermission, OkapiStatus>> request(
    List<OkapiPermission> permissions, {
    Map<String, Object?> options = const {},
  });

  /// Android: whether the system recommends explaining before asking.
  /// Always false on iOS.
  Future<bool> shouldShowRationale(OkapiPermission permission);

  /// Whether the related system service is switched on.
  Future<OkapiServiceStatus> checkServiceStatus(OkapiPermission permission);

  /// Opens this app's page in system settings.
  Future<bool> openAppSettings();

  /// Opens the settings page of the related service (for example Location).
  /// Falls back to the app's settings page when the platform has none.
  Future<bool> openServiceSettings(OkapiPermission permission);

  /// Whether the permission is declared in AndroidManifest.xml / Info.plist.
  Future<bool> isDeclared(OkapiPermission permission);

  // The members below have safe defaults so custom platforms keep working.

  /// Loads Okapi's small on-device store (timestamps, counters, flags).
  Future<Map<String, String>> loadStore() async => const {};

  /// Writes one store value; `null` removes it.
  Future<void> writeStore(String key, String? value) async {}

  /// Basic facts about the phone.
  Future<OkapiDeviceInfo> deviceInfo() async => const OkapiDeviceInfo.unknown();

  /// Which phone-maker screens exist on this phone (Android only).
  Future<Set<OkapiOemScreen>> availableOemScreens() async => const {};

  /// Opens a phone-maker screen. Returns false when it doesn't exist.
  Future<bool> openOemScreen(OkapiOemScreen screen) async => false;

  /// Whether Android may remove permissions when the app is unused.
  Future<OkapiAutoResetStatus> autoResetStatus() async =>
      OkapiAutoResetStatus.notAvailable;

  /// Opens the screen where the user can turn auto-reset off for this app.
  Future<bool> openAutoResetSettings() async => false;
}

/// Default implementation using a [MethodChannel].
class MethodChannelOkapi extends OkapiPlatform {
  /// The channel shared with the native plugins.
  @visibleForTesting
  static const MethodChannel channel = MethodChannel('dev.okapi/permissions');

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<T?> _invoke<T>(String method, [Object? args]) async {
    try {
      return await channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      final permissionName = (e.details is Map)
          ? (e.details as Map)['permission'] as String?
          : null;
      throw OkapiException(
        e.code,
        e.message ?? 'Unknown native error',
        permission: permissionName == null
            ? null
            : OkapiPermission.values
                .where((p) => p.name == permissionName)
                .firstOrNull,
      );
    }
  }

  @override
  Future<OkapiStatus> checkStatus(OkapiPermission permission) async {
    if (!_isMobile) return OkapiStatus.notApplicable;
    final code = await _invoke<int>('checkStatus', permission.name);
    return OkapiStatus.fromCode(code);
  }

  @override
  Future<Map<OkapiPermission, OkapiStatus>> request(
    List<OkapiPermission> permissions, {
    Map<String, Object?> options = const {},
  }) async {
    if (!_isMobile) {
      return {for (final p in permissions) p: OkapiStatus.notApplicable};
    }
    final raw = await _invoke<Map<Object?, Object?>>('request', {
      'permissions': permissions.map((p) => p.name).toList(),
      'options': options,
    });
    final result = <OkapiPermission, OkapiStatus>{};
    for (final p in permissions) {
      result[p] = OkapiStatus.fromCode(raw?[p.name] as int?);
    }
    return result;
  }

  @override
  Future<bool> shouldShowRationale(OkapiPermission permission) async {
    if (!_isMobile || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    return await _invoke<bool>('shouldShowRationale', permission.name) ?? false;
  }

  @override
  Future<OkapiServiceStatus> checkServiceStatus(
    OkapiPermission permission,
  ) async {
    if (!_isMobile || !permission.hasService) {
      return OkapiServiceStatus.notApplicable;
    }
    final code = await _invoke<int>('checkServiceStatus', permission.name);
    return OkapiServiceStatus.fromCode(code);
  }

  @override
  Future<bool> openAppSettings() async {
    if (!_isMobile) return false;
    return await _invoke<bool>('openAppSettings') ?? false;
  }

  @override
  Future<bool> openServiceSettings(OkapiPermission permission) async {
    if (!_isMobile) return false;
    return await _invoke<bool>('openServiceSettings', permission.name) ?? false;
  }

  @override
  Future<bool> isDeclared(OkapiPermission permission) async {
    if (!_isMobile) return true;
    return await _invoke<bool>('isDeclared', permission.name) ?? true;
  }

  @override
  Future<Map<String, String>> loadStore() async {
    if (!_isMobile) return const {};
    final raw = await _invoke<Map<Object?, Object?>>('loadStore');
    return {
      for (final e in (raw ?? const {}).entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    };
  }

  @override
  Future<void> writeStore(String key, String? value) async {
    if (!_isMobile) return;
    await _invoke<void>('writeStore', {'key': key, 'value': value});
  }

  @override
  Future<OkapiDeviceInfo> deviceInfo() async {
    if (!_isMobile) return const OkapiDeviceInfo.unknown();
    final raw = await _invoke<Map<Object?, Object?>>('deviceInfo');
    return raw == null
        ? const OkapiDeviceInfo.unknown()
        : OkapiDeviceInfo.fromMap(raw);
  }

  @override
  Future<Set<OkapiOemScreen>> availableOemScreens() async {
    if (!_isMobile || defaultTargetPlatform != TargetPlatform.android) {
      return const {};
    }
    final raw = await _invoke<List<Object?>>('availableOemScreens');
    return {
      for (final s in raw ?? const [])
        ...OkapiOemScreen.values.where((v) => v.name == s),
    };
  }

  @override
  Future<bool> openOemScreen(OkapiOemScreen screen) async {
    if (!_isMobile || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    return await _invoke<bool>('openOemScreen', screen.name) ?? false;
  }

  @override
  Future<OkapiAutoResetStatus> autoResetStatus() async {
    if (!_isMobile || defaultTargetPlatform != TargetPlatform.android) {
      return OkapiAutoResetStatus.notAvailable;
    }
    return OkapiAutoResetStatus.fromCode(await _invoke<int>('autoResetStatus'));
  }

  @override
  Future<bool> openAutoResetSettings() async {
    if (!_isMobile || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    return await _invoke<bool>('openAutoResetSettings') ?? false;
  }
}
