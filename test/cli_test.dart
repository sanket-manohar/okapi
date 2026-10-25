import 'package:flutter_test/flutter_test.dart';
import 'package:okapi/okapi.dart';
import 'package:okapi/src/cli/doctor.dart';
import 'package:okapi/src/cli/project.dart';
import 'package:okapi/src/cli/sync.dart';

const manifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <!-- <uses-permission android:name="android.permission.CAMERA" /> -->
    <application android:label="demo">
    </application>
</manifest>
''';

const plist = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
\t<key>CFBundleName</key>
\t<string>demo</string>
\t<key>NSLocationWhenInUseUsageDescription</key>
\t<string>Show stores within 5 km of you.</string>
</dict>
</plist>
''';

const podfile = '''
platform :ios, '13.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
  end
end
''';

void main() {
  test('comments are ignored when scanning', () {
    expect(stripComments('final p = OkapiPermission.camera; // OkapiPermission.sms', false).$1,
        isNot(contains('sms')));
    expect(stripComments("final u = 'https://x.dev'; OkapiPermission.photos", false).$1,
        contains('photos'));
    final (rest, block) = stripComments('a /* start', false);
    expect(rest.trim(), 'a');
    expect(block, isTrue);
  });

  test('commented-out manifest lines do not count', () {
    final names = parseManifest(manifest).map((e) => e.name);
    expect(names, contains('android.permission.INTERNET'));
    expect(names, isNot(contains('android.permission.CAMERA')));
  });

  test('sync adds missing Android permissions once', () {
    final used = {OkapiPermission.camera, OkapiPermission.photos};
    final once = syncManifest(manifest, used);
    expect(once, contains('android.permission.CAMERA'));
    expect(once, contains('android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"'));
    expect(syncManifest(once, used), once); // Idempotent.
    final removed = syncManifest(once, {});
    expect(removed, isNot(contains('okapi:begin')));
  });

  test('sync keeps edited plist texts and skips existing keys', () {
    final used = {OkapiPermission.camera, OkapiPermission.locationWhenInUse};
    final once = syncPlist(plist, used);
    expect(once, contains('NSCameraUsageDescription'));
    expect('NSLocationWhenInUseUsageDescription'.allMatches(once).length, 1);
    final edited = once.replaceFirst(RegExp(r'TODO:[^<]*'), 'Scan QR codes to pay.');
    expect(syncPlist(edited, used), contains('Scan QR codes to pay.'));
  });

  test('sync writes Podfile flags inside post_install', () {
    final r = syncPodfile(podfile, {'CONTACTS', 'CALENDAR'});
    expect(r.skippedReason, isNull);
    expect(r.text, contains("OKAPI_EXCLUDE_CALENDAR OKAPI_EXCLUDE_CONTACTS"));
    expect(r.text.indexOf('okapi:begin'), greaterThan(r.text.indexOf('post_install')));
    expect(syncPodfile(r.text, {}).text, podfile);
  });

  test('vague iOS texts are flagged', () {
    expect(vagueReason('This app needs access to your camera.'), isNotNull);
    expect(vagueReason('TODO: explain'), 'is still a placeholder');
    expect(vagueReason('Scan QR codes to pay in one tap.'), isNull);
  });

  test('pubspec okapi section is read', () {
    final c = CliConfig.parse('''
name: demo
okapi:
  permissions: [contacts, nope]
  ios_keep:
    - bluetooth
''');
    expect(c.extra, {OkapiPermission.contacts});
    expect(c.iosKeep, {'BLUETOOTH'});
    expect(c.problems.single, contains('nope'));
  });

  test('unused iOS families exclude used ones', () {
    final f = unusedFamilies({OkapiPermission.camera}, {'BLUETOOTH'});
    expect(f, isNot(contains('CAMERA')));
    expect(f, isNot(contains('BLUETOOTH')));
    expect(f, contains('CONTACTS'));
  });
}
