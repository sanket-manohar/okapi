// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted.

import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../core/okapi.dart';
import '../core/permission.dart';

/// Builds the visual shown at the top of a prompt (icon, Lottie, image...).
typedef OkapiVisualBuilder = Widget Function(
    BuildContext context, OkapiPermission permission, OkapiThemeData theme);

/// Colours, shapes and text styles for all of Okapi's built-in UI.
///
/// Resolution order (first match wins):
/// 1. An [OkapiTheme] widget above the calling widget.
/// 2. `OkapiConfig.theme` passed to `Okapi.configure`.
/// 3. An [OkapiThemeData] added to `ThemeData.extensions`.
/// 4. Derived automatically from your app's `ColorScheme`.
@immutable
class OkapiThemeData extends ThemeExtension<OkapiThemeData> {
  /// Creates a theme. Prefer the named presets and [copyWith].
  const OkapiThemeData({
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.onSurface,
    required this.muted,
    required this.granted,
    required this.danger,
    required this.warning,
    required this.iconBackground,
    required this.iconColor,
    this.radius = 28,
    this.buttonRadius = 16,
    this.iconBadgeSize = 76,
    this.blurSigma = 6,
    this.barrierColor = const Color(0x8A000000),
    this.maxWidth = 460,
    this.showHandle = true,
    this.showSettingsSteps = true,
    this.useGradientBadge = true,
    this.titleStyle,
    this.bodyStyle,
    this.buttonTextStyle,
    this.visualBuilder,
  });

  /// Main action colour.
  final Color primary;

  /// Text/icons on [primary].
  final Color onPrimary;

  /// Card / sheet background.
  final Color surface;

  /// Main text colour.
  final Color onSurface;

  /// Secondary text colour.
  final Color muted;

  /// "Allowed" colour.
  final Color granted;

  /// "Blocked" colour.
  final Color danger;

  /// "Limited / restricted" colour.
  final Color warning;

  /// Background of the round icon badge.
  final Color iconBackground;

  /// Icon colour inside the badge.
  final Color iconColor;

  /// Corner radius of sheets, dialogs and cards.
  final double radius;

  /// Corner radius of buttons.
  final double buttonRadius;

  /// Diameter of the icon badge.
  final double iconBadgeSize;

  /// Background blur behind prompts. `0` disables blur.
  final double blurSigma;

  /// Dim colour behind prompts.
  final Color barrierColor;

  /// Maximum width of prompts on tablets.
  final double maxWidth;

  /// Shows the small drag handle on bottom sheets.
  final bool showHandle;

  /// Shows "Settings › Permissions › Allow" steps on Settings prompts.
  final bool showSettingsSteps;

  /// Paints the icon badge with a soft gradient ring.
  final bool useGradientBadge;

  /// Title text style (merged over the default).
  final TextStyle? titleStyle;

  /// Body text style (merged over the default).
  final TextStyle? bodyStyle;

  /// Button label style (merged over the default).
  final TextStyle? buttonTextStyle;

  /// Replace the icon badge with any widget (illustration, animation...).
  final OkapiVisualBuilder? visualBuilder;

  /// Derives a theme that blends into any app.
  factory OkapiThemeData.fromColorScheme(ColorScheme cs) => OkapiThemeData(
        primary: cs.primary,
        onPrimary: cs.onPrimary,
        surface: cs.surface,
        onSurface: cs.onSurface,
        muted: cs.onSurfaceVariant,
        granted: const Color(0xFF1FAE7A),
        danger: cs.error,
        warning: const Color(0xFFE59A1A),
        iconBackground: cs.primaryContainer,
        iconColor: cs.onPrimaryContainer,
      );

  /// Okapi's signature look: warm chestnut and cream, light mode.
  factory OkapiThemeData.okapiLight() => const OkapiThemeData(
        primary: Color(0xFF5A2A1E),
        onPrimary: Color(0xFFFFF8EF),
        surface: Color(0xFFFFFBF5),
        onSurface: Color(0xFF1E1512),
        muted: Color(0xFF7A6A60),
        granted: Color(0xFF16A37A),
        danger: Color(0xFFD9483B),
        warning: Color(0xFFD98B1A),
        iconBackground: Color(0xFFF3E4D3),
        iconColor: Color(0xFF5A2A1E),
      );

  /// Okapi's signature look, dark mode.
  factory OkapiThemeData.okapiDark() => const OkapiThemeData(
        primary: Color(0xFFF2C9A0),
        onPrimary: Color(0xFF2A140E),
        surface: Color(0xFF1C1513),
        onSurface: Color(0xFFF6EDE1),
        muted: Color(0xFFB8A79B),
        granted: Color(0xFF2BD9A0),
        danger: Color(0xFFFF6B5A),
        warning: Color(0xFFFFB547),
        iconBackground: Color(0xFF3A2620),
        iconColor: Color(0xFFF2C9A0),
      );

  /// Minimal black and white with sharp corners.
  factory OkapiThemeData.mono({bool dark = false}) => OkapiThemeData(
        primary: dark ? Colors.white : Colors.black,
        onPrimary: dark ? Colors.black : Colors.white,
        surface: dark ? const Color(0xFF111111) : Colors.white,
        onSurface: dark ? Colors.white : Colors.black,
        muted: dark ? const Color(0xFF9E9E9E) : const Color(0xFF616161),
        granted: const Color(0xFF00A86B),
        danger: const Color(0xFFE53935),
        warning: const Color(0xFFF9A825),
        iconBackground: dark ? const Color(0xFF222222) : const Color(0xFFF1F1F1),
        iconColor: dark ? Colors.white : Colors.black,
        radius: 12,
        buttonRadius: 10,
        useGradientBadge: false,
      );

  /// Resolves the theme for [context] (see class docs for the order).
  static OkapiThemeData of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<OkapiTheme>()?.data;
    if (inherited != null) return inherited;
    final configured = Okapi.config.theme;
    if (configured != null) return configured;
    final theme = Theme.of(context);
    return theme.extension<OkapiThemeData>() ??
        OkapiThemeData.fromColorScheme(theme.colorScheme);
  }

  /// Resolved title style.
  TextStyle resolvedTitle(BuildContext context) => (Theme.of(context)
              .textTheme
              .titleLarge ??
          const TextStyle(fontSize: 22))
      .copyWith(
          color: onSurface,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.3)
      .merge(titleStyle);

  /// Resolved body style.
  TextStyle resolvedBody(BuildContext context) =>
      (Theme.of(context).textTheme.bodyMedium ?? const TextStyle(fontSize: 15))
          .copyWith(color: muted, height: 1.45, fontSize: 15)
          .merge(bodyStyle);

  /// Resolved button label style.
  TextStyle resolvedButton(BuildContext context) =>
      (Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 16))
          .copyWith(fontWeight: FontWeight.w600, fontSize: 16)
          .merge(buttonTextStyle);

  @override
  OkapiThemeData copyWith({
    Color? primary,
    Color? onPrimary,
    Color? surface,
    Color? onSurface,
    Color? muted,
    Color? granted,
    Color? danger,
    Color? warning,
    Color? iconBackground,
    Color? iconColor,
    double? radius,
    double? buttonRadius,
    double? iconBadgeSize,
    double? blurSigma,
    Color? barrierColor,
    double? maxWidth,
    bool? showHandle,
    bool? showSettingsSteps,
    bool? useGradientBadge,
    TextStyle? titleStyle,
    TextStyle? bodyStyle,
    TextStyle? buttonTextStyle,
    OkapiVisualBuilder? visualBuilder,
  }) =>
      OkapiThemeData(
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        surface: surface ?? this.surface,
        onSurface: onSurface ?? this.onSurface,
        muted: muted ?? this.muted,
        granted: granted ?? this.granted,
        danger: danger ?? this.danger,
        warning: warning ?? this.warning,
        iconBackground: iconBackground ?? this.iconBackground,
        iconColor: iconColor ?? this.iconColor,
        radius: radius ?? this.radius,
        buttonRadius: buttonRadius ?? this.buttonRadius,
        iconBadgeSize: iconBadgeSize ?? this.iconBadgeSize,
        blurSigma: blurSigma ?? this.blurSigma,
        barrierColor: barrierColor ?? this.barrierColor,
        maxWidth: maxWidth ?? this.maxWidth,
        showHandle: showHandle ?? this.showHandle,
        showSettingsSteps: showSettingsSteps ?? this.showSettingsSteps,
        useGradientBadge: useGradientBadge ?? this.useGradientBadge,
        titleStyle: titleStyle ?? this.titleStyle,
        bodyStyle: bodyStyle ?? this.bodyStyle,
        buttonTextStyle: buttonTextStyle ?? this.buttonTextStyle,
        visualBuilder: visualBuilder ?? this.visualBuilder,
      );

  @override
  OkapiThemeData lerp(covariant OkapiThemeData? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    double d(double a, double b) => lerpDouble(a, b, t)!;
    return OkapiThemeData(
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      surface: c(surface, other.surface),
      onSurface: c(onSurface, other.onSurface),
      muted: c(muted, other.muted),
      granted: c(granted, other.granted),
      danger: c(danger, other.danger),
      warning: c(warning, other.warning),
      iconBackground: c(iconBackground, other.iconBackground),
      iconColor: c(iconColor, other.iconColor),
      radius: d(radius, other.radius),
      buttonRadius: d(buttonRadius, other.buttonRadius),
      iconBadgeSize: d(iconBadgeSize, other.iconBadgeSize),
      blurSigma: d(blurSigma, other.blurSigma),
      barrierColor: c(barrierColor, other.barrierColor),
      maxWidth: d(maxWidth, other.maxWidth),
      showHandle: t < 0.5 ? showHandle : other.showHandle,
      showSettingsSteps: t < 0.5 ? showSettingsSteps : other.showSettingsSteps,
      useGradientBadge: t < 0.5 ? useGradientBadge : other.useGradientBadge,
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t),
      bodyStyle: TextStyle.lerp(bodyStyle, other.bodyStyle, t),
      buttonTextStyle: TextStyle.lerp(buttonTextStyle, other.buttonTextStyle, t),
      visualBuilder: t < 0.5 ? visualBuilder : other.visualBuilder,
    );
  }
}

/// Overrides the Okapi theme for a subtree.
///
/// Prompts are shown in new routes, so wrap your `MaterialApp` (or pass
/// `OkapiConfig.theme`) to style them app-wide. Okapi captures the theme from
/// the widget that started the flow, so a local [OkapiTheme] also works for
/// prompts started inside it.
class OkapiTheme extends InheritedWidget {
  /// Creates a theme override.
  const OkapiTheme({super.key, required this.data, required super.child});

  /// The theme for this subtree.
  final OkapiThemeData data;

  @override
  bool updateShouldNotify(OkapiTheme oldWidget) => data != oldWidget.data;
}
