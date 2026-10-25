// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Run: dart run okapi:sync
import 'dart:io';

import 'package:okapi/src/cli/sync.dart';

Future<void> main(List<String> args) async {
  exitCode = await runSync(args);
}
