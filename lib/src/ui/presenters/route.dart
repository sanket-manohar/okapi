// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted.

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';

/// How a prompt enters the screen.
enum OkapiPresentationStyle {
  /// Slides up from the bottom (default).
  sheet,

  /// Fades and scales in at the centre.
  dialog,

  /// Covers the whole screen.
  fullScreen,
}

/// Pushes an Okapi-styled route and resolves with `true`/`false`.
///
/// Dismissing (back button, tapping outside, swiping down) resolves `false`.
/// Public so custom presenters can reuse Okapi's blur and animations.
Future<bool> showOkapiRoute(
  BuildContext context, {
  required OkapiPresentationStyle style,
  required WidgetBuilder builder,
  bool dismissible = true,
}) async {
  final theme = OkapiThemeData.of(context);
  Widget themed(BuildContext c) => OkapiTheme(data: theme, child: builder(c));

  if (style == OkapiPresentationStyle.fullScreen) {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        fullscreenDialog: true,
        opaque: true,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (c, _, __) => themed(c),
        transitionsBuilder: (c, anim, _, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                  .animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    return result ?? false;
  }

  final isSheet = style == OkapiPresentationStyle.sheet;
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.transparent,
    transitionDuration: Duration(milliseconds: isSheet ? 340 : 260),
    pageBuilder: (c, _, __) => themed(c),
    transitionBuilder: (c, anim, _, child) {
      final curved = CurvedAnimation(
        parent: anim,
        curve: isSheet ? Curves.easeOutCubic : Curves.easeOutBack,
        reverseCurve: Curves.easeInCubic,
      );
      final content = isSheet
          ? SlideTransition(
              position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                  .animate(curved),
              child: child,
            )
          : FadeTransition(
              opacity: anim,
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(curved),
                child: child,
              ),
            );
      return Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, __) {
                  final v = anim.value.clamp(0.0, 1.0);
                  final barrier = ColoredBox(
                    color: theme.barrierColor
                        .withAlpha((theme.barrierColor.a * 255 * v).round()),
                  );
                  if (theme.blurSigma <= 0) return barrier;
                  return BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: theme.blurSigma * v,
                      sigmaY: theme.blurSigma * v,
                    ),
                    child: barrier,
                  );
                },
              ),
            ),
          ),
          content,
        ],
      );
    },
  );
  return result ?? false;
}

/// The rounded sheet container Okapi uses. Swipe down to dismiss.
class OkapiSheetFrame extends StatelessWidget {
  /// Wraps [child] in Okapi's sheet chrome.
  const OkapiSheetFrame({super.key, required this.child});

  /// Sheet contents.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: t.maxWidth),
        child: GestureDetector(
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) > 350) {
              Navigator.of(context).maybePop(false);
            }
          },
          child: Material(
            color: t.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(t.radius)),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (t.showHandle)
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: t.muted.withAlpha(70),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The rounded dialog container Okapi uses.
class OkapiDialogFrame extends StatelessWidget {
  /// Wraps [child] in Okapi's dialog chrome.
  const OkapiDialogFrame({super.key, required this.child});

  /// Dialog contents.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: t.maxWidth - 40),
          child: Material(
            color: t.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(t.radius),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// The full-screen container Okapi uses.
class OkapiFullScreenFrame extends StatelessWidget {
  /// Wraps [child] in Okapi's full-screen chrome.
  const OkapiFullScreenFrame({super.key, required this.child});

  /// Page contents.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = OkapiThemeData.of(context);
    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: t.maxWidth),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 56, 28, 24),
                  child: child,
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: Icon(Icons.close_rounded, color: t.muted),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
