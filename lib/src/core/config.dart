// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import '../ui/theme.dart';
import 'permission.dart';
import 'policy.dart';
import 'status.dart';
import 'strings.dart';

/// The kind of screen Okapi wants to show during a flow.
enum OkapiPromptKind {
  /// "Here's why we need this" before the system dialog.
  rationale,

  /// The user refused; offer to try again.
  denied,

  /// The permission is permanently denied; offer to open Settings.
  settings,

  /// The related service (Location, Bluetooth) is switched off.
  serviceDisabled,

  /// The permission is blocked by device restrictions.
  restricted,

  /// Several permissions explained at once (also used by `askFeature`).
  multiRationale,

  /// Android may remove permissions from unused apps; offer to turn it off.
  autoReset,

  /// The phone maker may stop the app in the background; show the steps.
  backgroundReliability,

  /// Asks the user to confirm a setting Okapi can't read (autostart).
  backgroundConfirm,
}

/// Everything a presenter needs to draw one prompt.
///
/// Built-in presenters read these fields; your custom widgets can too.
@immutable
class OkapiPrompt {
  /// Creates a prompt.
  const OkapiPrompt({
    required this.kind,
    required this.permissions,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.secondaryLabel,
    this.reasons = const {},
    this.statuses = const {},
    this.featureName,
    this.optional = const {},
    this.steps = const [],
    this.icon,
  });

  /// What this prompt is for.
  final OkapiPromptKind kind;

  /// The permissions involved (one, except for [OkapiPromptKind.multiRationale]
  /// and grouped settings prompts).
  final List<OkapiPermission> permissions;

  /// Headline.
  final String title;

  /// Body text.
  final String message;

  /// Label of the "yes" button.
  final String primaryLabel;

  /// Label of the "no" button. `null` means a single-button prompt.
  final String? secondaryLabel;

  /// Per-permission reason sentences (used by multi-permission prompts).
  final Map<OkapiPermission, String> reasons;

  /// Current statuses, when known.
  final Map<OkapiPermission, OkapiStatus> statuses;

  /// Set when the prompt comes from `Okapi.askFeature`.
  final String? featureName;

  /// Permissions shown with an "Optional" tag.
  final Set<OkapiPermission> optional;

  /// Numbered instructions (phone-maker guide, auto-reset).
  final List<String> steps;

  /// Icon for prompts that are not about one permission
  /// ([OkapiPromptKind.autoReset], [OkapiPromptKind.backgroundReliability],
  /// [OkapiPromptKind.backgroundConfirm]).
  final IconData? icon;

  /// The first (usually only) permission.
  ///
  /// [permissions] can be empty for [OkapiPromptKind.autoReset],
  /// [OkapiPromptKind.backgroundReliability] and
  /// [OkapiPromptKind.backgroundConfirm]; check [hasPermission] first there.
  OkapiPermission get permission => permissions.first;

  /// Whether [permissions] is not empty.
  bool get hasPermission => permissions.isNotEmpty;

  /// Returns a copy with some fields replaced. Handy inside
  /// [OkapiConfig.promptOverride].
  OkapiPrompt copyWith({
    String? title,
    String? message,
    String? primaryLabel,
    String? secondaryLabel,
    Map<OkapiPermission, String>? reasons,
    List<String>? steps,
    IconData? icon,
  }) => OkapiPrompt(
    kind: kind,
    permissions: permissions,
    title: title ?? this.title,
    message: message ?? this.message,
    primaryLabel: primaryLabel ?? this.primaryLabel,
    secondaryLabel: secondaryLabel ?? this.secondaryLabel,
    reasons: reasons ?? this.reasons,
    statuses: statuses,
    featureName: featureName,
    optional: optional,
    steps: steps ?? this.steps,
    icon: icon ?? this.icon,
  );
}

/// Shows prompts. Implement this to take full control of Okapi's UI.
///
/// Return `true` when the user chose the primary action ("Continue",
/// "Try again", "Open Settings") and `false` otherwise.
abstract class OkapiPresenter {
  /// Const constructor for subclasses.
  const OkapiPresenter();

  /// Shows [prompt] and resolves with the user's choice.
  Future<bool> present(BuildContext context, OkapiPrompt prompt);
}

/// When Okapi shows its own explanation before the system dialog.
enum OkapiRationaleMode {
  /// Always explain first (recommended: protects your one-shot system dialog).
  always,

  /// Only when Android says a rationale is recommended (after a refusal).
  whenRecommended,

  /// Never; go straight to the system dialog.
  never,
}

/// Listen to everything Okapi does, for analytics or logging.
///
/// Okapi never sends data anywhere; these hooks run only in your app.
abstract class OkapiObserver {
  /// Const constructor for subclasses.
  const OkapiObserver();

  /// A prompt was shown and the user answered.
  void onPrompt(OkapiPrompt prompt, bool accepted) {}

  /// The system dialog is about to be shown.
  void onSystemRequest(List<OkapiPermission> permissions) {}

  /// A guided flow finished.
  void onResult(OkapiResult result) {}

  /// A status changed (including changes made in system settings).
  void onStatusChange(OkapiStatusChange change) {}
}

/// Global settings. Pass to `Okapi.configure` once, usually in `main()`.
///
/// Every value can also be overridden per call on `Okapi.ask`.
@immutable
class OkapiConfig {
  /// Creates a configuration. All fields have sensible defaults.
  const OkapiConfig({
    this.presenter,
    this.theme,
    this.strings = OkapiStrings.english,
    this.rationaleMode = OkapiRationaleMode.always,
    this.maxRetries = 1,
    this.offerSettings = true,
    this.settingsRightAfterRefusal = false,
    this.checkService = true,
    this.settingsReturnTimeout = const Duration(minutes: 5),
    this.observers = const [],
    this.promptOverride,
    this.debugLogs = false,
    this.askPolicy = OkapiAskPolicy.none,
  });

  /// How prompts are shown. `null` uses [OkapiSheetPresenter].
  final OkapiPresenter? presenter;

  /// Colours, shapes and text styles for the built-in UI. `null` derives a
  /// theme from your app's `ThemeData`.
  final OkapiThemeData? theme;

  /// All user-facing text.
  final OkapiStrings strings;

  /// When to show the explanation screen.
  final OkapiRationaleMode rationaleMode;

  /// How many extra times to offer "Try again" after a refusal.
  final int maxRetries;

  /// Whether to offer "Open Settings" when a permission is permanently denied.
  final bool offerSettings;

  /// When the user refuses in the system dialog and the permission becomes
  /// permanently denied (always on iOS, second refusal on Android), whether
  /// to immediately suggest Settings. `false` (default) is less pushy: the
  /// Settings prompt appears the next time the user taps the feature.
  final bool settingsRightAfterRefusal;

  /// Whether to check Location / Bluetooth services before asking.
  final bool checkService;

  /// How long to wait for the user to come back from system settings.
  final Duration settingsReturnTimeout;

  /// Analytics / logging hooks.
  final List<OkapiObserver> observers;

  /// Last-chance edit of any prompt before it is shown, for example to change
  /// one title without replacing all strings.
  final OkapiPrompt Function(OkapiPrompt prompt)? promptOverride;

  /// Print what Okapi is doing to the debug console.
  final bool debugLogs;

  /// Rules that stop the app from nagging. Default: no rules.
  /// Try [OkapiAskPolicy.recommended].
  final OkapiAskPolicy askPolicy;

  /// Returns a copy with some fields replaced.
  OkapiConfig copyWith({
    OkapiPresenter? presenter,
    OkapiThemeData? theme,
    OkapiStrings? strings,
    OkapiRationaleMode? rationaleMode,
    int? maxRetries,
    bool? offerSettings,
    bool? settingsRightAfterRefusal,
    bool? checkService,
    Duration? settingsReturnTimeout,
    List<OkapiObserver>? observers,
    OkapiPrompt Function(OkapiPrompt prompt)? promptOverride,
    bool? debugLogs,
    OkapiAskPolicy? askPolicy,
  }) => OkapiConfig(
    presenter: presenter ?? this.presenter,
    theme: theme ?? this.theme,
    strings: strings ?? this.strings,
    rationaleMode: rationaleMode ?? this.rationaleMode,
    maxRetries: maxRetries ?? this.maxRetries,
    offerSettings: offerSettings ?? this.offerSettings,
    settingsRightAfterRefusal:
        settingsRightAfterRefusal ?? this.settingsRightAfterRefusal,
    checkService: checkService ?? this.checkService,
    settingsReturnTimeout: settingsReturnTimeout ?? this.settingsReturnTimeout,
    observers: observers ?? this.observers,
    promptOverride: promptOverride ?? this.promptOverride,
    debugLogs: debugLogs ?? this.debugLogs,
    askPolicy: askPolicy ?? this.askPolicy,
  );
}
