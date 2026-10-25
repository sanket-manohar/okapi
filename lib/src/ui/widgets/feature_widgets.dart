// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/feature.dart';
import '../../core/okapi.dart';
import '../../core/status.dart';
import '../icons.dart';
import '../theme.dart';

/// Builds UI from a feature's live level.
///
/// `result` is null only during the first check. `ask` runs
/// `Okapi.askFeature` (with `force: true`, because the user tapped).
typedef OkapiFeatureWidgetBuilder = Widget Function(
  BuildContext context,
  OkapiFeatureResult? result,
  Future<OkapiFeatureResult> Function() ask,
);

/// Rebuilds whenever any permission of [feature] changes, including changes
/// made in system settings.
class OkapiFeatureBuilder extends StatefulWidget {
  /// Creates a live feature builder.
  const OkapiFeatureBuilder({
    super.key,
    required this.feature,
    required this.builder,
  });

  /// The feature to watch.
  final OkapiFeature feature;

  /// Builds the UI.
  final OkapiFeatureWidgetBuilder builder;

  @override
  State<OkapiFeatureBuilder> createState() => _OkapiFeatureBuilderState();
}

class _OkapiFeatureBuilderState extends State<OkapiFeatureBuilder> {
  OkapiFeatureResult? _result;
  StreamSubscription<OkapiStatusChange>? _sub;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _sub = Okapi.statusChanges.listen((c) {
      if (widget.feature.permissions.contains(c.permission)) _refresh();
    });
    _refresh();
  }

  @override
  void didUpdateWidget(OkapiFeatureBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feature != widget.feature) _refresh();
  }

  Future<void> _refresh() async {
    final gen = ++_generation;
    try {
      final r = await Okapi.featureStatus(widget.feature);
      if (mounted && gen == _generation) setState(() => _result = r);
    } catch (_) {
      // Leave the last result on screen.
    }
  }

  Future<OkapiFeatureResult> _ask() async {
    final r = await Okapi.askFeature(context, widget.feature, force: true);
    if (mounted) setState(() => _result = r);
    return r;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _result, _ask);
}

/// Shows [child] when [feature] can run; otherwise a card that asks for
/// what's missing.
///
/// With [requireFull], optional permissions are needed too. Use
/// [partialChild] to show a reduced version when only optional ones are
/// missing.
class OkapiFeatureGate extends StatelessWidget {
  /// Creates a feature gate.
  const OkapiFeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.partialChild,
    this.requireFull = false,
    this.lockedBuilder,
    this.loading,
  });

  /// The feature.
  final OkapiFeature feature;

  /// Shown when the feature can run.
  final Widget child;

  /// Shown when only optional permissions are missing.
  final Widget? partialChild;

  /// Treat missing optional permissions as locked.
  final bool requireFull;

  /// Custom locked view.
  final OkapiFeatureWidgetBuilder? lockedBuilder;

  /// Shown during the first check.
  final Widget? loading;

  @override
  Widget build(BuildContext context) => OkapiFeatureBuilder(
        feature: feature,
        builder: (context, result, ask) {
          if (result == null) {
            return loading ??
                const Center(
                  child: SizedBox.square(
                    dimension: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                );
          }
          if (result.isFull) return child;
          if (result.isAvailable && !requireFull) return partialChild ?? child;
          return lockedBuilder?.call(context, result, ask) ??
              OkapiFeatureLockedCard(result: result, onAllow: ask);
        },
      );
}

/// The default locked card for [OkapiFeatureGate].
class OkapiFeatureLockedCard extends StatelessWidget {
  /// Creates the card.
  const OkapiFeatureLockedCard({
    super.key,
    required this.result,
    required this.onAllow,
  });

  /// The feature's current state.
  final OkapiFeatureResult result;

  /// Runs the flow.
  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final s = Okapi.strings;
    final missing = [...result.missingRequired, ...result.missingOptional];
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: t.maxWidth),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final p in missing)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: t.iconBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(okapiIconFor(p), color: t.iconColor),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                s.fillWith(s.featureTitle, {'feature': result.feature.name}),
                textAlign: TextAlign.center,
                style: t.resolvedTitle(context),
              ),
              const SizedBox(height: 8),
              Text(
                result.feature.description ??
                    s.fillWith(s.featureMessage, {'feature': result.feature.name}),
                textAlign: TextAlign.center,
                style: t.resolvedBody(context),
              ),
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
                child: Text(s.allowButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A pill showing a feature's level ("On", "Partly on", "Off").
class OkapiFeatureLevelChip extends StatelessWidget {
  /// Creates a chip.
  const OkapiFeatureLevelChip({super.key, required this.level});

  /// The level.
  final OkapiFeatureLevel level;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final s = Okapi.strings;
    final (label, color, icon) = switch (level) {
      OkapiFeatureLevel.full => (s.levelFull, t.granted, Icons.check_circle_rounded),
      OkapiFeatureLevel.partial => (s.levelPartial, t.warning, Icons.adjust_rounded),
      OkapiFeatureLevel.unavailable => (s.levelOff, t.muted, Icons.radio_button_unchecked_rounded),
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
          Icon(icon, size: 14, color: color),
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
