// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'permission.dart';
import 'status.dart';

/// A feature of your app and the permissions it needs.
///
/// Ask for features instead of single permissions; Okapi tells you how much
/// of the feature can run.
///
/// ```dart
/// const videoCall = OkapiFeature(
///   id: 'video_call',
///   name: 'Video calls',
///   required: [OkapiPermission.camera, OkapiPermission.microphone],
///   optional: [OkapiPermission.bluetoothConnect],
/// );
///
/// final r = await Okapi.askFeature(context, videoCall);
/// if (r.isFull) startCall(); else if (r.isAvailable) startCallWithoutHeadset();
/// ```
@immutable
class OkapiFeature {
  /// Describes a feature.
  const OkapiFeature({
    required this.id,
    required this.name,
    this.required = const [],
    this.optional = const [],
    this.description,
    this.reasons = const {},
  });

  /// A stable id, used for the ask policy and analytics.
  final String id;

  /// Name shown to users, for example "Video calls".
  final String name;

  /// Without these, the feature can't run.
  final List<OkapiPermission> required;

  /// Nice to have; the feature runs with less without them.
  final List<OkapiPermission> optional;

  /// One sentence shown under the name in the Privacy Center.
  final String? description;

  /// Feature-specific reason per permission.
  final Map<OkapiPermission, String> reasons;

  /// Every permission, required first, without duplicates.
  List<OkapiPermission> get permissions => [
    ...required,
    ...optional.where((p) => !required.contains(p)),
  ];

  /// Whether [p] is optional for this feature.
  bool isOptional(OkapiPermission p) =>
      optional.contains(p) && !required.contains(p);

  @override
  bool operator ==(Object other) => other is OkapiFeature && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OkapiFeature($id)';
}

/// How much of a feature can run.
enum OkapiFeatureLevel {
  /// Every permission is usable.
  full,

  /// All required permissions are usable, some optional ones are not.
  partial,

  /// At least one required permission is missing.
  unavailable;

  /// Computes the level from statuses.
  static OkapiFeatureLevel of(
    OkapiFeature feature,
    Map<OkapiPermission, OkapiStatus> statuses,
  ) {
    bool ok(OkapiPermission p) => statuses[p]?.canProceed ?? false;
    if (!feature.required.every(ok)) return unavailable;
    final optional = feature.optional.where(
      (p) => !feature.required.contains(p),
    );
    return optional.every(ok) ? full : partial;
  }
}

/// The result of `Okapi.askFeature` or `Okapi.featureStatus`.
@immutable
class OkapiFeatureResult {
  /// Creates a result.
  const OkapiFeatureResult({
    required this.feature,
    required this.level,
    required this.statuses,
    this.results = const {},
  });

  /// The feature.
  final OkapiFeature feature;

  /// How much can run.
  final OkapiFeatureLevel level;

  /// Status of every permission of the feature.
  final Map<OkapiPermission, OkapiStatus> statuses;

  /// Per-permission flow results (empty for `featureStatus`).
  final Map<OkapiPermission, OkapiResult> results;

  /// The feature can run (fully or partly).
  bool get isAvailable => level != OkapiFeatureLevel.unavailable;

  /// Everything is allowed.
  bool get isFull => level == OkapiFeatureLevel.full;

  /// Whether one permission is usable.
  bool has(OkapiPermission p) => statuses[p]?.canProceed ?? false;

  /// Required permissions that are missing.
  List<OkapiPermission> get missingRequired =>
      feature.required.where((p) => !has(p)).toList();

  /// Optional permissions that are missing.
  List<OkapiPermission> get missingOptional => feature.optional
      .where((p) => !feature.required.contains(p) && !has(p))
      .toList();

  @override
  String toString() => 'OkapiFeatureResult(${feature.id}: ${level.name})';
}
