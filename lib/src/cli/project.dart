// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted.

// Pure Dart: no Flutter imports, so `dart run okapi:doctor` works.

import 'dart:io';

import '../core/permission.dart';

/// Paths inside a Flutter app.
class OkapiProject {
  /// Wraps an app folder.
  OkapiProject(this.root);

  /// The folder that contains pubspec.yaml.
  final Directory root;

  String _p(List<String> parts) =>
      [root.path, ...parts].join(Platform.pathSeparator);

  /// pubspec.yaml.
  File get pubspec => File(_p(['pubspec.yaml']));

  /// android/app/src/main/AndroidManifest.xml.
  File get manifest =>
      File(_p(['android', 'app', 'src', 'main', 'AndroidManifest.xml']));

  /// ios/Runner/Info.plist.
  File get infoPlist => File(_p(['ios', 'Runner', 'Info.plist']));

  /// ios/Podfile.
  File get podfile => File(_p(['ios', 'Podfile']));

  /// android/app/build.gradle(.kts), whichever exists.
  File? get appGradle {
    for (final name in ['build.gradle.kts', 'build.gradle']) {
      final f = File(_p(['android', 'app', name]));
      if (f.existsSync()) return f;
    }
    return null;
  }

  /// The app's name from pubspec.yaml.
  String get name {
    try {
      final m = RegExp(r'^name:\s*(\S+)', multiLine: true)
          .firstMatch(pubspec.readAsStringSync());
      return m?.group(1) ?? 'app';
    } catch (_) {
      return 'app';
    }
  }

  /// A path relative to the app folder, for messages.
  String relative(String path) {
    final r = root.absolute.path;
    final a = File(path).absolute.path;
    return a.startsWith(r) ? a.substring(r.length + 1) : path;
  }

  /// Finds the app folder at or above [start] (default: current folder).
  static OkapiProject? find([String? start]) {
    var dir = Directory(start ?? Directory.current.path).absolute;
    for (var i = 0; i < 12; i++) {
      if (File('${dir.path}${Platform.pathSeparator}pubspec.yaml').existsSync()) {
        return OkapiProject(dir);
      }
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
    return null;
  }
}

/// Settings read from an optional `okapi:` section in pubspec.yaml:
///
/// ```yaml
/// okapi:
///   permissions: [contacts, calendarFullAccess]  # used dynamically
///   ios_keep: [BLUETOOTH]                        # never exclude these
///   manage_podfile: true
/// ```
class CliConfig {
  /// Creates settings.
  const CliConfig({
    this.extra = const {},
    this.iosKeep = const {},
    this.managePodfile = true,
    this.problems = const [],
  });

  /// Permissions to treat as used even if the code scan can't see them.
  final Set<OkapiPermission> extra;

  /// iOS families Sync must never exclude.
  final Set<String> iosKeep;

  /// Whether Sync may edit ios/Podfile.
  final bool managePodfile;

  /// Unknown names found in the section.
  final List<String> problems;

  /// Reads the section from [pubspec] text.
  static CliConfig parse(String pubspec) {
    final lines = pubspec.split('\n');
    final start = lines.indexWhere((l) => RegExp(r'^okapi:\s*(#.*)?$').hasMatch(l));
    if (start < 0) return const CliConfig();
    final values = <String, List<String>>{};
    String? current;
    for (var i = start + 1; i < lines.length; i++) {
      final raw = lines[i];
      if (raw.trim().isEmpty || raw.trimLeft().startsWith('#')) continue;
      if (!raw.startsWith(' ') && !raw.startsWith('\t')) break;
      final line = raw.split('#').first.trimRight();
      final kv = RegExp(r'^\s+([A-Za-z_]+):\s*(.*)$').firstMatch(line);
      final item = RegExp(r'^\s+-\s*(\S+)').firstMatch(line);
      if (kv != null) {
        current = kv.group(1)!;
        final v = kv.group(2)!.trim();
        values[current] = [];
        if (v.startsWith('[')) {
          values[current]!.addAll(v
              .replaceAll('[', '')
              .replaceAll(']', '')
              .split(',')
              .map((e) => e.trim().replaceAll("'", '').replaceAll('"', ''))
              .where((e) => e.isNotEmpty));
        } else if (v.isNotEmpty) {
          values[current]!.add(v.replaceAll("'", '').replaceAll('"', ''));
        }
      } else if (item != null && current != null) {
        values[current]!.add(item.group(1)!.replaceAll("'", '').replaceAll('"', ''));
      }
    }
    final problems = <String>[];
    final extra = <OkapiPermission>{};
    for (final n in values['permissions'] ?? const <String>[]) {
      final p = OkapiPermission.values.where((v) => v.name == n).firstOrNull;
      if (p == null) {
        problems.add('okapi.permissions: unknown "$n"');
      } else {
        extra.add(p);
      }
    }
    final keep = {
      for (final f in values['ios_keep'] ?? const <String>[])
        f.toUpperCase().replaceAll('OKAPI_EXCLUDE_', ''),
    };
    final mp = (values['manage_podfile'] ?? const ['true']).firstOrNull ?? 'true';
    return CliConfig(
      extra: extra,
      iosKeep: keep,
      managePodfile: mp.toLowerCase() != 'false',
      problems: problems,
    );
  }
}

/// Where the code uses Okapi permissions.
class Usage {
  /// Creates a usage report.
  Usage(this.locations, this.dynamicLocations);

  /// Permission → "file:line" places.
  final Map<OkapiPermission, List<String>> locations;

  /// Places where permissions are chosen at runtime
  /// (`OkapiPermission.values`, `.byName`).
  final List<String> dynamicLocations;

  /// Permissions found.
  Set<OkapiPermission> get permissions => locations.keys.toSet();

  /// Whether some usage can't be seen by scanning.
  bool get hasDynamic => dynamicLocations.isNotEmpty;
}

/// Removes `/* */` and `//` comments from one line, tracking block state.
(String, bool) stripComments(String line, bool inBlock) {
  var code = line;
  if (inBlock) {
    final end = code.indexOf('*/');
    if (end < 0) return ('', true);
    code = code.substring(end + 2);
  }
  // Line comment, ignoring "//" inside quotes (for example URLs).
  var single = false, dbl = false;
  for (var i = 0; i < code.length - 1; i++) {
    final c = code[i];
    if (c == '\\') {
      i++;
      continue;
    }
    if (c == "'" && !dbl) single = !single;
    if (c == '"' && !single) dbl = !dbl;
    if (!single && !dbl) {
      if (c == '/' && code[i + 1] == '/') {
        code = code.substring(0, i);
        break;
      }
      if (c == '/' && code[i + 1] == '*') {
        final end = code.indexOf('*/', i + 2);
        if (end < 0) return (code.substring(0, i), true);
        code = code.substring(0, i) + code.substring(end + 2);
        i--;
      }
    }
  }
  return (code, false);
}

final RegExp _use = RegExp(r'\bOkapiPermission\s*\.\s*([A-Za-z_]\w*)');

/// Scans Dart files under [dirs] for `OkapiPermission.xxx`.
Usage scanUsage(OkapiProject project, {List<String> dirs = const ['lib']}) {
  final names = {for (final p in OkapiPermission.values) p.name: p};
  final locations = <OkapiPermission, List<String>>{};
  final dynamicAt = <String>[];
  for (final d in dirs) {
    final dir = Directory('${project.root.path}${Platform.pathSeparator}$d');
    if (!dir.existsSync()) continue;
    final files = dir
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final f in files) {
      List<String> lines;
      try {
        lines = f.readAsLinesSync();
      } catch (_) {
        continue;
      }
      var inBlock = false;
      final rel = project.relative(f.path);
      for (var i = 0; i < lines.length; i++) {
        final (code, block) = stripComments(lines[i], inBlock);
        inBlock = block;
        for (final m in _use.allMatches(code)) {
          final n = m.group(1)!;
          final p = names[n];
          if (p != null) {
            (locations[p] ??= []).add('$rel:${i + 1}');
          } else if (n == 'values' || n == 'byName') {
            dynamicAt.add('$rel:${i + 1}');
          }
        }
      }
    }
  }
  return Usage(locations, dynamicAt);
}

/// A `<uses-permission>` entry.
class ManifestEntry {
  /// Creates an entry.
  const ManifestEntry(this.name, this.maxSdk);

  /// Full name, for example `android.permission.CAMERA`.
  final String name;

  /// `android:maxSdkVersion`, if set.
  final int? maxSdk;
}

/// Replaces XML comments with spaces (keeps offsets).
String blankXmlComments(String xml) => xml.replaceAllMapped(
    RegExp(r'<!--[\s\S]*?-->'), (m) => ' ' * m.group(0)!.length);

/// Reads `<uses-permission>` entries.
List<ManifestEntry> parseManifest(String xml) {
  final clean = blankXmlComments(xml);
  final out = <ManifestEntry>[];
  for (final m in RegExp(r'<uses-permission(?:-sdk-23)?\b([^>]*)>').allMatches(clean)) {
    final attrs = m.group(1)!;
    final name = RegExp(r'android:name\s*=\s*"([^"]+)"').firstMatch(attrs)?.group(1);
    if (name == null) continue;
    final max = RegExp(r'android:maxSdkVersion\s*=\s*"(\d+)"').firstMatch(attrs)?.group(1);
    out.add(ManifestEntry(name, max == null ? null : int.parse(max)));
  }
  return out;
}

/// Reads `<key>…</key><string>…</string>` pairs.
Map<String, String> parsePlistStrings(String xml) {
  final clean = blankXmlComments(xml);
  return {
    for (final m in RegExp(r'<key>\s*([^<]+?)\s*</key>\s*<string>([\s\S]*?)</string>')
        .allMatches(clean))
      m.group(1)!: m.group(2)!.trim(),
  };
}

/// iOS flags in a Podfile, ignoring commented lines.
Set<String> parsePodfileFlags(String podfile) => {
      for (final line in podfile.split('\n'))
        if (!line.trimLeft().startsWith('#'))
          for (final m in RegExp(r'OKAPI_EXCLUDE_([A-Z_]+)').allMatches(line))
            m.group(1)!,
    };

/// A marked region of a file, covering whole lines.
class ManagedRange {
  /// Creates a range.
  const ManagedRange(this.start, this.end);

  /// First character (start of the begin line).
  final int start;

  /// End (after the end line's newline).
  final int end;
}

/// Finds a region between [begin] and [end] markers.
ManagedRange? findManaged(String text, String begin, String end) {
  final b = text.indexOf(begin);
  if (b < 0) return null;
  final e = text.indexOf(end, b);
  if (e < 0) return null;
  final ls = text.lastIndexOf('\n', b) + 1;
  final nl = text.indexOf('\n', e);
  return ManagedRange(ls, nl < 0 ? text.length : nl + 1);
}

/// [text] without the managed region.
String withoutManaged(String text, String begin, String end) {
  final r = findManaged(text, begin, end);
  return r == null ? text : text.substring(0, r.start) + text.substring(r.end);
}

/// The managed region's text, or ''.
String managedContent(String text, String begin, String end) {
  final r = findManaged(text, begin, end);
  return r == null ? '' : text.substring(r.start, r.end);
}
