// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Pure Dart: no Flutter imports.

import 'dart:io';

/// Severity of a finding.
enum Severity {
  /// Must be fixed.
  error,

  /// Should be fixed.
  warning,

  /// Good to know.
  info,

  /// A passed check.
  ok,
}

/// One result of a check.
class Finding {
  /// Creates a finding.
  const Finding(this.severity, this.area, this.message, {this.fix});

  /// How serious it is.
  final Severity severity;

  /// Section: Code, Android, iOS, Google Play, App Store.
  final String area;

  /// What was found.
  final String message;

  /// How to fix it (code to paste or a command).
  final String? fix;

  /// For JSON output.
  Map<String, Object?> toJson() => {
        'severity': severity.name,
        'area': area,
        'message': message,
        if (fix != null) 'fix': fix,
      };
}

/// Small terminal helpers.
class Console {
  /// Creates a console; colours only when the terminal supports them.
  Console({bool? color})
      : color = color ?? (stdout.hasTerminal && stdout.supportsAnsiEscapes);

  /// Whether to print ANSI colours.
  final bool color;

  String _c(String code, String s) => color ? '\x1B[${code}m$s\x1B[0m' : s;

  /// Bold.
  String bold(String s) => _c('1', s);

  /// Dim.
  String dim(String s) => _c('2', s);

  /// Red.
  String red(String s) => _c('31', s);

  /// Yellow.
  String yellow(String s) => _c('33', s);

  /// Green.
  String green(String s) => _c('32', s);

  /// Cyan.
  String cyan(String s) => _c('36', s);

  /// Icon for a severity.
  String icon(Severity s) => switch (s) {
        Severity.error => red('✗'),
        Severity.warning => yellow('!'),
        Severity.info => cyan('i'),
        Severity.ok => green('✓'),
      };

  /// Prints a line.
  void line([String s = '']) => stdout.writeln(s);
}

/// Reads `--name=value` and `--flag` arguments.
class Args {
  /// Parses [args].
  Args(List<String> args) {
    for (final a in args) {
      if (!a.startsWith('--')) {
        rest.add(a);
        continue;
      }
      final eq = a.indexOf('=');
      if (eq < 0) {
        flags.add(a.substring(2));
      } else {
        values[a.substring(2, eq)] = a.substring(eq + 1);
      }
    }
  }

  /// `--flag` arguments.
  final Set<String> flags = {};

  /// `--name=value` arguments.
  final Map<String, String> values = {};

  /// Other arguments.
  final List<String> rest = [];

  /// Whether `--name` was given.
  bool has(String name) => flags.contains(name);
}
