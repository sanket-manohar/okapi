// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted.

import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/okapi.dart';
import '../../core/permission.dart';
import '../../core/status.dart';
import '../../core/strings.dart';
import '../icons.dart';
import '../theme.dart';
import 'route.dart';
import 'sheet_presenter.dart';

/// Builds your own widget for a prompt.
///
/// Use [controller] to answer the prompt and to reach Okapi's helpers.
typedef OkapiPromptBuilder = Widget Function(
  BuildContext context,
  OkapiPrompt prompt,
  OkapiPromptController controller,
);

/// Handed to your custom prompt widget. Call [accept] or [decline] exactly
/// once; Okapi continues the flow from there.
class OkapiPromptController {
  OkapiPromptController._(this.prompt, this.theme, this._complete);

  /// The prompt being shown (title, message, labels, permissions...).
  final OkapiPrompt prompt;

  /// The resolved Okapi theme, so your widget can match it.
  final OkapiThemeData theme;

  final void Function(bool) _complete;
  bool _done = false;

  /// Whether the prompt has been answered.
  bool get isDone => _done;

  /// The primary action ("Continue", "Try again", "Open Settings").
  void accept() => _answer(true);

  /// The secondary action ("Not now", "Cancel"), or dismissal.
  void decline() => _answer(false);

  void _answer(bool value) {
    if (_done) return;
    _done = true;
    _complete(value);
  }

  /// Opens app settings. On a Settings prompt this is the same as [accept]
  /// (Okapi opens Settings and re-checks on return). Elsewhere it opens
  /// Settings and declines the prompt.
  Future<void> openSettings() async {
    if (prompt.kind == OkapiPromptKind.settings) {
      accept();
      return;
    }
    await Okapi.openAppSettings();
    decline();
  }

  /// Reads a permission's current status.
  Future<OkapiStatus> status(OkapiPermission permission) =>
      Okapi.status(permission);

  /// Display name of a permission in the configured language.
  String nameOf(OkapiPermission permission) => Okapi.nameOf(permission);

  /// The icon Okapi uses for a permission.
  IconData iconOf(OkapiPermission permission) => okapiIconFor(permission);

  /// All configured strings.
  OkapiStrings get strings => Okapi.strings;
}

/// Show your own widgets for prompts while Okapi runs the logic.
///
/// ```dart
/// Okapi.configure(OkapiConfig(
///   presenter: OkapiCustomPresenter(
///     style: OkapiPresentationStyle.dialog,
///     builder: (context, prompt, c) => MyPermissionCard(
///       title: prompt.title,
///       onYes: c.accept,
///       onNo: c.decline,
///     ),
///   ),
/// ));
/// ```
///
/// Provide one [builder] for everything, or per-kind [builders]. Kinds with
/// no builder use [fallback]. Set [wrapInFrame] to `false` to draw the whole
/// container yourself (only the blur and animation are kept).
class OkapiCustomPresenter extends OkapiPresenter {
  /// Creates a custom presenter.
  const OkapiCustomPresenter({
    this.builder,
    this.builders = const {},
    this.style = OkapiPresentationStyle.sheet,
    this.wrapInFrame = true,
    this.fallback = const OkapiSheetPresenter(),
  });

  /// Builder for every prompt kind not in [builders].
  final OkapiPromptBuilder? builder;

  /// Builders per prompt kind.
  final Map<OkapiPromptKind, OkapiPromptBuilder> builders;

  /// How the route enters the screen.
  final OkapiPresentationStyle style;

  /// Wrap your widget in Okapi's sheet/dialog/page container.
  final bool wrapInFrame;

  /// Used for kinds with no builder.
  final OkapiPresenter fallback;

  @override
  Future<bool> present(BuildContext context, OkapiPrompt prompt) {
    final b = builders[prompt.kind] ?? builder;
    if (b == null) return fallback.present(context, prompt);
    final theme = OkapiThemeData.of(context);
    return showOkapiRoute(
      context,
      style: style,
      dismissible: prompt.secondaryLabel != null,
      builder: (c) {
        final controller = OkapiPromptController._(
          prompt,
          theme,
          (v) => Navigator.of(c).pop(v),
        );
        final child = b(c, prompt, controller);
        if (!wrapInFrame) return child;
        return switch (style) {
          OkapiPresentationStyle.sheet => OkapiSheetFrame(child: child),
          OkapiPresentationStyle.dialog => OkapiDialogFrame(child: child),
          OkapiPresentationStyle.fullScreen =>
            OkapiFullScreenFrame(child: child),
        };
      },
    );
  }
}
