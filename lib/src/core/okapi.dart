// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import '../platform/okapi_platform.dart';
import '../ui/presenters/sheet_presenter.dart';
import 'background.dart';
import 'config.dart';
import 'declarations.dart';
import 'device.dart';
import 'feature.dart';
import 'permission.dart';
import 'policy.dart';
import 'status.dart';
import 'store.dart';
import 'strings.dart';

/// The single entry point to Okapi.
///
/// * **Guided** – [ask], [askAll] and [askFeature] run the full, polished
///   flow: explain, ask, handle refusals, guide to Settings, and re-check
///   when the user comes back.
/// * **Reliability** – [askBackgroundReliability] guides users of Xiaomi,
///   Samsung, vivo, OPPO and other phones through autostart and battery
///   settings; [protectFromAutoReset] stops Android removing permissions
///   from unused apps.
/// * **Low level** – [status], [request], [requestMany],
///   [shouldShowRationale], [serviceStatus], [openAppSettings] and friends.
///
/// ```dart
/// final result = await Okapi.ask(context, OkapiPermission.camera);
/// if (result.isGranted) openCamera();
/// ```
class Okapi {
  Okapi._();

  // ── Configuration ────────────────────────────────────────────────────────

  static OkapiConfig _config = const OkapiConfig();

  /// The current global configuration.
  static OkapiConfig get config => _config;

  /// Sets the global configuration. Call once, for example in `main()`.
  static void configure(OkapiConfig config) {
    _config = config;
    _lifecycle.attach();
    try {
      // Count the launch now if Flutter is ready; otherwise the first flow
      // that needs the count does it.
      WidgetsBinding.instance;
      unawaited(OkapiPolicyEngine.recordLaunch());
    } catch (_) {
      // Binding not ready: the launch is counted later.
    }
  }

  static OkapiPlatform get _platform => OkapiPlatform.instance;

  static void _log(String message) {
    if (_config.debugLogs) debugPrint('[okapi] $message');
  }

  // ── Status cache & change stream ─────────────────────────────────────────

  static final Map<OkapiPermission, OkapiStatus> _known = {};
  static final StreamController<OkapiStatusChange> _changes =
      StreamController<OkapiStatusChange>.broadcast();

  /// Emits whenever Okapi notices a permission changed, including changes the
  /// user made in system settings (Okapi re-checks every known permission
  /// when your app returns to the foreground).
  static Stream<OkapiStatusChange> get statusChanges {
    _lifecycle.attach();
    return _changes.stream;
  }

  /// A stream of statuses for one permission. Emits the current status first.
  static Stream<OkapiStatus> watch(OkapiPermission permission) async* {
    _lifecycle.attach();
    yield await status(permission);
    yield* _changes.stream
        .where((c) => c.permission == permission)
        .map((c) => c.current);
  }

  /// The last status Okapi saw for [permission], without calling native code.
  static OkapiStatus? lastKnown(OkapiPermission permission) =>
      _known[permission];

  /// Every permission Okapi has checked or requested in this session.
  static Iterable<OkapiPermission> get knownPermissions => _known.keys;

  static void _record(OkapiPermission permission, OkapiStatus status) {
    final previous = _known[permission];
    _known[permission] = status;
    _trackGranted(permission, status);
    if (previous != status) {
      final change = OkapiStatusChange(
        permission: permission,
        previous: previous,
        current: status,
      );
      _log(change.toString());
      if (previous != null) {
        for (final o in _config.observers) {
          o.onStatusChange(change);
        }
      }
      _changes.add(change);
    }
  }

  /// Re-checks every permission Okapi has seen so far.
  static Future<void> refreshKnown() async {
    for (final p in _known.keys.toList()) {
      try {
        await status(p);
      } catch (_) {
        // A refresh must never crash the app.
      }
    }
  }

  // ── Granted memory (to spot removed permissions) ─────────────────────────

  static const String _grantedKey = 'okapi.granted';
  static Future<Set<String>>? _grantedAtLaunch;
  static Set<String> _grantedNow = {};
  static Future<void> _grantedChain = Future<void>.value();

  static Future<Set<String>> _loadGranted() => _grantedAtLaunch ??= () async {
        final raw = await OkapiStore.get(_grantedKey) ?? '';
        final set = raw.split(',').where((e) => e.isNotEmpty).toSet();
        _grantedNow = {...set};
        return set;
      }();

  static void _trackGranted(OkapiPermission p, OkapiStatus s) {
    if (s.isNotApplicable) return;
    _grantedChain = _grantedChain.then((_) async {
      await _loadGranted();
      final usable = s.isGranted || s.isLimited || s.isProvisional;
      final changed = usable ? _grantedNow.add(p.name) : _grantedNow.remove(p.name);
      if (changed) await OkapiStore.set(_grantedKey, _grantedNow.join(','));
    }).catchError((Object _) {});
  }

  /// Permissions that were allowed when the app last ran but are not allowed
  /// now: removed by the user in Settings or by Android's auto-reset.
  static Future<List<OkapiPermission>> revokedSinceLastLaunch() async {
    final before = await _loadGranted();
    final out = <OkapiPermission>[];
    for (final p in OkapiPermission.values) {
      if (!before.contains(p.name)) continue;
      final s = _known[p] ?? await status(p);
      if (!s.canProceed) out.add(p);
    }
    return out;
  }

  // ── Serialising ──────────────────────────────────────────────────────────
  // Android throws if two permission requests overlap, and two sheets on top
  // of each other look broken. Okapi queues both automatically.

  static final _OkapiLock _requestLock = _OkapiLock();
  static final _OkapiLock _flowLock = _OkapiLock();

  static Future<T> _serial<T>(bool flow, Future<T> Function() task) =>
      (flow ? _flowLock : _requestLock).run(task);

  // ── Low-level API ────────────────────────────────────────────────────────

  /// Current status of [permission]. Never shows UI.
  static Future<OkapiStatus> status(OkapiPermission permission) async {
    _lifecycle.attach();
    final s = await _platform.checkStatus(permission);
    _record(permission, s);
    return s;
  }

  /// Current statuses of several permissions.
  static Future<Map<OkapiPermission, OkapiStatus>> statuses(
      Iterable<OkapiPermission> permissions) async {
    final result = <OkapiPermission, OkapiStatus>{};
    for (final p in permissions) {
      result[p] = await status(p);
    }
    return result;
  }

  /// Shows the system dialog for one permission. No Okapi UI.
  static Future<OkapiStatus> request(
    OkapiPermission permission, {
    bool provisional = false,
  }) async =>
      (await requestMany([permission], provisional: provisional))[permission]!;

  /// Shows the system dialogs for several permissions, one after another.
  /// No Okapi UI. Requests are queued, so calling this twice is safe.
  ///
  /// [provisional] asks for iOS provisional (quiet) notifications.
  static Future<Map<OkapiPermission, OkapiStatus>> requestMany(
    List<OkapiPermission> permissions, {
    bool provisional = false,
  }) {
    _lifecycle.attach();
    return _serial(false, () async {
      for (final o in _config.observers) {
        o.onSystemRequest(permissions);
      }
      _log('request ${permissions.map((p) => p.name).join(', ')}');
      final result = await _platform.request(
        permissions,
        options: {'provisional': provisional},
      );
      result.forEach(_record);
      return result;
    });
  }

  /// Android: whether the system recommends showing an explanation (true
  /// after one refusal). Always false on iOS.
  static Future<bool> shouldShowRationale(OkapiPermission permission) =>
      _platform.shouldShowRationale(permission);

  /// Whether Location Services / Bluetooth is switched on.
  static Future<OkapiServiceStatus> serviceStatus(
          OkapiPermission permission) =>
      _platform.checkServiceStatus(permission);

  /// Opens this app's page in system settings.
  static Future<bool> openAppSettings() => _platform.openAppSettings();

  /// Opens the Location / Bluetooth settings page (falls back to app settings).
  static Future<bool> openServiceSettings(OkapiPermission permission) =>
      _platform.openServiceSettings(permission);

  /// Whether [permission] is declared in AndroidManifest.xml / Info.plist.
  static Future<bool> isDeclared(OkapiPermission permission) =>
      _platform.isDeclared(permission);

  /// Throws an [OkapiException] with a copy-paste fix if [permission] is not
  /// declared. Okapi calls this for you inside the guided flows.
  static Future<void> assertDeclared(OkapiPermission permission) async {
    if (await isDeclared(permission)) return;
    throw OkapiException(
      OkapiException.notDeclared,
      OkapiDeclarations.hint(
        permission,
        isIOS: defaultTargetPlatform == TargetPlatform.iOS,
      ),
      permission: permission,
    );
  }

  /// Resolves the next time the app comes back to the foreground, or after
  /// [timeout].
  static Future<void> nextResume([Duration? timeout]) =>
      _lifecycle.nextResume(timeout ?? _config.settingsReturnTimeout);

  // ── Device & phone maker ─────────────────────────────────────────────────

  static Future<OkapiDeviceInfo>? _device;
  static OkapiPlatform? _deviceOwner;

  /// Basic facts about the phone (maker, model, OS version, app name).
  static Future<OkapiDeviceInfo> deviceInfo() {
    if (!identical(_deviceOwner, _platform)) {
      _deviceOwner = _platform;
      _device = null;
    }
    return _device ??= () async {
      try {
        return await _platform.deviceInfo();
      } catch (_) {
        return const OkapiDeviceInfo.unknown();
      }
    }();
  }

  /// Which phone-maker screens exist on this phone (Android only).
  static Future<Set<OkapiOemScreen>> oemScreens() async {
    try {
      return await _platform.availableOemScreens();
    } catch (_) {
      return const {};
    }
  }

  /// Opens a phone-maker screen. Returns false when it doesn't exist.
  static Future<bool> openOemScreen(OkapiOemScreen screen) async {
    try {
      return await _platform.openOemScreen(screen);
    } catch (_) {
      return false;
    }
  }

  static const String _bgConfirmKey = 'okapi.background.confirmed';

  /// Whether [askBackgroundReliability] still has something to set up.
  /// Never shows UI.
  static Future<bool> needsBackgroundSetup() async =>
      !(await _backgroundState()).ready;

  /// The current background-reliability state. Never shows UI.
  static Future<OkapiBackgroundResult> backgroundStatus() => _backgroundState();

  static Future<OkapiBackgroundResult> _backgroundState({
    bool dismissed = false,
    OkapiPolicyDecision? policy,
  }) async {
    final info = await deviceInfo();
    if (!info.isAndroid) {
      return OkapiBackgroundResult(
          applicable: false, ready: true, brand: info.oem);
    }
    final screens = await oemScreens();
    final hasAutostart = screens.contains(OkapiOemScreen.autostart);
    bool? battery;
    try {
      if (await isDeclared(OkapiPermission.ignoreBatteryOptimizations)) {
        battery =
            (await status(OkapiPermission.ignoreBatteryOptimizations)).canProceed;
      }
    } catch (_) {
      battery = null;
    }
    final confirmed = await OkapiStore.get(_bgConfirmKey) == '1';
    final ready = (!hasAutostart || confirmed) &&
        (battery ?? (confirmed || !info.oem.restrictsBackground));
    return OkapiBackgroundResult(
      applicable: true,
      ready: ready,
      brand: info.oem,
      autostartAvailable: hasAutostart,
      autostartConfirmed: confirmed,
      batteryUnrestricted: battery,
      dismissed: dismissed,
      policy: policy,
    );
  }

  /// Guides the user through their phone maker's autostart and battery
  /// settings so notifications, alarms and sync keep working.
  ///
  /// Shows brand-specific steps (Xiaomi, Samsung, OPPO, realme, OnePlus,
  /// vivo, iQOO, Huawei, Honor, ASUS, TECNO, Infinix, itel, Nokia), opens
  /// the right hidden screen, asks the user to confirm (phones don't let
  /// apps read this setting), then handles battery optimisation.
  ///
  /// Does nothing on iOS or when everything is already set up, unless
  /// [force] is true. Respects [OkapiConfig.askPolicy].
  static Future<OkapiBackgroundResult> askBackgroundReliability(
    BuildContext context, {
    String? reason,
    bool force = false,
    OkapiPresenter? presenter,
  }) {
    final c = _config.copyWith(presenter: presenter);
    return _serial(true, () => _runBackground(context, c, reason, force));
  }

  static Future<OkapiBackgroundResult> _runBackground(
    BuildContext context,
    OkapiConfig c,
    String? reason,
    bool force,
  ) async {
    final start = await _backgroundState();
    if (!start.applicable || (start.ready && !force)) return start;
    if (!force) {
      final d = await OkapiPolicyEngine.check(c.askPolicy, 'background',
          settings: true);
      if (!d.allowed) return _backgroundState(policy: d);
    }
    if (!context.mounted) return _backgroundState(dismissed: true);

    final info = await deviceInfo();
    final s = c.strings;
    final values = {'app': info.appName, 'brand': info.oem.displayName};
    OkapiPolicyEngine.countPrompt();

    if (!context.mounted) return _backgroundState(dismissed: true);
    final go = await _show(
      context,
      _finalize(
        c,
        OkapiPrompt(
          kind: OkapiPromptKind.backgroundReliability,
          permissions: const [],
          title: s.fillWith(s.backgroundTitle, values),
          message: reason ?? s.fillWith(s.backgroundMessage, values),
          primaryLabel: s.backgroundOpen,
          secondaryLabel: s.backgroundNotNow,
          steps: s.stepsFor(info.oem, info.appName),
          icon: Icons.battery_saver_rounded,
        ),
      ),
      c,
    );
    if (!go) {
      await OkapiPolicyEngine.record('background', OkapiPolicyEvent.settingsDecline);
      return _backgroundState(dismissed: true);
    }

    Future<void> confirm() async {
      if (!context.mounted) return;
      final yes = await _show(
        context,
        _finalize(
          c,
          OkapiPrompt(
            kind: OkapiPromptKind.backgroundConfirm,
            permissions: const [],
            title: s.fillWith(s.backgroundConfirmTitle, values),
            message: s.fillWith(s.backgroundConfirmMessage, values),
            primaryLabel: s.backgroundConfirmYes,
            secondaryLabel: s.backgroundConfirmNo,
            icon: Icons.rocket_launch_rounded,
          ),
        ),
        c,
      );
      await OkapiStore.set(_bgConfirmKey, yes ? '1' : null);
    }

    // Step 1: the maker's autostart screen.
    if (start.autostartAvailable && (!start.autostartConfirmed || force)) {
      if (await openOemScreen(OkapiOemScreen.autostart)) {
        await nextResume();
        await confirm();
      }
    }

    // Step 2: battery.
    if (start.batteryUnrestricted == false) {
      await request(OkapiPermission.ignoreBatteryOptimizations);
    } else if (start.batteryUnrestricted == null &&
        info.oem.restrictsBackground) {
      if (await openOemScreen(OkapiOemScreen.battery)) {
        await nextResume();
        if (!start.autostartAvailable) await confirm();
      }
    }
    return _backgroundState();
  }

  // ── Auto-reset (Android "Pause app activity if unused") ──────────────────

  /// Whether Android may remove this app's permissions when it is unused.
  static Future<OkapiAutoResetStatus> autoResetStatus() async {
    try {
      return await _platform.autoResetStatus();
    } catch (_) {
      return OkapiAutoResetStatus.unknown;
    }
  }

  /// Opens the screen where the user can turn auto-reset off for this app.
  static Future<bool> openAutoResetSettings() async {
    try {
      return await _platform.openAutoResetSettings();
    } catch (_) {
      return false;
    }
  }

  /// Offers to turn off Android's auto-reset for this app, mentioning any
  /// permissions that were already removed.
  ///
  /// With [onlyIfRevoked], the prompt appears only when a permission was
  /// removed since the last launch, the gentlest way to use it. Returns the
  /// final status. Respects [OkapiConfig.askPolicy] unless [force] is true.
  static Future<OkapiAutoResetStatus> protectFromAutoReset(
    BuildContext context, {
    bool onlyIfRevoked = false,
    bool force = false,
    OkapiPresenter? presenter,
  }) {
    final c = _config.copyWith(presenter: presenter);
    return _serial(
        true, () => _runAutoReset(context, c, onlyIfRevoked, force));
  }

  static Future<OkapiAutoResetStatus> _runAutoReset(
    BuildContext context,
    OkapiConfig c,
    bool onlyIfRevoked,
    bool force,
  ) async {
    var st = await autoResetStatus();
    if (st != OkapiAutoResetStatus.enabled) return st;
    final revoked = await revokedSinceLastLaunch();
    if (onlyIfRevoked && revoked.isEmpty && !force) return st;
    if (!force) {
      final d = await OkapiPolicyEngine.check(c.askPolicy, 'autoReset',
          settings: true);
      if (!d.allowed) return st;
    }
    if (!context.mounted) return st;

    final info = await deviceInfo();
    final s = c.strings;
    final values = {
      'app': info.appName,
      'list': revoked.map(s.nameOf).toSet().join(', '),
    };
    OkapiPolicyEngine.countPrompt();
    if (!context.mounted) return st;
    final go = await _show(
      context,
      _finalize(
        c,
        OkapiPrompt(
          kind: OkapiPromptKind.autoReset,
          permissions: revoked,
          title: s.fillWith(s.autoResetTitle, values),
          message: s.fillWith(
              revoked.isEmpty ? s.autoResetMessage : s.autoResetRevokedMessage,
              values),
          primaryLabel: s.autoResetOpen,
          secondaryLabel: s.autoResetNotNow,
          steps: s.autoResetSteps,
          icon: Icons.restore_rounded,
        ),
      ),
      c,
    );
    if (!go) {
      await OkapiPolicyEngine.record('autoReset', OkapiPolicyEvent.settingsDecline);
      return st;
    }
    if (await openAutoResetSettings()) {
      await nextResume();
      st = await autoResetStatus();
    }
    return st;
  }

  // ── Guided API ───────────────────────────────────────────────────────────

  /// Runs the complete permission flow for [permission]:
  ///
  /// 1. Checks the permission is declared (clear error if not).
  /// 2. If Location/Bluetooth is off, offers to turn it on.
  /// 3. Returns at once if already granted.
  /// 4. Applies the ask policy (unless [force]).
  /// 5. Explains why (rationale), then shows the system dialog.
  /// 6. On refusal, offers "Try again" up to `maxRetries` times.
  /// 7. If permanently denied, offers Settings, waits for the user to come
  ///    back and re-checks.
  ///
  /// Every option defaults to [config]; pass a value to override per call.
  /// [reason] replaces the explanation text for this call only. Pass
  /// [force] when the user explicitly asked (for example tapped a switch),
  /// so the ask policy doesn't postpone the flow.
  static Future<OkapiResult> ask(
    BuildContext context,
    OkapiPermission permission, {
    String? reason,
    OkapiPresenter? presenter,
    OkapiRationaleMode? rationaleMode,
    int? maxRetries,
    bool? offerSettings,
    bool? settingsRightAfterRefusal,
    bool? checkService,
    bool provisional = false,
    bool force = false,
  }) {
    final c = _config.copyWith(
      presenter: presenter,
      rationaleMode: rationaleMode,
      maxRetries: maxRetries,
      offerSettings: offerSettings,
      settingsRightAfterRefusal: settingsRightAfterRefusal,
      checkService: checkService,
    );
    return _serial(
      true,
      () => _runAsk(context, permission, c, reason, provisional, force),
    );
  }

  /// Runs one combined flow for several permissions: a single explanation
  /// listing all of them, the system dialogs one after another, and a single
  /// Settings prompt for any that are permanently denied.
  ///
  /// [reasons] replaces the explanation per permission for this call only.
  static Future<Map<OkapiPermission, OkapiResult>> askAll(
    BuildContext context,
    List<OkapiPermission> permissions, {
    Map<OkapiPermission, String> reasons = const {},
    OkapiPresenter? presenter,
    OkapiRationaleMode? rationaleMode,
    bool? offerSettings,
    bool force = false,
  }) {
    final c = _config.copyWith(
      presenter: presenter,
      rationaleMode: rationaleMode,
      offerSettings: offerSettings,
    );
    return _serial(
        true, () => _runAskAll(context, permissions, c, reasons, force: force));
  }

  /// Current level of a feature. Never shows UI.
  static Future<OkapiFeatureResult> featureStatus(OkapiFeature feature) async {
    final st = await statuses(feature.permissions);
    return OkapiFeatureResult(
      feature: feature,
      level: OkapiFeatureLevel.of(feature, st),
      statuses: st,
    );
  }

  /// Asks for everything a feature needs in one flow, marking optional
  /// permissions, and tells you how much of the feature can run.
  static Future<OkapiFeatureResult> askFeature(
    BuildContext context,
    OkapiFeature feature, {
    OkapiPresenter? presenter,
    OkapiRationaleMode? rationaleMode,
    bool? offerSettings,
    bool force = false,
  }) {
    final c = _config.copyWith(
      presenter: presenter,
      rationaleMode: rationaleMode,
      offerSettings: offerSettings,
    );
    return _serial(true, () async {
      final results = await _runAskAll(
          context, feature.permissions, c, feature.reasons,
          feature: feature, force: force);
      final st = {for (final e in results.entries) e.key: e.value.status};
      return OkapiFeatureResult(
        feature: feature,
        level: OkapiFeatureLevel.of(feature, st),
        statuses: st,
        results: results,
      );
    });
  }

  // ── Flow internals ───────────────────────────────────────────────────────

  static OkapiPrompt _finalize(OkapiConfig c, OkapiPrompt prompt) =>
      c.promptOverride?.call(prompt) ?? prompt;

  static OkapiPrompt _buildPrompt(
    OkapiConfig c,
    OkapiPromptKind kind,
    List<OkapiPermission> perms, {
    String? reason,
    Map<OkapiPermission, String> reasons = const {},
    Map<OkapiPermission, OkapiStatus> statuses = const {},
    OkapiFeature? feature,
  }) {
    final s = c.strings;
    final p = perms.first;
    String fill(String t) {
      var out = s.fill(t, p);
      if (reason != null) out = out.replaceAll(s.reasonOf(p), reason);
      return out;
    }

    final names = perms.map(s.nameOf).toSet().join(', ');
    String fillMany(String t) =>
        perms.length == 1 ? fill(t) : t.replaceAll('{permission}', names);

    final reasonMap = {
      for (final q in perms) q: reasons[q] ?? s.reasonOf(q),
    };
    if (reason != null) reasonMap[p] = reason;
    final optional = feature == null
        ? const <OkapiPermission>{}
        : perms.where(feature.isOptional).toSet();
    final featureName = feature?.name;

    OkapiPrompt make(
      String title,
      String message,
      String primary,
      String? secondary,
    ) =>
        OkapiPrompt(
          kind: kind,
          permissions: perms,
          title: title,
          message: message,
          primaryLabel: primary,
          secondaryLabel: secondary,
          reasons: reasonMap,
          statuses: statuses,
          featureName: featureName,
          optional: optional,
        );

    final prompt = switch (kind) {
      OkapiPromptKind.rationale => make(fill(s.rationaleTitle),
          reason ?? fill(s.rationaleMessage), s.rationaleAllow, s.rationaleNotNow),
      OkapiPromptKind.denied => make(fill(s.deniedTitle), fill(s.deniedMessage),
          s.deniedRetry, s.deniedCancel),
      OkapiPromptKind.settings => make(fillMany(s.settingsTitle),
          fillMany(s.settingsMessage), s.settingsOpen, s.settingsCancel),
      OkapiPromptKind.serviceDisabled => make(fill(s.serviceTitle),
          fill(s.serviceMessage), s.serviceOpen, s.serviceCancel),
      OkapiPromptKind.restricted => make(fill(s.restrictedTitle),
          fill(s.restrictedMessage), s.restrictedOk, null),
      OkapiPromptKind.multiRationale => featureName == null
          ? make(s.multiTitle, s.multiMessage, s.multiAllow, s.multiNotNow)
          : make(
              s.fillWith(s.featureTitle, {'feature': featureName}),
              feature?.description ??
                  s.fillWith(s.featureMessage, {'feature': featureName}),
              s.multiAllow,
              s.multiNotNow),
      // Built by their own flows; listed for completeness.
      OkapiPromptKind.autoReset ||
      OkapiPromptKind.backgroundReliability ||
      OkapiPromptKind.backgroundConfirm =>
        make(fill(s.rationaleTitle), fill(s.rationaleMessage), s.rationaleAllow,
            s.rationaleNotNow),
    };
    return _finalize(c, prompt);
  }

  static Future<bool> _show(
      BuildContext context, OkapiPrompt prompt, OkapiConfig c) async {
    final presenter = c.presenter ?? const OkapiSheetPresenter();
    _log('show ${prompt.kind.name} for ${prompt.permissions.map((p) => p.name)}');
    final accepted = await presenter.present(context, prompt);
    for (final o in c.observers) {
      o.onPrompt(prompt, accepted);
    }
    return accepted;
  }

  static OkapiResult _finish(
    OkapiConfig c,
    OkapiPermission p,
    OkapiStatus status,
    OkapiOutcome outcome, {
    int attempts = 0,
    bool openedSettings = false,
    OkapiPolicyDecision? policy,
  }) {
    final result = OkapiResult(
      permission: p,
      status: status,
      outcome: outcome,
      attempts: attempts,
      openedSettings: openedSettings,
      policy: policy,
    );
    _log(result.toString());
    for (final o in c.observers) {
      o.onResult(result);
    }
    return result;
  }

  /// The policy without session/launch rules (cooldowns only).
  static OkapiAskPolicy _cooldownsOnly(OkapiAskPolicy p) =>
      p.copyWith(skipFirstLaunches: 0, maxPromptsPerSession: 0);

  /// The policy without cooldowns (session/launch rules only).
  static OkapiAskPolicy _sessionOnly(OkapiAskPolicy p) => p.copyWith(
        cooldownAfterNotNow: Duration.zero,
        cooldownAfterDenied: Duration.zero,
        cooldownAfterSettingsDecline: Duration.zero,
      );

  static Future<OkapiResult> _runAsk(
    BuildContext context,
    OkapiPermission p,
    OkapiConfig c,
    String? reason,
    bool provisional,
    bool force,
  ) async {
    var attempts = 0;
    var counted = false;

    Future<OkapiPolicyDecision> allowed({required bool settings}) {
      if (force) return Future.value(const OkapiPolicyDecision.allow());
      return OkapiPolicyEngine.check(
          counted ? _cooldownsOnly(c.askPolicy) : c.askPolicy, p.name,
          settings: settings);
    }

    void count() {
      if (counted) return;
      counted = true;
      OkapiPolicyEngine.countPrompt();
    }

    await assertDeclared(p);

    // 1. Service switched off?
    if (c.checkService && p.hasService) {
      if (await serviceStatus(p) == OkapiServiceStatus.disabled) {
        if (!context.mounted) {
          return _finish(c, p, await status(p), OkapiOutcome.serviceDisabled);
        }
        final go = await _show(
          context,
          _buildPrompt(c, OkapiPromptKind.serviceDisabled, [p]),
          c,
        );
        if (go && await openServiceSettings(p)) await nextResume();
        if (await serviceStatus(p) == OkapiServiceStatus.disabled) {
          return _finish(c, p, await status(p), OkapiOutcome.serviceDisabled);
        }
      }
    }

    // 2. Already usable?
    var st = await status(p);
    if (st.canProceed) return _finish(c, p, st, OkapiOutcome.granted);

    // 3. Restricted: explain once, never nag.
    if (st.isRestricted) {
      if (context.mounted) {
        await _show(context, _buildPrompt(c, OkapiPromptKind.restricted, [p]),
            c);
      }
      return _finish(c, p, st, OkapiOutcome.restricted);
    }

    // 4. Can still ask: policy, rationale, request, retry.
    var becameBlockedNow = false;
    if (st.isDenied) {
      final d = await allowed(settings: false);
      if (!d.allowed) {
        return _finish(c, p, st, OkapiOutcome.deferredByPolicy, policy: d);
      }
      final wantRationale = switch (c.rationaleMode) {
        OkapiRationaleMode.always => true,
        OkapiRationaleMode.whenRecommended => await shouldShowRationale(p),
        OkapiRationaleMode.never => false,
      };
      count();
      if (wantRationale) {
        if (!context.mounted) {
          return _finish(c, p, st, OkapiOutcome.dismissedRationale);
        }
        final go = await _show(
          context,
          _buildPrompt(c, OkapiPromptKind.rationale, [p], reason: reason),
          c,
        );
        if (!go) {
          await OkapiPolicyEngine.record(p.name, OkapiPolicyEvent.notNow);
          return _finish(c, p, st, OkapiOutcome.dismissedRationale);
        }
      }

      var retriesLeft = c.maxRetries;
      while (true) {
        st = await request(p, provisional: provisional);
        attempts++;
        if (st.canProceed) {
          return _finish(c, p, st, OkapiOutcome.granted, attempts: attempts);
        }
        if (st.isRestricted) {
          return _finish(c, p, st, OkapiOutcome.restricted,
              attempts: attempts);
        }
        await OkapiPolicyEngine.record(p.name, OkapiPolicyEvent.denied);
        if (st.isPermanentlyDenied) {
          becameBlockedNow = true;
          break;
        }
        if (retriesLeft <= 0 || !context.mounted) {
          return _finish(c, p, st, OkapiOutcome.denied, attempts: attempts);
        }
        retriesLeft--;
        final retry = await _show(
          context,
          _buildPrompt(c, OkapiPromptKind.denied, [p], reason: reason),
          c,
        );
        if (!retry) {
          return _finish(c, p, st, OkapiOutcome.denied, attempts: attempts);
        }
      }
    }

    // 5. Permanently denied: guide to Settings.
    final offer =
        c.offerSettings && (!becameBlockedNow || c.settingsRightAfterRefusal);
    if (!offer || !context.mounted) {
      return _finish(c, p, st, OkapiOutcome.permanentlyDenied,
          attempts: attempts);
    }
    final d = await allowed(settings: true);
    if (!d.allowed) {
      return _finish(c, p, st, OkapiOutcome.deferredByPolicy,
          attempts: attempts, policy: d);
    }
    count();
    if (!context.mounted) {
      return _finish(c, p, st, OkapiOutcome.permanentlyDenied,
          attempts: attempts);
    }
    final go = await _show(
      context,
      _buildPrompt(c, OkapiPromptKind.settings, [p], reason: reason),
      c,
    );
    if (!go) {
      await OkapiPolicyEngine.record(p.name, OkapiPolicyEvent.settingsDecline);
      return _finish(c, p, st, OkapiOutcome.permanentlyDenied,
          attempts: attempts);
    }
    if (await openAppSettings()) await nextResume();
    st = await status(p);
    if (!st.canProceed) {
      await OkapiPolicyEngine.record(p.name, OkapiPolicyEvent.settingsDecline);
    }
    return _finish(
      c,
      p,
      st,
      st.canProceed ? OkapiOutcome.granted : OkapiOutcome.settingsReturnedDenied,
      attempts: attempts,
      openedSettings: true,
    );
  }

  static Future<Map<OkapiPermission, OkapiResult>> _runAskAll(
    BuildContext context,
    List<OkapiPermission> permissions,
    OkapiConfig c,
    Map<OkapiPermission, String> reasons, {
    OkapiFeature? feature,
    bool force = false,
  }) async {
    for (final p in permissions) {
      await assertDeclared(p);
    }
    final results = <OkapiPermission, OkapiResult>{};
    final current = await statuses(permissions);

    var toAsk = <OkapiPermission>[];
    var blocked = <OkapiPermission>[];
    for (final p in permissions) {
      final s = current[p]!;
      if (s.canProceed) {
        results[p] = _finish(c, p, s, OkapiOutcome.granted);
      } else if (s.isRestricted) {
        results[p] = _finish(c, p, s, OkapiOutcome.restricted);
      } else if (s.isPermanentlyDenied) {
        blocked.add(p);
      } else {
        toAsk.add(p);
      }
    }

    // Ask policy: session/launch rules once for the whole flow, then
    // cooldowns per permission.
    if (!force && (toAsk.isNotEmpty || blocked.isNotEmpty)) {
      final session = await OkapiPolicyEngine.check(
          _sessionOnly(c.askPolicy), 'session');
      final cooldowns = _cooldownsOnly(c.askPolicy);
      Future<bool> keep(OkapiPermission p, bool settings) async {
        final d = session.allowed
            ? await OkapiPolicyEngine.check(cooldowns, p.name, settings: settings)
            : session;
        if (d.allowed) return true;
        results[p] = _finish(c, p, current[p]!, OkapiOutcome.deferredByPolicy,
            policy: d);
        return false;
      }

      toAsk = [for (final p in toAsk) if (await keep(p, false)) p];
      if (!c.offerSettings) {
        for (final p in blocked) {
          results[p] = _finish(c, p, current[p]!, OkapiOutcome.permanentlyDenied);
        }
        blocked = [];
      } else {
        blocked = [for (final p in blocked) if (await keep(p, true)) p];
      }
    }
    if (toAsk.isNotEmpty || blocked.isNotEmpty) OkapiPolicyEngine.countPrompt();

    if (toAsk.isNotEmpty) {
      var go = true;
      if (c.rationaleMode != OkapiRationaleMode.never) {
        if (!context.mounted) {
          go = false;
        } else {
          go = await _show(
            context,
            _buildPrompt(c, OkapiPromptKind.multiRationale, toAsk,
                reasons: reasons, statuses: current, feature: feature),
            c,
          );
        }
      }
      if (!go) {
        for (final p in toAsk) {
          await OkapiPolicyEngine.record(p.name, OkapiPolicyEvent.notNow);
          results[p] =
              _finish(c, p, current[p]!, OkapiOutcome.dismissedRationale);
        }
      } else {
        final asked = await requestMany(toAsk);
        for (final p in toAsk) {
          final s = asked[p]!;
          if (!s.canProceed && !s.isRestricted) {
            await OkapiPolicyEngine.record(p.name, OkapiPolicyEvent.denied);
          }
          results[p] = _finish(
            c,
            p,
            s,
            s.canProceed
                ? OkapiOutcome.granted
                : s.isRestricted
                    ? OkapiOutcome.restricted
                    : s.isPermanentlyDenied
                        ? OkapiOutcome.permanentlyDenied
                        : OkapiOutcome.denied,
            attempts: 1,
          );
        }
      }
    }

    if (blocked.isNotEmpty) {
      var opened = false;
      if (c.offerSettings && context.mounted) {
        final prompt = _buildPrompt(c, OkapiPromptKind.settings, blocked,
            reasons: reasons, statuses: current, feature: feature);
        final go = await _show(context, prompt, c);
        if (go && await openAppSettings()) {
          opened = true;
          await nextResume();
        }
      }
      for (final p in blocked) {
        final s = opened ? await status(p) : current[p]!;
        if (!s.canProceed) {
          await OkapiPolicyEngine.record(p.name, OkapiPolicyEvent.settingsDecline);
        }
        results[p] = _finish(
          c,
          p,
          s,
          s.canProceed
              ? OkapiOutcome.granted
              : opened
                  ? OkapiOutcome.settingsReturnedDenied
                  : OkapiOutcome.permanentlyDenied,
          openedSettings: opened,
        );
      }
    }

    // Keep the caller's order.
    return {for (final p in permissions) p: results[p]!};
  }

  /// Display name of [permission] in the configured language.
  static String nameOf(OkapiPermission permission) =>
      _config.strings.nameOf(permission);

  /// The configured strings.
  static OkapiStrings get strings => _config.strings;

  /// Clears Okapi's in-memory state. For tests.
  @visibleForTesting
  static void debugReset() {
    _known.clear();
    _grantedAtLaunch = null;
    _grantedNow = {};
    _grantedChain = Future<void>.value();
    _device = null;
    _deviceOwner = null;
    _config = const OkapiConfig();
    OkapiStore.resetCache();
    OkapiPolicyEngine.debugResetSession();
  }
}

// ── Queue ──────────────────────────────────────────────────────────────────

/// A tiny FIFO lock: tasks run one at a time, in call order.
class _OkapiLock {
  bool _busy = false;
  final List<Completer<void>> _waiting = [];

  Future<T> run<T>(Future<T> Function() task) async {
    if (_busy) {
      final turn = Completer<void>();
      _waiting.add(turn);
      await turn.future;
    } else {
      _busy = true;
    }
    try {
      return await task();
    } finally {
      if (_waiting.isNotEmpty) {
        _waiting.removeAt(0).complete();
      } else {
        _busy = false;
      }
    }
  }
}

// ── Lifecycle ──────────────────────────────────────────────────────────────

final _OkapiLifecycle _lifecycle = _OkapiLifecycle();

class _OkapiLifecycle with WidgetsBindingObserver {
  bool _attached = false;
  final StreamController<void> _resumes = StreamController<void>.broadcast();

  void attach() {
    if (_attached) return;
    try {
      WidgetsBinding.instance.addObserver(this);
      _attached = true;
    } catch (_) {
      // Binding not ready yet (called before runApp). Try again later.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumes.add(null);
      unawaited(Okapi.refreshKnown());
    }
  }

  Future<void> nextResume(Duration timeout) {
    attach();
    return _resumes.stream.first.timeout(timeout, onTimeout: () {});
  }
}
