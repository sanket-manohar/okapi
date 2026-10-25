// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/okapi.dart';
import '../../core/permission.dart';
import '../icons.dart';
import '../theme.dart';

/// The round icon badge used across Okapi's UI.
class OkapiIconBadge extends StatelessWidget {
  /// Creates a badge for [permission], or for a custom [icon].
  const OkapiIconBadge({
    super.key,
    this.permission,
    this.icon,
    this.size,
    this.theme,
    this.color,
  }) : assert(
          permission != null || icon != null,
          'Pass a permission or an icon.',
        );

  /// Which permission's icon to show.
  final OkapiPermission? permission;

  /// A custom icon, used when [permission] is null.
  final IconData? icon;

  /// Diameter; defaults to the theme's badge size.
  final double? size;

  /// Theme override.
  final OkapiThemeData? theme;

  /// Tint override (for example the danger colour on Settings prompts).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = theme ?? OkapiThemeData.of(context);
    final p = permission;
    if (t.visualBuilder != null && p != null) {
      return t.visualBuilder!(context, p, t);
    }
    final d = size ?? t.iconBadgeSize;
    final tint = color ?? t.iconColor;
    final inner = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color != null ? color!.withAlpha(30) : t.iconBackground,
      ),
      alignment: Alignment.center,
      child: Icon(
        p != null ? okapiIconFor(p) : icon,
        size: d * 0.46,
        color: tint,
      ),
    );
    if (!t.useGradientBadge) return inner;
    return Container(
      padding: EdgeInsets.all(d * 0.09),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint.withAlpha(56), tint.withAlpha(8)],
        ),
      ),
      child: inner,
    );
  }
}

/// The body of every built-in prompt. Reuse it inside your own presenters to
/// keep Okapi's layout with your own container.
class OkapiPromptView extends StatelessWidget {
  /// Creates the view for [prompt].
  const OkapiPromptView({
    super.key,
    required this.prompt,
    required this.onPrimary,
    this.onSecondary,
    this.theme,
    this.expanded = false,
  });

  /// What to show.
  final OkapiPrompt prompt;

  /// Called for the primary button.
  final VoidCallback onPrimary;

  /// Called for the secondary button.
  final VoidCallback? onSecondary;

  /// Theme override.
  final OkapiThemeData? theme;

  /// Larger, airier layout for full-screen presentation.
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final t = theme ?? OkapiThemeData.of(context);
    final isSettings = prompt.kind == OkapiPromptKind.settings;
    final usesIcon = prompt.icon != null || !prompt.hasPermission;
    final isMulti = !usesIcon &&
        (prompt.kind == OkapiPromptKind.multiRationale ||
            (isSettings && prompt.permissions.length > 1));
    final badgeColor = switch (prompt.kind) {
      OkapiPromptKind.settings => t.danger,
      OkapiPromptKind.restricted ||
      OkapiPromptKind.serviceDisabled ||
      OkapiPromptKind.autoReset ||
      OkapiPromptKind.backgroundReliability =>
        t.warning,
      _ => null,
    };
    final align = isMulti ? TextAlign.start : TextAlign.center;

    final children = <Widget>[
      if (!isMulti)
        Center(
          child: OkapiIconBadge(
            permission: usesIcon ? null : prompt.permission,
            icon: prompt.icon ?? Icons.verified_user_rounded,
            theme: t,
            color: badgeColor,
            size: expanded ? t.iconBadgeSize * 1.5 : null,
          ),
        ),
      SizedBox(height: expanded ? 32 : 20),
      Text(
        prompt.title,
        textAlign: align,
        style:
            t.resolvedTitle(context).copyWith(fontSize: expanded ? 28 : null),
      ),
      const SizedBox(height: 10),
      Text(prompt.message, textAlign: align, style: t.resolvedBody(context)),
      if (isMulti) ...[
        const SizedBox(height: 18),
        for (final p in prompt.permissions)
          _ReasonRow(
            permission: p,
            reason: prompt.reasons[p],
            theme: t,
            optional: prompt.optional.contains(p),
          ),
      ],
      if (prompt.steps.isNotEmpty) ...[
        const SizedBox(height: 18),
        OkapiStepList(steps: prompt.steps, theme: t),
      ],
      if (isSettings && t.showSettingsSteps && prompt.hasPermission) ...[
        const SizedBox(height: 18),
        _SettingsSteps(theme: t, permission: prompt.permission),
      ],
      SizedBox(height: expanded ? 40 : 26),
      _PrimaryButton(label: prompt.primaryLabel, onTap: onPrimary, theme: t),
      if (prompt.secondaryLabel != null) ...[
        const SizedBox(height: 6),
        TextButton(
          onPressed: onSecondary,
          style: TextButton.styleFrom(
            foregroundColor: t.muted,
            minimumSize: const Size.fromHeight(48),
            textStyle: t.resolvedButton(context),
          ),
          child: Text(prompt.secondaryLabel!),
        ),
      ],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    required this.theme,
  });

  final String label;
  final VoidCallback onTap;
  final OkapiThemeData theme;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: theme.primary,
          foregroundColor: theme.onPrimary,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.buttonRadius),
          ),
          textStyle: theme.resolvedButton(context),
          elevation: 0,
        ),
        child: Text(label),
      );
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.permission,
    required this.reason,
    required this.theme,
    this.optional = false,
  });

  final OkapiPermission permission;
  final String? reason;
  final OkapiThemeData theme;
  final bool optional;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.iconBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                okapiIconFor(permission),
                size: 22,
                color: theme.iconColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        Okapi.nameOf(permission),
                        style: theme.resolvedBody(context).copyWith(
                              color: theme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (optional)
                        OkapiTag(label: Okapi.strings.optionalLabel),
                    ],
                  ),
                  if (reason != null)
                    Text(
                      reason!,
                      style:
                          theme.resolvedBody(context).copyWith(fontSize: 13.5),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SettingsSteps extends StatelessWidget {
  const _SettingsSteps({required this.theme, required this.permission});

  final OkapiThemeData theme;
  final OkapiPermission permission;

  @override
  Widget build(BuildContext context) {
    final strings = Okapi.strings;
    final steps = [
      strings.stepSettings,
      strings.stepPermissions,
      strings.nameOf(permission),
    ];
    final style = theme.resolvedBody(context).copyWith(
          fontSize: 13,
          color: theme.onSurface,
          fontWeight: FontWeight.w600,
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.iconBackground.withAlpha(140),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Text(steps[i], style: style),
            if (i < steps.length - 1)
              Icon(Icons.chevron_right_rounded, size: 18, color: theme.muted),
          ],
          Icon(Icons.toggle_on_rounded, size: 26, color: theme.granted),
        ],
      ),
    );
  }
}

/// A small rounded label, for example "Optional".
class OkapiTag extends StatelessWidget {
  /// Creates a tag.
  const OkapiTag({super.key, required this.label, this.color});

  /// The text.
  final String label;

  /// Tint; defaults to the theme's muted colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final c = color ?? t.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlpha(24),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// A numbered list of instructions, used by the phone-maker guide and the
/// auto-reset prompt. Reusable in your own screens.
class OkapiStepList extends StatelessWidget {
  /// Creates a list.
  const OkapiStepList({super.key, required this.steps, this.theme});

  /// One sentence per step.
  final List<String> steps;

  /// Theme override.
  final OkapiThemeData? theme;

  @override
  Widget build(BuildContext context) {
    final t = theme ?? OkapiThemeData.of(context);
    final body = t.resolvedBody(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.iconBackground.withAlpha(120),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.primary,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: t.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: body.copyWith(
                        color: t.onSurface,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
