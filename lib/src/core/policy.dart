// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'store.dart';

/// Rules that stop an app from nagging. Applied by `Okapi.ask`, `askAll`,
/// `askFeature`, `askBackgroundReliability` and `protectFromAutoReset`.
///
/// Everything is decided on the device; nothing is sent anywhere.
/// Pass `force: true` to any of those calls when the user explicitly asked
/// (for example by tapping a switch on your settings screen).
///
/// ```dart
/// Okapi.configure(const OkapiConfig(askPolicy: OkapiAskPolicy.recommended));
/// ```
@immutable
class OkapiAskPolicy {
  /// Creates a policy. Zero values switch a rule off.
  const OkapiAskPolicy({
    this.skipFirstLaunches = 0,
    this.cooldownAfterNotNow = Duration.zero,
    this.cooldownAfterDenied = Duration.zero,
    this.cooldownAfterSettingsDecline = Duration.zero,
    this.maxPromptsPerSession = 0,
  });

  /// No rules: Okapi asks whenever you call it. The default.
  static const OkapiAskPolicy none = OkapiAskPolicy();

  /// Sensible, user-friendly rules:
  /// never on the very first launch, wait 2 days after "Not now", 7 days
  /// after a refusal, 14 days after the user declined Settings, and at most
  /// 2 Okapi prompts per app session.
  static const OkapiAskPolicy recommended = OkapiAskPolicy(
    skipFirstLaunches: 1,
    cooldownAfterNotNow: Duration(days: 2),
    cooldownAfterDenied: Duration(days: 7),
    cooldownAfterSettingsDecline: Duration(days: 14),
    maxPromptsPerSession: 2,
  );

  /// Don't ask during the first N app launches.
  final int skipFirstLaunches;

  /// Wait this long after the user tapped "Not now" on Okapi's explanation.
  final Duration cooldownAfterNotNow;

  /// Wait this long after the user refused in the system dialog.
  final Duration cooldownAfterDenied;

  /// Wait this long after the user declined to open Settings.
  final Duration cooldownAfterSettingsDecline;

  /// At most this many Okapi flows that show UI per app session. 0 = no limit.
  final int maxPromptsPerSession;

  /// Whether every rule is off.
  bool get isNone =>
      skipFirstLaunches <= 0 &&
      cooldownAfterNotNow == Duration.zero &&
      cooldownAfterDenied == Duration.zero &&
      cooldownAfterSettingsDecline == Duration.zero &&
      maxPromptsPerSession <= 0;

  /// Returns a copy with some rules replaced.
  OkapiAskPolicy copyWith({
    int? skipFirstLaunches,
    Duration? cooldownAfterNotNow,
    Duration? cooldownAfterDenied,
    Duration? cooldownAfterSettingsDecline,
    int? maxPromptsPerSession,
  }) =>
      OkapiAskPolicy(
        skipFirstLaunches: skipFirstLaunches ?? this.skipFirstLaunches,
        cooldownAfterNotNow: cooldownAfterNotNow ?? this.cooldownAfterNotNow,
        cooldownAfterDenied: cooldownAfterDenied ?? this.cooldownAfterDenied,
        cooldownAfterSettingsDecline:
            cooldownAfterSettingsDecline ?? this.cooldownAfterSettingsDecline,
        maxPromptsPerSession: maxPromptsPerSession ?? this.maxPromptsPerSession,
      );
}

/// Why a policy postponed a prompt.
enum OkapiPolicyReason {
  /// Inside the first launches set by `skipFirstLaunches`.
  firstLaunches,

  /// The session's prompt limit is reached.
  sessionLimit,

  /// The user tapped "Not now" recently.
  notNowCooldown,

  /// The user refused recently.
  deniedCooldown,

  /// The user declined Settings recently.
  settingsCooldown,
}

/// The policy's answer.
@immutable
class OkapiPolicyDecision {
  /// Creates a decision.
  const OkapiPolicyDecision.allow()
      : allowed = true,
        reason = null,
        retryAfter = null;

  /// Creates a "not now" decision.
  const OkapiPolicyDecision.wait(this.reason, [this.retryAfter])
      : allowed = false;

  /// Whether Okapi may show its UI now.
  final bool allowed;

  /// Why not, when [allowed] is false.
  final OkapiPolicyReason? reason;

  /// When the rule stops applying, if known.
  final DateTime? retryAfter;

  @override
  String toString() => allowed
      ? 'OkapiPolicyDecision(allowed)'
      : 'OkapiPolicyDecision(wait: ${reason?.name}, until: $retryAfter)';
}

/// Events the policy remembers, per permission or flow key.
enum OkapiPolicyEvent {
  /// "Not now" on Okapi's explanation.
  notNow,

  /// Refused in the system dialog.
  denied,

  /// Declined to open Settings.
  settingsDecline,
}

/// Applies an [OkapiAskPolicy]. Used internally; public so the debug panel
/// and your own code can inspect or reset it.
class OkapiPolicyEngine {
  OkapiPolicyEngine._();

  static const String _launchKey = 'okapi.launches';
  static const String _prefix = 'okapi.policy.';

  static int _sessionPrompts = 0;
  static int? _launchCount;

  /// Counts this app launch once per process. Called by `Okapi.configure`.
  static Future<int> recordLaunch() async {
    final known = _launchCount;
    if (known != null) return known;
    final n = (await OkapiStore.getInt(_launchKey) ?? 0) + 1;
    // Another call may have finished while this one was reading.
    final counted = _launchCount;
    if (counted != null) return counted;
    _launchCount = n;
    await OkapiStore.set(_launchKey, '$n');
    return n;
  }

  /// Number of app launches, including this one.
  static Future<int> launches() => recordLaunch();

  /// Okapi flows that showed UI in this session.
  static int get sessionPrompts => _sessionPrompts;

  /// Counts a flow that showed UI.
  static void countPrompt() => _sessionPrompts++;

  static String _key(String flow, OkapiPolicyEvent e) =>
      '$_prefix$flow.${e.name}';

  /// Remembers an event for [flow] (usually the permission name).
  static Future<void> record(String flow, OkapiPolicyEvent event) =>
      OkapiStore.setTime(_key(flow, event), DateTime.now());

  /// Decides whether [flow] may show UI now. [settings] selects the
  /// Settings-prompt rules instead of the ask rules.
  static Future<OkapiPolicyDecision> check(
    OkapiAskPolicy policy,
    String flow, {
    bool settings = false,
  }) async {
    if (policy.isNone) return const OkapiPolicyDecision.allow();
    if (policy.skipFirstLaunches > 0 &&
        await launches() <= policy.skipFirstLaunches) {
      return const OkapiPolicyDecision.wait(OkapiPolicyReason.firstLaunches);
    }
    if (policy.maxPromptsPerSession > 0 &&
        _sessionPrompts >= policy.maxPromptsPerSession) {
      return const OkapiPolicyDecision.wait(OkapiPolicyReason.sessionLimit);
    }
    final now = DateTime.now();
    Future<OkapiPolicyDecision?> cooldown(
      OkapiPolicyEvent e,
      Duration d,
      OkapiPolicyReason r,
    ) async {
      if (d <= Duration.zero) return null;
      final last = await OkapiStore.getTime(_key(flow, e));
      if (last == null) return null;
      final until = last.add(d);
      return until.isAfter(now) ? OkapiPolicyDecision.wait(r, until) : null;
    }

    final checks = settings
        ? [
            await cooldown(
              OkapiPolicyEvent.settingsDecline,
              policy.cooldownAfterSettingsDecline,
              OkapiPolicyReason.settingsCooldown,
            ),
          ]
        : [
            await cooldown(
              OkapiPolicyEvent.notNow,
              policy.cooldownAfterNotNow,
              OkapiPolicyReason.notNowCooldown,
            ),
            await cooldown(
              OkapiPolicyEvent.denied,
              policy.cooldownAfterDenied,
              OkapiPolicyReason.deniedCooldown,
            ),
          ];
    return checks.whereType<OkapiPolicyDecision>().firstOrNull ??
        const OkapiPolicyDecision.allow();
  }

  /// Forgets all remembered events and the session count. Launch count is
  /// kept unless [launchesToo] is true.
  static Future<void> reset({bool launchesToo = false}) async {
    _sessionPrompts = 0;
    await OkapiStore.clear(_prefix);
    if (launchesToo) {
      await OkapiStore.set(_launchKey, null);
      _launchCount = null;
    }
  }

  /// Resets in-memory state between tests.
  static void debugResetSession() {
    _sessionPrompts = 0;
    _launchCount = null;
  }
}
