// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Licensed under the Okapi Software License (see LICENSE).
// Run: dart run okapi doctor | sync
import 'dart:io';

import 'package:okapi/src/cli/doctor.dart';
import 'package:okapi/src/cli/sync.dart';

Future<void> main(List<String> args) async {
  final command = args.isEmpty ? 'help' : args.first;
  final rest = args.length > 1 ? args.sublist(1) : <String>[];
  switch (command) {
    case 'doctor':
      exitCode = await runDoctor(rest);
    case 'sync':
      exitCode = await runSync(rest);
    default:
      stdout.writeln('Okapi tools\n\n'
          '  dart run okapi:doctor   Check your permission setup\n'
          '  dart run okapi:sync     Write the declarations your code needs\n\n'
          'Add --help to either command for options.');
  }
}
