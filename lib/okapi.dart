// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted.
// "Okapi" and the Okapi logo are trademarks of Sanket Santosh Vidya Manohar;
// see TRADEMARKS.md.

/// Okapi: a complete permission manager for Flutter on Android and iOS.
///
/// Check, request and guide users through every permission with a polished,
/// fully customisable UI. Includes feature-based asking, an ask policy,
/// phone-maker (OEM) background guides, auto-reset protection, a Privacy
/// Center screen and a debug panel. Run `dart run okapi:doctor` and
/// `dart run okapi:sync` to check and fix your platform files.
///
/// ```dart
/// import 'package:okapi/okapi.dart';
///
/// final result = await Okapi.ask(context, OkapiPermission.camera);
/// if (result.isGranted) { /* open the camera */ }
/// ```
library;

export 'src/core/background.dart';
export 'src/core/config.dart';
export 'src/core/declarations.dart';
export 'src/core/device.dart';
export 'src/core/feature.dart';
export 'src/core/okapi.dart';
export 'src/core/permission.dart';
export 'src/core/policy.dart';
export 'src/core/status.dart';
export 'src/core/strings.dart';
export 'src/platform/dev_platform.dart'
    show OkapiDevOverrides, OkapiDevPlatform;
export 'src/platform/okapi_platform.dart' show OkapiPlatform;
export 'src/ui/debug/debug_panel.dart';
export 'src/ui/icons.dart';
export 'src/ui/presenters/custom_presenter.dart';
export 'src/ui/presenters/route.dart';
export 'src/ui/presenters/sheet_presenter.dart';
export 'src/ui/theme.dart';
export 'src/ui/widgets/feature_widgets.dart';
export 'src/ui/widgets/privacy_center.dart';
export 'src/ui/widgets/prompt_view.dart';
export 'src/ui/widgets/widgets.dart';
