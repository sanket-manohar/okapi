// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted.

import 'permission.dart';
import 'policy.dart';

/// The state of a single permission.
enum OkapiStatus {
  /// Not granted yet. The app may still ask.
  denied,

  /// Fully granted.
  granted,

  /// Blocked by the OS or a parent (iOS Screen Time, MDM, parental controls).
  /// The user cannot change it, so do not keep asking.
  restricted,

  /// Partly granted: iOS limited photos or contacts, Android 14
  /// "selected photos only", approximate location, or iOS reduced accuracy.
  limited,

  /// Denied in a way the app can no longer ask again: Android "Don't ask
  /// again" (or two refusals on Android 11+), or any refusal on iOS.
  /// The only way forward is the app's system settings page.
  permanentlyDenied,

  /// iOS provisional notifications (delivered quietly to Notification Center).
  provisional,

  /// No permission is needed on this platform or OS version (for example
  /// [OkapiPermission.storage] on Android 13+, or an Android-only permission
  /// on iOS). Treat this as "you can proceed".
  notApplicable;

  /// True only for [granted].
  bool get isGranted => this == granted;

  /// True for [denied].
  bool get isDenied => this == denied;

  /// True for [permanentlyDenied].
  bool get isPermanentlyDenied => this == permanentlyDenied;

  /// True for [restricted].
  bool get isRestricted => this == restricted;

  /// True for [limited].
  bool get isLimited => this == limited;

  /// True for [provisional].
  bool get isProvisional => this == provisional;

  /// True for [notApplicable].
  bool get isNotApplicable => this == notApplicable;

  /// The status developers usually mean: the feature can be used now.
  /// True for [granted], [limited], [provisional] and [notApplicable].
  bool get canProceed =>
      this == granted ||
      this == limited ||
      this == provisional ||
      this == notApplicable;

  /// Whether calling `request` again can show a system dialog.
  bool get canAskAgain => this == denied;

  /// Decodes the integer sent by the native side.
  static OkapiStatus fromCode(int? code) => switch (code) {
        0 => denied,
        1 => granted,
        2 => restricted,
        3 => limited,
        4 => permanentlyDenied,
        5 => provisional,
        6 => notApplicable,
        _ => denied,
      };

  /// The integer used on the native side.
  int get code => switch (this) {
        denied => 0,
        granted => 1,
        restricted => 2,
        limited => 3,
        permanentlyDenied => 4,
        provisional => 5,
        notApplicable => 6,
      };
}

/// Whether the system service behind a permission is switched on.
enum OkapiServiceStatus {
  /// The service is off (for example Location Services disabled).
  disabled,

  /// The service is on.
  enabled,

  /// The permission has no related service.
  notApplicable;

  /// Decodes the integer sent by the native side.
  static OkapiServiceStatus fromCode(int? code) => switch (code) {
        0 => disabled,
        1 => enabled,
        _ => notApplicable,
      };
}

/// A change detected for one permission, for example after the user flipped
/// a switch in system settings and came back to the app.
class OkapiStatusChange {
  /// Creates a status change record.
  const OkapiStatusChange({
    required this.permission,
    required this.previous,
    required this.current,
  });

  /// The permission that changed.
  final OkapiPermission permission;

  /// Last known status, or `null` if Okapi had not seen it before.
  final OkapiStatus? previous;

  /// The new status.
  final OkapiStatus current;

  @override
  String toString() =>
      'OkapiStatusChange(${permission.name}: ${previous?.name} -> ${current.name})';
}

/// How a guided [Okapi.ask] flow ended.
enum OkapiOutcome {
  /// The permission is usable ([OkapiStatus.canProceed]).
  granted,

  /// The user chose "Not now" on Okapi's own explanation screen, so the
  /// system dialog was never shown. Nothing was burned: you can ask later.
  dismissedRationale,

  /// The user refused in the system dialog and did not retry.
  denied,

  /// The permission is permanently denied and the user did not go to settings.
  permanentlyDenied,

  /// The user went to system settings but came back without enabling it.
  settingsReturnedDenied,

  /// The OS or a parent blocks the permission.
  restricted,

  /// The related service (Location, Bluetooth) is off and the user did not
  /// turn it on.
  serviceDisabled,

  /// The ask policy postponed the flow (for example "Not now" was tapped
  /// recently). No UI was shown. See [OkapiResult.policy].
  deferredByPolicy,
}

/// The result of a guided [Okapi.ask] flow.
class OkapiResult {
  /// Creates a result.
  const OkapiResult({
    required this.permission,
    required this.status,
    required this.outcome,
    this.attempts = 0,
    this.openedSettings = false,
    this.policy,
  });

  /// The permission the flow was about.
  final OkapiPermission permission;

  /// Final status after the flow.
  final OkapiStatus status;

  /// How the flow ended.
  final OkapiOutcome outcome;

  /// How many times the system dialog was shown during this flow.
  final int attempts;

  /// Whether the user was sent to system settings during this flow.
  final bool openedSettings;

  /// Why the ask policy postponed the flow, when [outcome] is
  /// [OkapiOutcome.deferredByPolicy].
  final OkapiPolicyDecision? policy;

  /// Shortcut for `outcome == OkapiOutcome.granted`.
  bool get isGranted => outcome == OkapiOutcome.granted;

  @override
  String toString() => 'OkapiResult(${permission.name}, ${status.name}, '
      '${outcome.name}, attempts: $attempts)';
}

/// Errors Okapi throws for developer mistakes, with a message that says
/// exactly how to fix them.
class OkapiException implements Exception {
  /// Creates an exception.
  const OkapiException(this.code, this.message, {this.permission});

  /// A stable error code, for example `not_declared`.
  final String code;

  /// A readable explanation including the fix.
  final String message;

  /// The permission involved, if any.
  final OkapiPermission? permission;

  /// The permission is missing from AndroidManifest.xml or Info.plist.
  static const String notDeclared = 'not_declared';

  /// No foreground Android activity was available to show a dialog.
  static const String noActivity = 'no_activity';

  /// The native side failed unexpectedly.
  static const String nativeError = 'native_error';

  @override
  String toString() => 'OkapiException($code): $message';
}
