import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okapi/okapi.dart';
import 'package:okapi/testing.dart';

Future<BuildContext> _pumpApp(WidgetTester tester) async {
  late BuildContext ctx;
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (c) {
      ctx = c;
      return const SizedBox();
    }),
  ));
  return ctx;
}

void main() {
  late FakeOkapiPlatform fake;

  setUp(() {
    Okapi.debugReset();
    fake = FakeOkapiPlatform();
    OkapiPlatform.instance = fake;
    Okapi.configure(const OkapiConfig(presenter: OkapiNoUiPresenter()));
  });

  test('status codes round-trip', () {
    for (final s in OkapiStatus.values) {
      expect(OkapiStatus.fromCode(s.code), s);
    }
  });

  test('canProceed covers usable states only', () {
    expect(OkapiStatus.granted.canProceed, isTrue);
    expect(OkapiStatus.limited.canProceed, isTrue);
    expect(OkapiStatus.provisional.canProceed, isTrue);
    expect(OkapiStatus.notApplicable.canProceed, isTrue);
    expect(OkapiStatus.denied.canProceed, isFalse);
    expect(OkapiStatus.permanentlyDenied.canProceed, isFalse);
    expect(OkapiStatus.restricted.canProceed, isFalse);
  });

  test('every permission has declaration info and a name', () {
    for (final p in OkapiPermission.values) {
      expect(OkapiStrings.english.nameOf(p), isNotEmpty);
      OkapiDeclarations.android(p);
      OkapiDeclarations.ios(p);
    }
  });

  test('requests are queued, never overlapping', () async {
    fake.requestResults[OkapiPermission.camera] = OkapiStatus.granted;
    fake.requestResults[OkapiPermission.microphone] = OkapiStatus.denied;
    final results = await Future.wait([
      Okapi.request(OkapiPermission.camera),
      Okapi.request(OkapiPermission.microphone),
    ]);
    expect(results, [OkapiStatus.granted, OkapiStatus.denied]);
    expect(fake.requests.length, 2);
  });

  testWidgets('ask grants after system dialog', (tester) async {
    final ctx = await _pumpApp(tester);
    fake.requestResults[OkapiPermission.camera] = OkapiStatus.granted;
    final r = await Okapi.ask(ctx, OkapiPermission.camera);
    expect(r.outcome, OkapiOutcome.granted);
    expect(r.attempts, 1);
  });

  testWidgets('ask returns immediately when already granted', (tester) async {
    final ctx = await _pumpApp(tester);
    fake.statuses[OkapiPermission.camera] = OkapiStatus.granted;
    final r = await Okapi.ask(ctx, OkapiPermission.camera);
    expect(r.outcome, OkapiOutcome.granted);
    expect(fake.requests, isEmpty);
  });

  testWidgets('undeclared permission throws a helpful error',
      (tester) async {
    final ctx = await _pumpApp(tester);
    fake.undeclared.add(OkapiPermission.camera);
    await expectLater(
      Okapi.ask(ctx, OkapiPermission.camera),
      throwsA(isA<OkapiException>()
          .having((e) => e.code, 'code', OkapiException.notDeclared)),
    );
  });

  testWidgets('restricted never shows the system dialog', (tester) async {
    final ctx = await _pumpApp(tester);
    fake.statuses[OkapiPermission.photos] = OkapiStatus.restricted;
    final r = await Okapi.ask(ctx, OkapiPermission.photos);
    expect(r.outcome, OkapiOutcome.restricted);
    expect(fake.requests, isEmpty);
  });

  testWidgets('permanently denied guides to settings and re-checks',
      (tester) async {
    Okapi.configure(OkapiConfig(
      presenter: OkapiFunctionPresenter((_, __) async => true),
    ));
    final ctx = await _pumpApp(tester);
    fake.statuses[OkapiPermission.location] = OkapiStatus.permanentlyDenied;
    fake.onSettingsReturn = {OkapiPermission.location: OkapiStatus.granted};
    final r = await Okapi.ask(ctx, OkapiPermission.location);
    expect(fake.settingsOpened, 1);
    expect(r.outcome, OkapiOutcome.granted);
    expect(r.openedSettings, isTrue);
  });

  testWidgets('"Not now" on the rationale burns no system dialog',
      (tester) async {
    Okapi.configure(OkapiConfig(
      presenter: OkapiFunctionPresenter((_, __) async => false),
    ));
    final ctx = await _pumpApp(tester);
    final r = await Okapi.ask(ctx, OkapiPermission.contacts);
    expect(r.outcome, OkapiOutcome.dismissedRationale);
    expect(fake.requests, isEmpty);
  });

  testWidgets('service disabled is reported', (tester) async {
    final ctx = await _pumpApp(tester);
    fake.services[OkapiPermission.location] = OkapiServiceStatus.disabled;
    final r = await Okapi.ask(ctx, OkapiPermission.location);
    expect(r.outcome, OkapiOutcome.serviceDisabled);
  });

  testWidgets('askAll keeps the caller order', (tester) async {
    final ctx = await _pumpApp(tester);
    fake.statuses[OkapiPermission.microphone] = OkapiStatus.granted;
    fake.requestResults[OkapiPermission.camera] = OkapiStatus.granted;
    final r = await Okapi.askAll(
        ctx, [OkapiPermission.camera, OkapiPermission.microphone]);
    expect(r.keys.toList(),
        [OkapiPermission.camera, OkapiPermission.microphone]);
    expect(r.values.every((x) => x.isGranted), isTrue);
  });

  testWidgets('sheet presenter renders title and buttons', (tester) async {
    Okapi.configure(const OkapiConfig());
    final ctx = await _pumpApp(tester);
    final future = Okapi.ask(ctx, OkapiPermission.camera);
    await tester.pumpAndSettle();
    expect(find.text('Allow Camera?'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    final r = await future;
    expect(r.outcome, OkapiOutcome.dismissedRationale);
  });

  group('ask policy', () {
    testWidgets('"Not now" starts a cooldown', (tester) async {
      Okapi.configure(OkapiConfig(
        presenter: OkapiFunctionPresenter((_, __) async => false),
        askPolicy: const OkapiAskPolicy(cooldownAfterNotNow: Duration(days: 2)),
      ));
      final ctx = await _pumpApp(tester);
      final first = await Okapi.ask(ctx, OkapiPermission.camera);
      expect(first.outcome, OkapiOutcome.dismissedRationale);
      final second = await Okapi.ask(ctx, OkapiPermission.camera);
      expect(second.outcome, OkapiOutcome.deferredByPolicy);
      expect(second.policy?.reason, OkapiPolicyReason.notNowCooldown);
    });

    testWidgets('force bypasses the policy', (tester) async {
      Okapi.configure(OkapiConfig(
        presenter: OkapiFunctionPresenter((_, __) async => false),
        askPolicy: const OkapiAskPolicy(cooldownAfterNotNow: Duration(days: 2)),
      ));
      final ctx = await _pumpApp(tester);
      await Okapi.ask(ctx, OkapiPermission.camera);
      final again = await Okapi.ask(ctx, OkapiPermission.camera, force: true);
      expect(again.outcome, OkapiOutcome.dismissedRationale);
    });

    testWidgets('skips the first launch', (tester) async {
      Okapi.configure(const OkapiConfig(
        presenter: OkapiNoUiPresenter(),
        askPolicy: OkapiAskPolicy(skipFirstLaunches: 1),
      ));
      final ctx = await _pumpApp(tester);
      final r = await Okapi.ask(ctx, OkapiPermission.camera);
      expect(r.outcome, OkapiOutcome.deferredByPolicy);
      expect(r.policy?.reason, OkapiPolicyReason.firstLaunches);
      expect(fake.requests, isEmpty);
    });

    testWidgets('session limit', (tester) async {
      Okapi.configure(const OkapiConfig(
        presenter: OkapiNoUiPresenter(),
        askPolicy: OkapiAskPolicy(maxPromptsPerSession: 1),
      ));
      final ctx = await _pumpApp(tester);
      await Okapi.ask(ctx, OkapiPermission.camera);
      final r = await Okapi.ask(ctx, OkapiPermission.microphone);
      expect(r.outcome, OkapiOutcome.deferredByPolicy);
      expect(r.policy?.reason, OkapiPolicyReason.sessionLimit);
    });
  });

  group('features', () {
    const call = OkapiFeature(
      id: 'call',
      name: 'Video calls',
      required: [OkapiPermission.camera, OkapiPermission.microphone],
      optional: [OkapiPermission.bluetoothConnect],
    );

    test('level is computed from statuses', () {
      expect(
        OkapiFeatureLevel.of(call, {
          OkapiPermission.camera: OkapiStatus.granted,
          OkapiPermission.microphone: OkapiStatus.granted,
          OkapiPermission.bluetoothConnect: OkapiStatus.denied,
        }),
        OkapiFeatureLevel.partial,
      );
      expect(
        OkapiFeatureLevel.of(call, {OkapiPermission.camera: OkapiStatus.granted}),
        OkapiFeatureLevel.unavailable,
      );
    });

    testWidgets('askFeature reports partial when optional is refused',
        (tester) async {
      final ctx = await _pumpApp(tester);
      fake.requestResults
        ..[OkapiPermission.camera] = OkapiStatus.granted
        ..[OkapiPermission.microphone] = OkapiStatus.granted
        ..[OkapiPermission.bluetoothConnect] = OkapiStatus.denied;
      final r = await Okapi.askFeature(ctx, call);
      expect(r.level, OkapiFeatureLevel.partial);
      expect(r.isAvailable, isTrue);
      expect(r.missingOptional, [OkapiPermission.bluetoothConnect]);
    });

    testWidgets('feature prompt marks optional permissions', (tester) async {
      OkapiPrompt? seen;
      Okapi.configure(OkapiConfig(
        presenter: OkapiFunctionPresenter((_, p) async {
          seen ??= p;
          return false;
        }),
      ));
      final ctx = await _pumpApp(tester);
      await Okapi.askFeature(ctx, call);
      expect(seen?.featureName, 'Video calls');
      expect(seen?.optional, {OkapiPermission.bluetoothConnect});
    });
  });

  group('background reliability', () {
    testWidgets('not applicable on iOS', (tester) async {
      fake.device = const OkapiDeviceInfo(
        platform: 'ios',
        manufacturer: 'Apple',
        brand: 'Apple',
        model: 'iPhone',
        osVersion: '18',
        sdkInt: 0,
        appName: 'Test',
      );
      final ctx = await _pumpApp(tester);
      final r = await Okapi.askBackgroundReliability(ctx);
      expect(r.applicable, isFalse);
      expect(r.ready, isTrue);
    });

    testWidgets('Xiaomi shows steps and opens Autostart', (tester) async {
      OkapiPrompt? seen;
      fake.device = fakeAndroidDevice(brand: OkapiOemBrand.xiaomi);
      fake.oemScreens.addAll({OkapiOemScreen.autostart, OkapiOemScreen.battery});
      fake.undeclared.add(OkapiPermission.ignoreBatteryOptimizations);
      Okapi.configure(OkapiConfig(
        presenter: OkapiFunctionPresenter((_, p) async {
          seen ??= p;
          return true;
        }),
      ));
      final ctx = await _pumpApp(tester);
      final r = await Okapi.askBackgroundReliability(ctx);
      expect(seen?.kind, OkapiPromptKind.backgroundReliability);
      expect(seen?.steps.first, 'Tap Open settings.');
      expect(seen?.steps[1], contains('Test App'));
      expect(fake.openedOemScreens.first, OkapiOemScreen.autostart);
      expect(r.brand, OkapiOemBrand.xiaomi);
    });

    test('brand detection', () {
      expect(fakeAndroidDevice(brand: OkapiOemBrand.vivo).oem, OkapiOemBrand.vivo);
      expect(
        const OkapiDeviceInfo(
          platform: 'android',
          manufacturer: 'Xiaomi',
          brand: 'Redmi',
          model: 'Note',
          osVersion: '14',
          sdkInt: 34,
          appName: 'A',
        ).oem,
        OkapiOemBrand.xiaomi,
      );
    });
  });

  group('auto-reset', () {
    testWidgets('mentions removed permissions and opens settings',
        (tester) async {
      OkapiPrompt? seen;
      fake.device = fakeAndroidDevice();
      fake.autoReset = OkapiAutoResetStatus.enabled;
      fake.onAutoResetSettingsReturn = OkapiAutoResetStatus.exempt;
      fake.store['okapi.granted'] = 'camera';
      fake.statuses[OkapiPermission.camera] = OkapiStatus.denied;
      Okapi.configure(OkapiConfig(
        presenter: OkapiFunctionPresenter((_, p) async {
          seen = p;
          return true;
        }),
      ));
      final ctx = await _pumpApp(tester);
      expect(await Okapi.revokedSinceLastLaunch(), [OkapiPermission.camera]);
      await Okapi.protectFromAutoReset(ctx, onlyIfRevoked: true);
      expect(seen?.kind, OkapiPromptKind.autoReset);
      expect(seen?.message, contains('Camera'));
      expect(fake.autoResetSettingsOpened, 1);
    });

    testWidgets('does nothing when exempt', (tester) async {
      fake.autoReset = OkapiAutoResetStatus.exempt;
      final ctx = await _pumpApp(tester);
      final s = await Okapi.protectFromAutoReset(ctx);
      expect(s, OkapiAutoResetStatus.exempt);
      expect(fake.autoResetSettingsOpened, 0);
    });
  });

  group('debug overrides', () {
    tearDown(() => OkapiDevOverrides.instance.clear());

    test('simulated status wins over the real one', () async {
      OkapiPlatform.instance = OkapiDevPlatform(fake);
      fake.statuses[OkapiPermission.camera] = OkapiStatus.granted;
      OkapiDevOverrides.instance.setStatus(
          OkapiPermission.camera, OkapiStatus.permanentlyDenied);
      expect(await Okapi.status(OkapiPermission.camera),
          OkapiStatus.permanentlyDenied);
      OkapiDevOverrides.instance.setStatus(OkapiPermission.camera, null);
      expect(await Okapi.status(OkapiPermission.camera), OkapiStatus.granted);
    });
  });
}
