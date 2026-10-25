// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/background.dart';
import '../../core/device.dart';
import '../../core/feature.dart';
import '../../core/okapi.dart';
import '../../core/permission.dart';
import '../../core/status.dart';
import '../icons.dart';
import '../theme.dart';
import 'feature_widgets.dart';
import 'prompt_view.dart';
import 'widgets.dart';

/// A ready-made "Privacy & permissions" screen for your app's settings.
///
/// Lists your features and permissions with live status and a reason for
/// each, lets users allow or manage them, and (on Android) adds cards for
/// background reliability and unused-app protection.
///
/// ```dart
/// Navigator.of(context).push(MaterialPageRoute(
///   builder: (_) => OkapiPrivacyCenter(
///     features: [videoCall, nearbyStores],
///     permissions: [OkapiPermission.notification],
///     onOpenPrivacyPolicy: () => launchUrl(policyUrl),
///   ),
/// ));
/// ```
class OkapiPrivacyCenter extends StatefulWidget {
  /// Creates the screen.
  const OkapiPrivacyCenter({
    super.key,
    this.features = const [],
    this.permissions = const [],
    this.reasons = const {},
    this.title,
    this.intro,
    this.header,
    this.showBackgroundReliability = true,
    this.showAutoReset = true,
    this.onOpenPrivacyPolicy,
    this.asPage = true,
  });

  /// Features to show as cards.
  final List<OkapiFeature> features;

  /// Extra permissions to list individually.
  final List<OkapiPermission> permissions;

  /// Reasons for [permissions].
  final Map<OkapiPermission, String> reasons;

  /// Title; defaults to `OkapiStrings.privacyTitle`.
  final String? title;

  /// Intro; defaults to `OkapiStrings.privacyIntro`.
  final String? intro;

  /// Any widget above the title (logo, illustration).
  final Widget? header;

  /// Show the phone-maker background card on Android when relevant.
  final bool showBackgroundReliability;

  /// Show the unused-app protection card on Android when relevant.
  final bool showAutoReset;

  /// Adds a "Privacy policy" link at the bottom.
  final VoidCallback? onOpenPrivacyPolicy;

  /// Wrap in a Scaffold with a back button. Set false to embed in your own
  /// page.
  final bool asPage;

  @override
  State<OkapiPrivacyCenter> createState() => _OkapiPrivacyCenterState();
}

class _OkapiPrivacyCenterState extends State<OkapiPrivacyCenter> {
  OkapiBackgroundResult? _background;
  OkapiAutoResetStatus? _autoReset;
  OkapiDeviceInfo _device = const OkapiDeviceInfo.unknown();
  StreamSubscription<OkapiStatusChange>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = Okapi.statusChanges.listen((_) => _refreshCards());
    _refreshCards();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _refreshCards() async {
    final device = await Okapi.deviceInfo();
    final bg = widget.showBackgroundReliability && device.isAndroid
        ? await Okapi.backgroundStatus()
        : null;
    final ar = widget.showAutoReset && device.isAndroid
        ? await Okapi.autoResetStatus()
        : null;
    if (!mounted) return;
    setState(() {
      _device = device;
      _background = bg;
      _autoReset = ar;
    });
  }

  bool get _showBackground {
    final b = _background;
    if (b == null || !b.applicable) return false;
    return b.brand.restrictsBackground ||
        b.autostartAvailable ||
        b.batteryUnrestricted != null;
  }

  bool get _showAutoReset =>
      _autoReset == OkapiAutoResetStatus.enabled ||
      _autoReset == OkapiAutoResetStatus.exempt;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final s = Okapi.strings;
    final listed = widget.permissions
        .where((p) => !widget.features.any((f) => f.permissions.contains(p)))
        .toList();

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: 20),
        ],
        Text(
          widget.title ?? s.privacyTitle,
          style: t.resolvedTitle(context).copyWith(fontSize: 28, height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(widget.intro ?? s.privacyIntro, style: t.resolvedBody(context)),
        if (widget.features.isNotEmpty) ...[
          _SectionLabel(s.privacyFeatures),
          for (final f in widget.features) _FeatureCard(feature: f),
        ],
        if (listed.isNotEmpty) ...[
          _SectionLabel(s.privacyPermissions),
          _Card(
            child: Column(
              children: [
                for (var i = 0; i < listed.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: t.muted.withAlpha(40)),
                  _PermissionRow(
                    permission: listed[i],
                    reason: widget.reasons[listed[i]],
                  ),
                ],
              ],
            ),
          ),
        ],
        if (_showBackground || _showAutoReset) const SizedBox(height: 8),
        if (_showBackground)
          _InfoCard(
            icon: Icons.battery_saver_rounded,
            title: s.privacyBackground,
            body: s.fillWith(s.privacyBackgroundBody, {
              'brand': _background!.brand.displayName,
              'app': _device.appName,
            }),
            ok: _background!.ready,
            okLabel: s.levelFull,
            actionLabel: s.privacyBackgroundAction,
            onAction: () async {
              await Okapi.askBackgroundReliability(context, force: true);
              await _refreshCards();
            },
          ),
        if (_showAutoReset)
          _InfoCard(
            icon: Icons.restore_rounded,
            title: s.privacyAutoReset,
            body: _autoReset == OkapiAutoResetStatus.exempt
                ? s.privacyAutoResetOff
                : s.privacyAutoResetOn,
            ok: _autoReset == OkapiAutoResetStatus.exempt,
            okLabel: s.privacyProtected,
            actionLabel: s.privacyAutoResetAction,
            onAction: () async {
              await Okapi.protectFromAutoReset(context, force: true);
              await _refreshCards();
            },
          ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: Okapi.openAppSettings,
          icon: const Icon(Icons.settings_rounded, size: 18),
          label: Text(s.privacyManageAll),
          style: OutlinedButton.styleFrom(
            foregroundColor: t.primary,
            side: BorderSide(color: t.primary.withAlpha(90)),
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.buttonRadius),
            ),
            textStyle: t.resolvedButton(context),
          ),
        ),
        if (widget.onOpenPrivacyPolicy != null)
          TextButton(
            onPressed: widget.onOpenPrivacyPolicy,
            style: TextButton.styleFrom(foregroundColor: t.muted),
            child: Text(s.privacyPolicy),
          ),
      ],
    );

    if (!widget.asPage) return content;
    return Scaffold(
      backgroundColor: t.surface,
      appBar: AppBar(
        backgroundColor: t.surface,
        foregroundColor: t.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: t.maxWidth + 120),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: t.muted,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: t.iconBackground.withAlpha(70),
        borderRadius: BorderRadius.circular(t.radius * 0.7),
        border: Border.all(color: t.muted.withAlpha(36)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});
  final OkapiFeature feature;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final s = Okapi.strings;
    return OkapiFeatureBuilder(
      feature: feature,
      builder: (context, result, ask) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.name,
                          style: t.resolvedBody(context).copyWith(
                                color: t.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                        ),
                        if (feature.description != null)
                          Text(
                            feature.description!,
                            style: t
                                .resolvedBody(context)
                                .copyWith(fontSize: 13.5),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (result != null)
                    OkapiFeatureLevelChip(level: result.level),
                ],
              ),
            ),
            for (final p in feature.permissions)
              _PermissionRow(
                permission: p,
                reason: feature.reasons[p],
                optional: feature.isOptional(p),
                dense: true,
              ),
            if (result != null && !result.isFull)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                child: FilledButton(
                  onPressed: ask,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: t.onPrimary,
                    minimumSize: const Size.fromHeight(46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(t.buttonRadius),
                    ),
                  ),
                  child: Text(s.allowButton),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.permission,
    this.reason,
    this.optional = false,
    this.dense = false,
  });

  final OkapiPermission permission;
  final String? reason;
  final bool optional;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final s = Okapi.strings;
    return OkapiPermissionBuilder(
      permission: permission,
      reason: reason,
      builder: (context, status, ask) {
        Widget trailing;
        if (status == null) {
          trailing = const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (status.isDenied || status.isPermanentlyDenied) {
          trailing = FilledButton.tonal(
            onPressed: () =>
                Okapi.ask(context, permission, reason: reason, force: true),
            style: FilledButton.styleFrom(
              backgroundColor: t.primary.withAlpha(26),
              foregroundColor: t.primary,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.buttonRadius),
              ),
            ),
            child: Text(
              status.isPermanentlyDenied ? s.settingsOpen : s.allowButton,
            ),
          );
        } else if (status.isGranted ||
            status.isLimited ||
            status.isProvisional) {
          trailing = Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OkapiStatusChip(status: status),
              GestureDetector(
                onTap: Okapi.openAppSettings,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    s.manageButton,
                    style: TextStyle(
                      color: t.primary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else {
          trailing = OkapiStatusChip(status: status);
        }
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: dense ? 8 : 12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: t.iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  okapiIconFor(permission),
                  color: t.iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          s.nameOf(permission),
                          style: t.resolvedBody(context).copyWith(
                                color: t.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (optional) OkapiTag(label: s.optionalLabel),
                      ],
                    ),
                    Text(
                      reason ?? s.reasonOf(permission),
                      style: t.resolvedBody(context).copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing,
            ],
          ),
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.ok,
    required this.okLabel,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool ok;
  final String okLabel;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (ok ? t.granted : t.warning).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: ok ? t.granted : t.warning, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.resolvedBody(context).copyWith(
                          color: t.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: t.resolvedBody(context).copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 10),
                  if (ok)
                    OkapiTag(label: okLabel, color: t.granted)
                  else
                    FilledButton.tonal(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: t.primary.withAlpha(26),
                        foregroundColor: t.primary,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(t.buttonRadius),
                        ),
                      ),
                      child: Text(actionLabel),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
