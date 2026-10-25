// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'device.dart';
import 'policy.dart';

/// The result of `Okapi.askBackgroundReliability`.
@immutable
class OkapiBackgroundResult {
  /// Creates a result.
  const OkapiBackgroundResult({
    required this.applicable,
    required this.ready,
    required this.brand,
    this.autostartAvailable = false,
    this.autostartConfirmed = false,
    this.batteryUnrestricted,
    this.dismissed = false,
    this.policy,
  });

  /// False on iOS (Apple doesn't stop apps this way).
  final bool applicable;

  /// Everything Okapi knows of is set up: autostart confirmed (when the
  /// phone has that screen) and battery not restricted.
  final bool ready;

  /// The detected phone maker.
  final OkapiOemBrand brand;

  /// The phone has an Autostart / Auto-launch screen.
  final bool autostartAvailable;

  /// The user confirmed they turned autostart on. Phones don't let apps read
  /// this setting, so it is the user's answer, not a measurement.
  final bool autostartConfirmed;

  /// Whether Android battery optimisation is off for this app. `null` when
  /// your manifest doesn't declare `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
  final bool? batteryUnrestricted;

  /// The user chose "Not now".
  final bool dismissed;

  /// Set when the ask policy postponed the guide.
  final OkapiPolicyDecision? policy;

  @override
  String toString() => 'OkapiBackgroundResult(${brand.name}, ready: $ready, '
      'autostart: $autostartAvailable/$autostartConfirmed, '
      'battery: $batteryUnrestricted, dismissed: $dismissed)';
}
