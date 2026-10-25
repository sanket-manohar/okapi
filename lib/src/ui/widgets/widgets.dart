// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/okapi.dart';
import '../../core/permission.dart';
import '../../core/status.dart';
import '../icons.dart';
import '../theme.dart';
import 'prompt_view.dart';

/// Builds UI from a permission's live status.
///
/// [ask] runs the guided `Okapi.ask` flow for this permission.
typedef OkapiStatusWidgetBuilder = Widget Function(
  BuildContext context,
  OkapiStatus? status,
  Future<OkapiResult> Function() ask,
);

/// Rebuilds whenever [permission]'s status changes, including when the user
/// changes it in system settings and returns to the app.
///
/// `status` is `null` only while the first check is running.
class OkapiPermissionBuilder extends StatefulWidget {
  /// Creates a live status builder.
  const OkapiPermissionBuilder({
    super.key,
    required this.permission,
    required this.builder,
    this.reason,
  });

  /// The permission to watch.
  final OkapiPermission permission;

  /// Builds the UI.
  final OkapiStatusWidgetBuilder builder;

  /// Custom explanation used when [OkapiStatusWidgetBuilder]'s `ask` runs.
  final String? reason;

  @override
  State<OkapiPermissionBuilder> createState() => _OkapiPermissionBuilderState();
}

class _OkapiPermissionBuilderState extends State<OkapiPermissionBuilder> {
  OkapiStatus? _status;
  StreamSubscription<OkapiStatus>? _sub;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(OkapiPermissionBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.permission != widget.permission) {
      _sub?.cancel();
      _status = null;
      _listen();
    }
  }

  void _listen() {
    _sub = Okapi.watch(widget.permission).listen((s) {
      if (mounted) setState(() => _status = s);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<OkapiResult> _ask() =>
      Okapi.ask(context, widget.permission, reason: widget.reason);

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _status, _ask);
}

/// Shows [child] only when [permission] can be used; otherwise shows a
/// polished "allow access" card (or your [lockedBuilder]).
///
/// ```dart
/// OkapiPermissionGate(
///   permission: OkapiPermission.camera,
///   child: CameraPreviewScreen(),
/// )
/// ```
class OkapiPermissionGate extends StatefulWidget {
  /// Creates a gate.
  const OkapiPermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.lockedBuilder,
    this.loading,
    this.reason,
    this.autoAsk = false,
  });

  /// The permission required to see [child].
  final OkapiPermission permission;

  /// Shown when the permission can be used.
  final Widget child;

  /// Custom locked view. Call `ask` to run the flow.
  final OkapiStatusWidgetBuilder? lockedBuilder;

  /// Shown during the very first check. Defaults to a small spinner.
  final Widget? loading;

  /// Explanation shown on the card and in the rationale.
  final String? reason;

  /// Run the flow automatically the first time the gate is shown.
  final bool autoAsk;

  @override
  State<OkapiPermissionGate> createState() => _OkapiPermissionGateState();
}

class _OkapiPermissionGateState extends State<OkapiPermissionGate> {
  bool _autoAsked = false;

  @override
  Widget build(BuildContext context) => OkapiPermissionBuilder(
        permission: widget.permission,
        reason: widget.reason,
        builder: (context, status, ask) {
          if (status == null) {
            return widget.loading ??
                const Center(
                  child: SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
          }
          if (status.canProceed) return widget.child;
          if (widget.autoAsk && !_autoAsked && status.isDenied) {
            _autoAsked = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) ask();
            });
          }
          return widget.lockedBuilder?.call(context, status, ask) ??
              OkapiLockedCard(
                permission: widget.permission,
                status: status,
                reason: widget.reason,
                onAllow: ask,
              );
        },
      );
}

/// The default "allow access" card used by [OkapiPermissionGate].
class OkapiLockedCard extends StatelessWidget {
  /// Creates the card.
  const OkapiLockedCard({
    super.key,
    required this.permission,
    required this.status,
    required this.onAllow,
    this.reason,
  });

  /// Which permission is missing.
  final OkapiPermission permission;

  /// Its current status.
  final OkapiStatus status;

  /// Called when the user taps the button.
  final VoidCallback onAllow;

  /// Explanation text.
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final s = Okapi.strings;
    final blocked = status.isPermanentlyDenied;
    final restricted = status.isRestricted;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: t.maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OkapiIconBadge(
                permission: permission,
                color: blocked ? t.danger : restricted ? t.warning : null,
              ),
              const SizedBox(height: 20),
              Text(
                blocked
                    ? s.fill(s.settingsTitle, permission)
                    : s.fill(s.rationaleTitle, permission),
                textAlign: TextAlign.center,
                style: t.resolvedTitle(context),
              ),
              const SizedBox(height: 8),
              Text(
                restricted
                    ? s.fill(s.restrictedMessage, permission)
                    : reason ?? s.reasonOf(permission),
                textAlign: TextAlign.center,
                style: t.resolvedBody(context),
              ),
              if (!restricted) ...[
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: onAllow,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: t.onPrimary,
                    minimumSize: const Size(200, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(t.buttonRadius),
                    ),
                    textStyle: t.resolvedButton(context),
                  ),
                  child: Text(blocked ? s.settingsOpen : s.allowButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A small coloured pill showing a status.
class OkapiStatusChip extends StatelessWidget {
  /// Creates a chip.
  const OkapiStatusChip({super.key, required this.status});

  /// The status to show.
  final OkapiStatus status;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final s = Okapi.strings;
    final (label, color) = switch (status) {
      OkapiStatus.granted => (s.statusGranted, t.granted),
      OkapiStatus.limited => (s.statusLimited, t.warning),
      OkapiStatus.provisional => (s.statusProvisional, t.granted),
      OkapiStatus.denied => (s.statusDenied, t.muted),
      OkapiStatus.permanentlyDenied => (s.statusPermanentlyDenied, t.danger),
      OkapiStatus.restricted => (s.statusRestricted, t.warning),
      OkapiStatus.notApplicable => (s.statusNotApplicable, t.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(okapiStatusIcon(status), size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A list row for one permission: icon, name, reason, and a status chip or
/// an "Allow" button. Updates live.
class OkapiPermissionTile extends StatelessWidget {
  /// Creates a tile.
  const OkapiPermissionTile({
    super.key,
    required this.permission,
    this.reason,
    this.onResult,
    this.showReason = true,
  });

  /// The permission.
  final OkapiPermission permission;

  /// Custom explanation.
  final String? reason;

  /// Called after the user goes through the flow from this tile.
  final ValueChanged<OkapiResult>? onResult;

  /// Show the reason line under the name.
  final bool showReason;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    return OkapiPermissionBuilder(
      permission: permission,
      reason: reason,
      builder: (context, status, ask) {
        final canAsk = status != null &&
            (status.isDenied || status.isPermanentlyDenied);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: t.iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(okapiIconFor(permission),
                    color: t.iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Okapi.nameOf(permission),
                      style: t.resolvedBody(context).copyWith(
                            color: t.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (showReason)
                      Text(
                        reason ?? Okapi.strings.reasonOf(permission),
                        style:
                            t.resolvedBody(context).copyWith(fontSize: 13.5),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (status == null)
                const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (canAsk)
                FilledButton.tonal(
                  onPressed: () async {
                    final r = await ask();
                    onResult?.call(r);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primary.withAlpha(26),
                    foregroundColor: t.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(t.buttonRadius),
                    ),
                  ),
                  child: Text(status.isPermanentlyDenied
                      ? Okapi.strings.settingsOpen
                      : Okapi.strings.allowButton),
                )
              else
                OkapiStatusChip(status: status),
            ],
          ),
        );
      },
    );
  }
}

/// A ready-made onboarding screen listing several permissions, each with its
/// own "Allow" button, an optional "Allow all", and a Continue button.
class OkapiOnboarding extends StatefulWidget {
  /// Creates an onboarding page.
  const OkapiOnboarding({
    super.key,
    required this.permissions,
    required this.onComplete,
    this.requiredPermissions = const [],
    this.reasons = const {},
    this.title,
    this.subtitle,
    this.header,
    this.showAllowAll = true,
  });

  /// Permissions to list, in order.
  final List<OkapiPermission> permissions;

  /// Permissions that must be usable before Continue is enabled.
  final List<OkapiPermission> requiredPermissions;

  /// Custom reason per permission.
  final Map<OkapiPermission, String> reasons;

  /// Called with the final statuses when the user taps Continue.
  final ValueChanged<Map<OkapiPermission, OkapiStatus>> onComplete;

  /// Headline; defaults to the strings' multi-permission title.
  final String? title;

  /// Sub-headline.
  final String? subtitle;

  /// Any widget above the title (logo, illustration...).
  final Widget? header;

  /// Show an "Allow all" button.
  final bool showAllowAll;

  @override
  State<OkapiOnboarding> createState() => _OkapiOnboardingState();
}

class _OkapiOnboardingState extends State<OkapiOnboarding> {
  StreamSubscription<OkapiStatusChange>? _sub;
  bool _requiredOk = false;

  @override
  void initState() {
    super.initState();
    _sub = Okapi.statusChanges.listen((_) => _check());
    _check();
  }

  Future<void> _check() async {
    final st = await Okapi.statuses(widget.requiredPermissions);
    if (!mounted) return;
    setState(() => _requiredOk = st.values.every((s) => s.canProceed));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _finish() async {
    final st = await Okapi.statuses(widget.permissions);
    widget.onComplete(st);
  }

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final s = Okapi.strings;
    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: t.maxWidth + 60),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
                    children: [
                      if (widget.header != null) ...[
                        widget.header!,
                        const SizedBox(height: 24),
                      ],
                      Text(
                        widget.title ?? s.multiTitle,
                        style: t
                            .resolvedTitle(context)
                            .copyWith(fontSize: 28, height: 1.15),
                      ),
                      const SizedBox(height: 10),
                      Text(widget.subtitle ?? s.multiMessage,
                          style: t.resolvedBody(context)),
                      const SizedBox(height: 24),
                      for (final p in widget.permissions)
                        OkapiPermissionTile(
                          permission: p,
                          reason: widget.reasons[p],
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.showAllowAll)
                        OutlinedButton(
                          onPressed: () => Okapi.askAll(
                            context,
                            widget.permissions,
                            reasons: widget.reasons,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: t.primary,
                            side: BorderSide(color: t.primary.withAlpha(90)),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(t.buttonRadius),
                            ),
                            textStyle: t.resolvedButton(context),
                          ),
                          child: Text(s.multiAllow),
                        ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: _requiredOk ? _finish : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: t.primary,
                          foregroundColor: t.onPrimary,
                          disabledBackgroundColor: t.primary.withAlpha(60),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(t.buttonRadius),
                          ),
                          textStyle: t.resolvedButton(context),
                        ),
                        child: Text(s.continueButton),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
