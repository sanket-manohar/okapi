// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Pure Dart: no Flutter imports, so `dart run okapi:doctor` works.

import 'dart:convert';
import 'dart:io';

import 'console.dart';
import 'project.dart';
import 'rules.dart';

/// Why an Info.plist usage text may be rejected by Apple, or null if it
/// looks fine.
String? vagueReason(String text) {
  final t = text.trim();
  final l = t.toLowerCase();
  if (t.isEmpty) return 'is empty';
  if (t.contains(r'$(')) return null; // Build variable; can't judge.
  if (l.contains('todo') || l.contains('explain why')) {
    return 'is still a placeholder';
  }
  if (t.length < 20) return 'is very short';
  const generic = [
    'needs access',
    'need access',
    'requires access',
    'require access',
    'needs permission',
    'needs your permission',
    'requires permission',
    'is required',
    'this app needs',
    'for app functionality',
    'to function properly',
    'to work properly',
  ];
  for (final g in generic) {
    if (l.contains(g)) return 'sounds generic ("$g")';
  }
  return null;
}

String _manifestLine(String name, int? maxSdk) =>
    '<uses-permission android:name="$name"'
    '${maxSdk == null ? '' : ' android:maxSdkVersion="$maxSdk"'} />';

/// Runs every check and returns the findings.
List<Finding> diagnose(
  OkapiProject project, {
  CliConfig? config,
  Usage? usage,
}) {
  final out = <Finding>[];
  final cfg =
      config ??
      (project.pubspec.existsSync()
          ? CliConfig.parse(project.pubspec.readAsStringSync())
          : const CliConfig());
  final use = usage ?? scanUsage(project);
  final used = {...use.permissions, ...cfg.extra};
  final names = used.map((p) => p.name).toList()..sort();

  // ── Code ───────────────────────────────────────────────────────────────
  for (final p in cfg.problems) {
    out.add(
      Finding(
        Severity.error,
        'Code',
        p,
        fix: 'Use a name from OkapiPermission, for example camera.',
      ),
    );
  }
  if (used.isEmpty) {
    out.add(
      const Finding(
        Severity.warning,
        'Code',
        'No OkapiPermission found in lib/. Nothing to check.',
      ),
    );
  } else {
    out.add(
      Finding(
        Severity.ok,
        'Code',
        '${used.length} permission${used.length == 1 ? '' : 's'} used: ${names.join(', ')}',
      ),
    );
  }
  if (use.hasDynamic) {
    out.add(
      Finding(
        Severity.warning,
        'Code',
        'Permissions chosen at runtime (${use.dynamicLocations.take(3).join(', ')}). '
            'Doctor and Sync can\'t see which ones.',
        fix: 'List them in pubspec.yaml:\nokapi:\n  permissions: [contacts, calendarFullAccess]',
      ),
    );
  }

  // ── Android ────────────────────────────────────────────────────────────
  if (!project.manifest.existsSync()) {
    out.add(
      const Finding(
        Severity.info,
        'Android',
        'No android/app/src/main/AndroidManifest.xml; Android checks skipped.',
      ),
    );
  } else {
    final xml = project.manifest.readAsStringSync();
    final declared = {for (final e in parseManifest(xml)) e.name};
    var missing = 0;
    final neededNames = <String>{};
    for (final p in used) {
      for (final need in androidNeeds(p)) {
        neededNames.addAll(need.names);
        if (need.names.any(declared.contains)) continue;
        if (need.level == NeedLevel.optional) continue;
        missing++;
        final what = need.names.length == 1
            ? need.primary
            : 'one of ${need.names.map((n) => n.replaceFirst('android.permission.', '')).join(', ')}';
        out.add(
          Finding(
            need.level == NeedLevel.required
                ? Severity.error
                : Severity.warning,
            'Android',
            '${p.name}: missing $what${need.note == null ? '' : ' (${need.note})'}',
            fix: _manifestLine(need.primary, need.maxSdk),
          ),
        );
      }
    }
    if (missing == 0 && used.any((p) => androidNeeds(p).isNotEmpty)) {
      out.add(
        const Finding(
          Severity.ok,
          'Android',
          'Every permission your code uses is declared.',
        ),
      );
    }
    final known = knownAndroidNames;
    for (final n in declared.where(
      (n) => known.contains(n) && !neededNames.contains(n),
    )) {
      out.add(
        Finding(
          Severity.info,
          'Android',
          '$n is declared but your code never asks for it through Okapi. '
              'Remove it if no other package needs it.',
        ),
      );
    }
    for (final n in declared.where(playRestricted.containsKey)) {
      out.add(
        Finding(
          Severity.warning,
          'Google Play',
          '$n falls under Google Play\'s ${playRestricted[n]}.',
          fix:
              'Complete the declaration in Play Console › App content, '
              'or remove the permission if your app doesn\'t qualify.',
        ),
      );
    }
    final gradle = project.appGradle;
    if (gradle != null) {
      final m = RegExp(r'compileSdk(?:Version)?\s*=?\s*(\d+)')
          .firstMatch(gradle.readAsStringSync());
      final v = m == null ? null : int.tryParse(m.group(1)!);
      if (v != null && v < 35) {
        out.add(
          Finding(
            Severity.warning,
            'Android',
            'compileSdk is $v. Okapi needs 35 or higher.',
            fix: 'In ${project.relative(gradle.path)}: compileSdk = 35',
          ),
        );
      }
    }
  }

  // ── iOS ────────────────────────────────────────────────────────────────
  if (!project.infoPlist.existsSync()) {
    out.add(
      const Finding(
        Severity.info,
        'iOS',
        'No ios/Runner/Info.plist; iOS checks skipped.',
      ),
    );
  } else {
    final keys = parsePlistStrings(project.infoPlist.readAsStringSync());
    var missing = 0;
    final neededKeys = <String>{};
    for (final p in used) {
      for (final need in iosNeeds(p)) {
        neededKeys.addAll(need.names);
        final present = need.names.where(keys.containsKey).toList();
        if (present.isEmpty) {
          if (need.level == NeedLevel.optional) continue;
          missing++;
          out.add(
            Finding(
              need.level == NeedLevel.required
                  ? Severity.error
                  : Severity.warning,
              'iOS',
              '${p.name}: missing ${need.primary} in Info.plist'
                  '${need.level == NeedLevel.required ? ' (iOS would crash the app)' : ''}'
                  '${need.note == null ? '' : ' (${need.note})'}',
              fix:
                  '<key>${need.primary}</key>\n<string>${iosExamples[need.primary] ?? 'Explain why you need it.'}</string>',
            ),
          );
        }
      }
    }
    if (missing == 0 && used.any((p) => iosNeeds(p).isNotEmpty)) {
      out.add(
        const Finding(
          Severity.ok,
          'iOS',
          'Every permission your code uses has a usage description.',
        ),
      );
    }
    for (final k in neededKeys.where(keys.containsKey)) {
      final why = vagueReason(keys[k]!);
      if (why == null) continue;
      out.add(
        Finding(
          why == 'is still a placeholder' || why == 'is empty'
              ? Severity.error
              : Severity.warning,
          'App Store',
          '$k $why: "${keys[k]}". Apple rejects vague reasons.',
          fix:
              'Say what the user gets, for example: "${iosExamples[k] ?? 'Scan QR codes to pay in one tap.'}"',
        ),
      );
    }
    final allUsageKeys = {for (final v in iosExamples.keys) v};
    for (final k in keys.keys.where(
      (k) => allUsageKeys.contains(k) && !neededKeys.contains(k),
    )) {
      out.add(
        Finding(
          Severity.info,
          'iOS',
          '$k is in Info.plist but your code never asks for it through Okapi.',
        ),
      );
    }

    if (project.podfile.existsSync()) {
      final podfile = project.podfile.readAsStringSync();
      final flags = parsePodfileFlags(podfile);
      final usedFamilies = {
        for (final e in iosFamilies.entries)
          if (e.value.any(used.contains)) e.key,
      };
      for (final f in flags) {
        if (!iosFamilies.containsKey(f)) {
          out.add(
            Finding(
              Severity.warning,
              'iOS',
              'Unknown flag OKAPI_EXCLUDE_$f in Podfile.',
            ),
          );
        } else if (usedFamilies.contains(f)) {
          final ps = iosFamilies[f]!
              .where(used.contains)
              .map((p) => p.name)
              .join(', ');
          out.add(
            Finding(
              Severity.error,
              'iOS',
              'Podfile excludes $f but your code uses $ps. Those calls return notApplicable on iOS.',
              fix: 'Remove OKAPI_EXCLUDE_$f, or run dart run okapi:sync',
            ),
          );
        }
      }
      final unused = iosFamilies.keys
          .where(
            (f) =>
                !usedFamilies.contains(f) &&
                !flags.contains(f) &&
                !cfg.iosKeep.contains(f),
          )
          .toList();
      if (unused.isNotEmpty && !use.hasDynamic && used.isNotEmpty) {
        out.add(
          Finding(
            Severity.info,
            'App Store',
            'Unused permission APIs are still compiled in: ${unused.join(', ')}. '
                'Excluding them avoids App Store questions.',
            fix: 'dart run okapi:sync',
          ),
        );
      }
      final target = RegExp(
        r"^\s*platform\s+:ios\s*,\s*'(\d+)(?:\.\d+)?'",
        multiLine: true,
      ).firstMatch(podfile);
      final t = target == null ? null : int.tryParse(target.group(1)!);
      if (t != null && t < 12) {
        out.add(
          Finding(
            Severity.error,
            'iOS',
            'iOS deployment target is $t. Okapi needs iOS 12 or higher.',
            fix: "In ios/Podfile: platform :ios, '12.0'",
          ),
        );
      }
    }
  }
  return out;
}

const String _help = '''
Okapi Doctor checks your app's permission setup.

Usage: dart run okapi:doctor [options]

  --path=<dir>    App folder (default: current folder)
  --strict        Exit with code 1 on warnings too
  --json          Print results as JSON (for CI)
  --no-color      Plain output
  --help          Show this help

It scans lib/ for OkapiPermission usage and checks AndroidManifest.xml,
Info.plist, the Podfile and Google Play / App Store rules.
Fix declarations automatically with: dart run okapi:sync
''';

/// Entry point for `dart run okapi:doctor`. Returns the exit code.
Future<int> runDoctor(List<String> arguments) async {
  final args = Args(arguments);
  final console = Console(color: args.has('no-color') ? false : null);
  if (args.has('help')) {
    console.line(_help);
    return 0;
  }
  final project = OkapiProject.find(args.values['path']);
  if (project == null) {
    stderr.writeln(
      'Okapi Doctor: no pubspec.yaml found. Run it inside your app folder.',
    );
    return 2;
  }
  final findings = diagnose(project);
  final errors = findings.where((f) => f.severity == Severity.error).length;
  final warnings = findings.where((f) => f.severity == Severity.warning).length;
  final notes = findings.where((f) => f.severity == Severity.info).length;

  if (args.has('json')) {
    console.line(
      const JsonEncoder.withIndent('  ').convert({
        'project': project.name,
        'errors': errors,
        'warnings': warnings,
        'notes': notes,
        'findings': findings.map((f) => f.toJson()).toList(),
      }),
    );
  } else {
    console.line();
    console.line(
      '${console.bold('Okapi Doctor')} ${console.dim('· ${project.name}')}',
    );
    for (final area in ['Code', 'Android', 'Google Play', 'iOS', 'App Store']) {
      final items = findings.where((f) => f.area == area).toList();
      if (items.isEmpty) continue;
      console.line();
      console.line(console.bold(area));
      for (final f in items) {
        console.line('  ${console.icon(f.severity)} ${f.message}');
        if (f.fix != null) {
          for (final l in f.fix!.split('\n')) {
            console.line(console.dim('      $l'));
          }
        }
      }
    }
    console.line();
    final summary =
        '$errors error${errors == 1 ? '' : 's'}, '
        '$warnings warning${warnings == 1 ? '' : 's'}, '
        '$notes note${notes == 1 ? '' : 's'}';
    console.line(
      errors > 0
          ? console.red(summary)
          : warnings > 0
          ? console.yellow(summary)
          : console.green(summary),
    );
    if (errors + warnings > 0) {
      console.line(
        console.dim('Fix declarations automatically: dart run okapi:sync'),
      );
    }
    console.line();
  }
  if (errors > 0) return 1;
  if (warnings > 0 && args.has('strict')) return 1;
  return 0;
}
