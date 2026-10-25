// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../widgets/prompt_view.dart';
import 'route.dart';

/// Default presenter: a modern bottom sheet with blurred background.
class OkapiSheetPresenter extends OkapiPresenter {
  /// Creates the sheet presenter.
  const OkapiSheetPresenter();

  @override
  Future<bool> present(BuildContext context, OkapiPrompt prompt) =>
      showOkapiRoute(
        context,
        style: OkapiPresentationStyle.sheet,
        dismissible: prompt.secondaryLabel != null,
        builder: (c) => OkapiSheetFrame(
          child: OkapiPromptView(
            prompt: prompt,
            onPrimary: () => Navigator.of(c).pop(true),
            onSecondary: () => Navigator.of(c).pop(false),
          ),
        ),
      );
}

/// A centred dialog.
class OkapiDialogPresenter extends OkapiPresenter {
  /// Creates the dialog presenter.
  const OkapiDialogPresenter();

  @override
  Future<bool> present(BuildContext context, OkapiPrompt prompt) =>
      showOkapiRoute(
        context,
        style: OkapiPresentationStyle.dialog,
        dismissible: prompt.secondaryLabel != null,
        builder: (c) => OkapiDialogFrame(
          child: OkapiPromptView(
            prompt: prompt,
            onPrimary: () => Navigator.of(c).pop(true),
            onSecondary: () => Navigator.of(c).pop(false),
          ),
        ),
      );
}

/// A full-screen page, great for onboarding-style explanations.
class OkapiFullScreenPresenter extends OkapiPresenter {
  /// Creates the full-screen presenter.
  const OkapiFullScreenPresenter();

  @override
  Future<bool> present(BuildContext context, OkapiPrompt prompt) =>
      showOkapiRoute(
        context,
        style: OkapiPresentationStyle.fullScreen,
        builder: (c) => OkapiFullScreenFrame(
          child: OkapiPromptView(
            prompt: prompt,
            expanded: true,
            onPrimary: () => Navigator.of(c).pop(true),
            onSecondary: () => Navigator.of(c).pop(false),
          ),
        ),
      );
}

/// Picks a different presenter per prompt kind, for example a full-screen
/// explanation but a small dialog for "Open Settings".
class OkapiMixedPresenter extends OkapiPresenter {
  /// Creates a mixed presenter. Kinds not in [byKind] use [fallback].
  const OkapiMixedPresenter({
    this.byKind = const {},
    this.fallback = const OkapiSheetPresenter(),
  });

  /// Presenter per prompt kind.
  final Map<OkapiPromptKind, OkapiPresenter> byKind;

  /// Presenter for every other kind.
  final OkapiPresenter fallback;

  @override
  Future<bool> present(BuildContext context, OkapiPrompt prompt) =>
      (byKind[prompt.kind] ?? fallback).present(context, prompt);
}

/// Shows no Okapi UI at all: explanations are skipped (the system dialog is
/// shown straight away) and retry / Settings offers are declined. Use it when
/// you want Okapi's logic with zero extra screens.
class OkapiNoUiPresenter extends OkapiPresenter {
  /// Creates the no-UI presenter.
  const OkapiNoUiPresenter();

  @override
  Future<bool> present(BuildContext context, OkapiPrompt prompt) async =>
      prompt.kind == OkapiPromptKind.rationale ||
      prompt.kind == OkapiPromptKind.multiRationale;
}

/// Wraps a plain function as a presenter, for full control (your own routes,
/// another UI library, a native dialog...).
class OkapiFunctionPresenter extends OkapiPresenter {
  /// Creates a presenter from [onPresent].
  const OkapiFunctionPresenter(this.onPresent);

  /// Called for every prompt. Return `true` for the primary action.
  final Future<bool> Function(BuildContext context, OkapiPrompt prompt)
  onPresent;

  @override
  Future<bool> present(BuildContext context, OkapiPrompt prompt) =>
      onPresent(context, prompt);
}
