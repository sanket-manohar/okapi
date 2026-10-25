// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Licensed under the Okapi Software License (see LICENSE).
// Run: dart run okapi:sync
import 'dart:io';

import 'package:okapi/src/cli/sync.dart';

Future<void> main(List<String> args) async {
  exitCode = await runSync(args);
}
