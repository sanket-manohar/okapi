// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../core/device.dart';
import '../core/okapi.dart';
import '../core/permission.dart';
import '../core/status.dart';
import 'okapi_platform.dart';

/// Simulated answers set from the debug panel (or your own tests).
///
/// Anything not overridden goes to the real platform.
class OkapiDevOverrides extends ChangeNotifier {
  OkapiDevOverrides._();

  /// The shared instance used by [OkapiDevPlatform] and the debug panel.
  static final OkapiDevOverrides instance = OkapiDevOverrides._();

  final Map<OkapiPermission, OkapiStatus> _statuses = {};
  final Map<OkapiPermission, OkapiServiceStatus> _services = {};
  bool _allowOnRequest = false;
  OkapiAutoResetStatus? _autoReset;
  OkapiOemBrand? _brand;

  /// Simulated status, or null for the real one.
  OkapiStatus? statusOf(OkapiPermission p) => _statuses[p];

  /// Simulated service state, or null for the real one.
  OkapiServiceStatus? serviceOf(OkapiPermission p) => _services[p];

  /// When true, a simulated permission becomes granted when requested, as
  /// if the user tapped "Allow" in the system dialog.
  bool get allowOnRequest => _allowOnRequest;

  /// Simulated auto-reset state, or null for the real one.
  OkapiAutoResetStatus? get autoReset => _autoReset;

  /// Phone maker to preview, or null for the real phone.
  OkapiOemBrand? get brand => _brand;

  /// Number of active overrides.
  int get count =>
      _statuses.length +
      _services.length +
      (_allowOnRequest ? 1 : 0) +
      (_autoReset != null ? 1 : 0) +
      (_brand != null ? 1 : 0);

  void _changed() {
    notifyListeners();
    Okapi.refreshKnown();
  }

  void _notify() => notifyListeners();

  /// Simulates [status] for [p]; `null` returns to the real status.
  void setStatus(OkapiPermission p, OkapiStatus? status) {
    if (status == null) {
      _statuses.remove(p);
    } else {
      _statuses[p] = status;
    }
    _changed();
  }

  /// Simulates the Location / Bluetooth service; `null` uses the real one.
  void setService(OkapiPermission p, OkapiServiceStatus? status) {
    if (status == null) {
      _services.remove(p);
    } else {
      _services[p] = status;
    }
    _changed();
  }

  /// See [allowOnRequest].
  set allowOnRequest(bool value) {
    _allowOnRequest = value;
    _changed();
  }

  /// See [autoReset].
  set autoReset(OkapiAutoResetStatus? value) {
    _autoReset = value;
    _changed();
  }

  /// See [brand].
  set brand(OkapiOemBrand? value) {
    _brand = value;
    _changed();
  }

  /// Removes every override.
  void clear() {
    _statuses.clear();
    _services.clear();
    _allowOnRequest = false;
    _autoReset = null;
    _brand = null;
    _changed();
  }
}

/// Wraps the real platform and applies [OkapiDevOverrides].
///
/// Installed automatically by `OkapiDebugPanel` in debug builds.
class OkapiDevPlatform extends OkapiPlatform {
  /// Wraps [inner].
  OkapiDevPlatform(this.inner);

  /// The real platform.
  final OkapiPlatform inner;

  OkapiDevOverrides get _o => OkapiDevOverrides.instance;

  @override
  Future<OkapiStatus> checkStatus(OkapiPermission permission) async =>
      _o.statusOf(permission) ?? await inner.checkStatus(permission);

  @override
  Future<Map<OkapiPermission, OkapiStatus>> request(
    List<OkapiPermission> permissions, {
    Map<String, Object?> options = const {},
  }) async {
    final result = <OkapiPermission, OkapiStatus>{};
    final real = <OkapiPermission>[];
    for (final p in permissions) {
      final simulated = _o.statusOf(p);
      if (simulated == null) {
        real.add(p);
      } else if (_o.allowOnRequest && simulated.canAskAgain) {
        _o._statuses[p] = OkapiStatus.granted;
        result[p] = OkapiStatus.granted;
      } else {
        result[p] = simulated;
      }
    }
    if (real.isNotEmpty) {
      result.addAll(await inner.request(real, options: options));
    }
    if (permissions.any((p) => _o.statusOf(p) != null)) _o._notify();
    return result;
  }

  @override
  Future<bool> shouldShowRationale(OkapiPermission permission) async =>
      _o.statusOf(permission) != null
          ? false
          : await inner.shouldShowRationale(permission);

  @override
  Future<OkapiServiceStatus> checkServiceStatus(
          OkapiPermission permission) async =>
      _o.serviceOf(permission) ?? await inner.checkServiceStatus(permission);

  @override
  Future<bool> openAppSettings() => inner.openAppSettings();

  @override
  Future<bool> openServiceSettings(OkapiPermission permission) =>
      inner.openServiceSettings(permission);

  @override
  Future<bool> isDeclared(OkapiPermission permission) async =>
      _o.statusOf(permission) != null || await inner.isDeclared(permission);

  @override
  Future<Map<String, String>> loadStore() => inner.loadStore();

  @override
  Future<void> writeStore(String key, String? value) =>
      inner.writeStore(key, value);

  @override
  Future<OkapiDeviceInfo> deviceInfo() async {
    final real = await inner.deviceInfo();
    final b = _o.brand;
    return b == null ? real : real.withBrand(b);
  }

  @override
  Future<Set<OkapiOemScreen>> availableOemScreens() async {
    final b = _o.brand;
    if (b == null) return inner.availableOemScreens();
    return {
      if (b.restrictsBackground &&
          b != OkapiOemBrand.samsung &&
          b != OkapiOemBrand.nokia)
        OkapiOemScreen.autostart,
      OkapiOemScreen.battery,
    };
  }

  @override
  Future<bool> openOemScreen(OkapiOemScreen screen) async {
    // In a preview the screen may not exist on this phone; that's fine.
    try {
      return await inner.openOemScreen(screen);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<OkapiAutoResetStatus> autoResetStatus() async =>
      _o.autoReset ?? await inner.autoResetStatus();

  @override
  Future<bool> openAutoResetSettings() => inner.openAutoResetSettings();
}

/// Installs [OkapiDevPlatform] once. Returns true when it is active.
bool installOkapiDevPlatform() {
  if (OkapiPlatform.instance is OkapiDevPlatform) return true;
  if (kReleaseMode) return false;
  OkapiPlatform.instance = OkapiDevPlatform(OkapiPlatform.instance);
  return true;
}
