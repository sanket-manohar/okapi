// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Pure Dart: no Flutter imports, so `dart run okapi:sync` works.

import 'dart:io';

import '../core/permission.dart';
import 'console.dart';
import 'project.dart';
import 'rules.dart';

/// Marker that starts the region Sync manages in XML files.
const String xmlBegin = '<!-- okapi:begin';

/// Marker that ends the region Sync manages in XML files.
const String xmlEnd = '<!-- okapi:end';

/// Marker that starts the region Sync manages in the Podfile.
const String podBegin = '# okapi:begin';

/// Marker that ends the region Sync manages in the Podfile.
const String podEnd = '# okapi:end';

const String _note =
    '(managed by `dart run okapi:sync`; edits inside are replaced)';

/// Returns [xml] with every needed `<uses-permission>` that isn't already
/// declared outside Okapi's region written inside that region.
String syncManifest(
  String xml,
  Set<OkapiPermission> used, {
  bool withOptional = false,
}) {
  final outside = {
    for (final e in parseManifest(withoutManaged(xml, xmlBegin, xmlEnd)))
      e.name,
  };
  final needed = <String, int?>{};
  final order = <String>[];
  for (final p in OkapiPermission.values.where(used.contains)) {
    for (final n in androidNeeds(p)) {
      if (n.level == NeedLevel.optional && !withOptional) continue;
      if (n.names.any(outside.contains)) continue;
      final name = n.primary;
      if (!needed.containsKey(name)) {
        needed[name] = n.maxSdk;
        order.add(name);
      } else {
        final a = needed[name], b = n.maxSdk;
        // No limit wins; otherwise keep the higher limit.
        needed[name] = (a == null || b == null) ? null : (a > b ? a : b);
      }
    }
  }

  final range = findManaged(xml, xmlBegin, xmlEnd);
  String indentAt(int index) {
    final ls = xml.lastIndexOf('\n', index) + 1;
    final m = RegExp(r'^[ \t]*').firstMatch(xml.substring(ls));
    return m?.group(0) ?? '    ';
  }

  if (needed.isEmpty) {
    return range == null
        ? xml
        : xml.substring(0, range.start) + xml.substring(range.end);
  }

  late final String indent;
  late final int at;
  if (range != null) {
    indent = indentAt(range.start + 1);
    at = range.start;
  } else {
    final app = xml.indexOf('<application');
    final anchor = app >= 0 ? app : xml.lastIndexOf('</manifest>');
    if (anchor < 0) return xml; // Not a manifest; leave it alone.
    at = xml.lastIndexOf('\n', anchor) + 1;
    indent = app >= 0 ? indentAt(anchor) : '    ';
  }
  final block = StringBuffer()..writeln('$indent$xmlBegin $_note -->');
  for (final name in order) {
    final max = needed[name];
    block.writeln(
      '$indent<uses-permission android:name="$name"'
      '${max == null ? '' : ' android:maxSdkVersion="$max"'} />',
    );
  }
  block.writeln('$indent$xmlEnd -->');
  if (range != null) {
    return xml.substring(0, range.start) +
        block.toString() +
        xml.substring(range.end);
  }
  return xml.substring(0, at) + block.toString() + xml.substring(at);
}

/// Returns [xml] (an Info.plist) with every needed usage description that
/// isn't already present outside Okapi's region written inside it. Texts you
/// edited inside the region are kept.
String syncPlist(String xml, Set<OkapiPermission> used) {
  final outside = parsePlistStrings(withoutManaged(xml, xmlBegin, xmlEnd));
  final inside = parsePlistStrings(managedContent(xml, xmlBegin, xmlEnd));
  final keys = <String>[];
  for (final p in OkapiPermission.values.where(used.contains)) {
    for (final n in iosNeeds(p)) {
      if (n.level == NeedLevel.optional) continue;
      if (n.names.any(outside.containsKey)) continue;
      if (!keys.contains(n.primary)) keys.add(n.primary);
    }
  }

  final range = findManaged(xml, xmlBegin, xmlEnd);
  if (keys.isEmpty) {
    return range == null
        ? xml
        : xml.substring(0, range.start) + xml.substring(range.end);
  }
  final keyLine = RegExp(r'^([ \t]*)<key>', multiLine: true).firstMatch(xml);
  final indent = keyLine?.group(1) ?? '\t';

  String escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  final block = StringBuffer()..writeln('$indent$xmlBegin $_note -->');
  for (final k in keys) {
    final value =
        inside[k] ??
        escape(
          'TODO: Tell users why this app needs this. '
          'Example: ${iosExamples[k] ?? 'Scan QR codes to pay in one tap.'}',
        );
    block
      ..writeln('$indent<key>$k</key>')
      ..writeln('$indent<string>$value</string>');
  }
  block.writeln('$indent$xmlEnd -->');

  if (range != null) {
    return xml.substring(0, range.start) +
        block.toString() +
        xml.substring(range.end);
  }
  final plistEnd = xml.lastIndexOf('</plist>');
  final dictEnd = plistEnd < 0 ? -1 : xml.lastIndexOf('</dict>', plistEnd);
  if (dictEnd < 0) return xml; // Not a plist; leave it alone.
  final at = xml.lastIndexOf('\n', dictEnd) + 1;
  return xml.substring(0, at) + block.toString() + xml.substring(at);
}

/// The result of [syncPodfile].
class PodfileResult {
  /// Creates a result.
  const PodfileResult(this.text, {this.skippedReason});

  /// New Podfile text (unchanged when skipped).
  final String text;

  /// Why Sync left the Podfile alone, if it did.
  final String? skippedReason;
}

/// Writes iOS exclude flags for [exclude] families into Okapi's region of
/// the Podfile (or removes the region when [exclude] is empty).
PodfileResult syncPodfile(String podfile, Set<String> exclude) {
  final outside = withoutManaged(podfile, podBegin, podEnd);
  if (parsePodfileFlags(outside).isNotEmpty) {
    return PodfileResult(
      podfile,
      skippedReason: 'it already has OKAPI_EXCLUDE flags you added by hand',
    );
  }
  final range = findManaged(podfile, podBegin, podEnd);
  final sorted = exclude.toList()..sort();
  if (sorted.isEmpty) {
    return PodfileResult(
      range == null
          ? podfile
          : podfile.substring(0, range.start) + podfile.substring(range.end),
    );
  }

  final hook = RegExp(
    r'^post_install\s+do\s*\|\s*(\w+)\s*\|.*$',
    multiLine: true,
  ).firstMatch(outside);
  final v = hook?.group(1) ?? 'installer';
  final flags = sorted.map((f) => 'OKAPI_EXCLUDE_$f').join(' ');
  final block =
      '''
  $podBegin $_note
  $v.pods_project.targets.each do |target|
    next unless target.name == 'okapi'
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '\$(inherited) $flags'
    end
  end
  $podEnd
''';
  if (range != null) {
    return PodfileResult(
      podfile.substring(0, range.start) + block + podfile.substring(range.end),
    );
  }
  final realHook = RegExp(
    r'^post_install\s+do\s*\|\s*(\w+)\s*\|.*$',
    multiLine: true,
  ).firstMatch(podfile);
  if (realHook != null) {
    final nl = podfile.indexOf('\n', realHook.end);
    final at = nl < 0 ? podfile.length : nl + 1;
    return PodfileResult(
      podfile.substring(0, at) + block + podfile.substring(at),
    );
  }
  final sep = podfile.endsWith('\n') ? '' : '\n';
  return PodfileResult(
    '$podfile$sep\npost_install do |installer|\n'
    '  installer.pods_project.targets.each do |target|\n'
    '    flutter_additional_ios_build_settings(target)\n'
    '  end\n'
    '$block'
    'end\n',
  );
}

/// iOS families that no used permission needs.
Set<String> unusedFamilies(Set<OkapiPermission> used, Set<String> keep) => {
  for (final e in iosFamilies.entries)
    if (!e.value.any(used.contains) && !keep.contains(e.key)) e.key,
};

const String _help = '''
Okapi Sync writes the permission declarations your code needs.

Usage: dart run okapi:sync [options]

  --dry-run           Show what would change, write nothing
  --path=<dir>        App folder (default: current folder)
  --with-optional     Also add optional Android permissions
  --no-podfile        Don't touch ios/Podfile
  --ios-keep=A,B      iOS families never to exclude (for example BLUETOOTH)
  --no-color          Plain output
  --help              Show this help

Sync only edits the region between "okapi:begin" and "okapi:end" markers
and never removes anything you wrote yourself. Run it again whenever you
start or stop using a permission. Then run: dart run okapi:doctor
''';

/// Entry point for `dart run okapi:sync`. Returns the exit code.
Future<int> runSync(List<String> arguments) async {
  final args = Args(arguments);
  final console = Console(color: args.has('no-color') ? false : null);
  if (args.has('help')) {
    console.line(_help);
    return 0;
  }
  final project = OkapiProject.find(args.values['path']);
  if (project == null) {
    stderr.writeln(
      'Okapi Sync: no pubspec.yaml found. Run it inside your app folder.',
    );
    return 2;
  }
  final dry = args.has('dry-run');
  final cfg = project.pubspec.existsSync()
      ? CliConfig.parse(project.pubspec.readAsStringSync())
      : const CliConfig();
  final usage = scanUsage(project);
  final used = {...usage.permissions, ...cfg.extra};
  final keep = {
    ...cfg.iosKeep,
    ...?args.values['ios-keep']
        ?.split(',')
        .map((e) => e.trim().toUpperCase().replaceAll('OKAPI_EXCLUDE_', ''))
        .where((e) => e.isNotEmpty),
  };

  console.line();
  console.line(
    '${console.bold('Okapi Sync')} ${console.dim('· ${project.name}${dry ? ' · dry run' : ''}')}',
  );
  console.line();
  for (final p in cfg.problems) {
    console.line('  ${console.icon(Severity.error)} $p');
  }
  if (used.isEmpty) {
    console.line(
      '  ${console.icon(Severity.warning)} No OkapiPermission found in lib/. Nothing to sync.',
    );
    return 0;
  }
  console.line(
    '  ${console.icon(Severity.ok)} Permissions used: '
    '${(used.map((p) => p.name).toList()..sort()).join(', ')}',
  );

  var changed = 0;
  void write(File file, String before, String after, String label) {
    final rel = project.relative(file.path);
    if (before == after) {
      console.line('  ${console.icon(Severity.ok)} $rel is up to date');
      return;
    }
    changed++;
    final region = after.contains(label)
        ? managedRegionPreview(after, label)
        : '';
    console.line(
      '  ${console.icon(Severity.info)} ${dry ? 'Would update' : 'Updated'} $rel',
    );
    for (final l in region.split('\n').where((l) => l.trim().isNotEmpty)) {
      console.line(console.dim('      ${l.trim()}'));
    }
    if (!dry) file.writeAsStringSync(after);
  }

  if (project.manifest.existsSync()) {
    final before = project.manifest.readAsStringSync();
    write(
      project.manifest,
      before,
      syncManifest(before, used, withOptional: args.has('with-optional')),
      xmlBegin,
    );
  } else {
    console.line(
      '  ${console.icon(Severity.info)} No AndroidManifest.xml; skipped Android',
    );
  }

  if (project.infoPlist.existsSync()) {
    final before = project.infoPlist.readAsStringSync();
    final after = syncPlist(before, used);
    write(project.infoPlist, before, after, xmlBegin);
    if (after.contains('TODO: Tell users why')) {
      console.line(
        console.yellow(
          '      Replace each TODO text in Info.plist with a real reason before release.',
        ),
      );
    }
  } else {
    console.line('  ${console.icon(Severity.info)} No Info.plist; skipped iOS');
  }

  final managePod = cfg.managePodfile && !args.has('no-podfile');
  if (managePod && project.podfile.existsSync()) {
    if (usage.hasDynamic && cfg.extra.isEmpty) {
      console.line(
        '  ${console.icon(Severity.warning)} Podfile left alone: permissions are chosen at '
        'runtime, so Sync can\'t tell which iOS APIs are safe to exclude. '
        'List them under "okapi: permissions:" in pubspec.yaml.',
      );
    } else {
      final before = project.podfile.readAsStringSync();
      final r = syncPodfile(before, unusedFamilies(used, keep));
      if (r.skippedReason != null) {
        console.line(
          '  ${console.icon(Severity.warning)} Podfile left alone: ${r.skippedReason}.',
        );
      } else {
        write(project.podfile, before, r.text, podBegin);
        if (before != r.text && !dry) {
          console.line(console.dim('      Run: cd ios && pod install'));
        }
      }
    }
  } else if (managePod) {
    console.line(
      '  ${console.icon(Severity.info)} No ios/Podfile yet (run flutter build ios once); skipped',
    );
  }

  console.line();
  console.line(
    changed == 0
        ? console.green('Everything is in sync.')
        : dry
        ? console.yellow(
            '$changed file${changed == 1 ? '' : 's'} would change. Run without --dry-run to apply.',
          )
        : console.green(
            '$changed file${changed == 1 ? '' : 's'} updated. Next: dart run okapi:doctor',
          ),
  );
  console.line();
  return 0;
}

/// The managed region of [text] for printing.
String managedRegionPreview(String text, String beginMarker) {
  final end = beginMarker == podBegin ? podEnd : xmlEnd;
  return managedContent(text, beginMarker, end);
}
