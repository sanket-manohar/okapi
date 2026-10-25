// Okapi example app. Shows every feature on one screen.

import 'package:flutter/material.dart';
import 'package:okapi/okapi.dart';

// A feature: what it needs, and what's optional.
const videoCall = OkapiFeature(
  id: 'video_call',
  name: 'Video calls',
  description: 'See and hear your friends. A headset is optional.',
  required: [OkapiPermission.camera, OkapiPermission.microphone],
  optional: [OkapiPermission.bluetoothConnect],
  reasons: {
    OkapiPermission.camera: 'So friends can see you.',
    OkapiPermission.microphone: 'So friends can hear you.',
    OkapiPermission.bluetoothConnect: 'Use your Bluetooth headset.',
  },
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Okapi.configure(
    OkapiConfig(
      debugLogs: true,
      // Friendly limits, but allow asking on the very first launch in the demo.
      askPolicy: OkapiAskPolicy.recommended.copyWith(skipFirstLaunches: 0),
    ),
  );
  runApp(const OkapiExampleApp());
}

class OkapiExampleApp extends StatefulWidget {
  const OkapiExampleApp({super.key});

  @override
  State<OkapiExampleApp> createState() => _OkapiExampleAppState();
}

class _OkapiExampleAppState extends State<OkapiExampleApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Okapi',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5A2A1E),
        extensions: [OkapiThemeData.okapiLight()],
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF5A2A1E),
        brightness: Brightness.dark,
        extensions: [OkapiThemeData.okapiDark()],
      ),
      // Debug builds only: a floating panel to simulate any permission state.
      builder: (context, child) => OkapiDebugPanel(child: child!),
      home: HomePage(
        dark: _mode == ThemeMode.dark,
        onToggleTheme: () => setState(
          () => _mode =
              _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.dark, required this.onToggleTheme});

  final bool dark;
  final VoidCallback onToggleTheme;

  void _snack(BuildContext context, OkapiResult r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${r.permission.name}: ${r.outcome.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Okapi'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _Header('1. Guided flow (bottom sheet)'),
          FilledButton.icon(
            icon: const Icon(Icons.photo_camera_rounded),
            label: const Text('Ask for camera'),
            onPressed: () async {
              final r = await Okapi.ask(
                context,
                OkapiPermission.camera,
                reason: 'Scan QR codes to pay in one tap.',
              );
              if (context.mounted) _snack(context, r);
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.location_on_rounded),
            label: const Text('Ask for location (dialog style)'),
            onPressed: () async {
              final r = await Okapi.ask(
                context,
                OkapiPermission.locationWhenInUse,
                presenter: const OkapiDialogPresenter(),
              );
              if (context.mounted) _snack(context, r);
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.notifications_rounded),
            label: const Text('Ask for notifications (full screen)'),
            onPressed: () async {
              final r = await Okapi.ask(
                context,
                OkapiPermission.notification,
                presenter: const OkapiFullScreenPresenter(),
              );
              if (context.mounted) _snack(context, r);
            },
          ),
          const _Header('2. Several at once'),
          OutlinedButton.icon(
            icon: const Icon(Icons.video_call_rounded),
            label: const Text('Camera + microphone'),
            onPressed: () => Okapi.askAll(
              context,
              const [OkapiPermission.camera, OkapiPermission.microphone],
              reasons: const {
                OkapiPermission.camera: 'See each other on video calls.',
                OkapiPermission.microphone: 'Hear each other on calls.',
              },
            ),
          ),
          const _Header('3. Your own widget, Okapi\'s logic'),
          OutlinedButton.icon(
            icon: const Icon(Icons.brush_rounded),
            label: const Text('Contacts with a custom card'),
            onPressed: () => Okapi.ask(
              context,
              OkapiPermission.contacts,
              presenter: OkapiCustomPresenter(
                style: OkapiPresentationStyle.dialog,
                builder: (context, prompt, c) =>
                    _MyCustomCard(prompt: prompt, controller: c),
              ),
            ),
          ),
          const _Header('4. Live tiles'),
          const OkapiPermissionTile(permission: OkapiPermission.photos),
          const OkapiPermissionTile(permission: OkapiPermission.microphone),
          const OkapiPermissionTile(permission: OkapiPermission.bluetooth),
          const _Header('5. Gate'),
          SizedBox(
            height: 320,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: OkapiPermissionGate(
                permission: OkapiPermission.camera,
                reason: 'Point your camera at a QR code.',
                child: const Center(
                  child: Text(
                    '📷  Camera is ready',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
          const _Header('6. Onboarding screen'),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (ctx) => OkapiOnboarding(
                  permissions: const [
                    OkapiPermission.notification,
                    OkapiPermission.locationWhenInUse,
                    OkapiPermission.photos,
                  ],
                  requiredPermissions: const [OkapiPermission.notification],
                  onComplete: (_) => Navigator.of(ctx).pop(),
                ),
              ),
            ),
            child: const Text('Open onboarding'),
          ),
          const _Header('7. Low level'),
          OutlinedButton(
            onPressed: Okapi.openAppSettings,
            child: const Text('Open app settings'),
          ),
          const _Header('8. Ask for a feature'),
          FilledButton.icon(
            icon: const Icon(Icons.videocam_rounded),
            label: const Text('Start a video call'),
            onPressed: () async {
              final r = await Okapi.askFeature(context, videoCall);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(switch (r.level) {
                    OkapiFeatureLevel.full => 'Calling with everything on',
                    OkapiFeatureLevel.partial => 'Calling without the headset',
                    OkapiFeatureLevel.unavailable =>
                      'Video calls need camera and mic',
                  }),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: OkapiFeatureGate(
                feature: videoCall,
                partialChild: const Center(
                  child: Text('🎥  Ready (no headset)'),
                ),
                child: const Center(child: Text('🎥  Ready to call')),
              ),
            ),
          ),
          const _Header('9. Background reliability (Android)'),
          OutlinedButton.icon(
            icon: const Icon(Icons.battery_saver_rounded),
            label: const Text('Keep reminders on time'),
            onPressed: () async {
              final r = await Okapi.askBackgroundReliability(
                context,
                force: true,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      r.applicable
                          ? '${r.brand.displayName}: ready = ${r.ready}'
                          : 'Not needed on this phone',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Protect from auto-reset'),
            onPressed: () async {
              final s = await Okapi.protectFromAutoReset(context, force: true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Auto-reset: ${s.name}')),
                );
              }
            },
          ),
          const _Header('10. Privacy Center'),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.privacy_tip_rounded),
            label: const Text('Open Privacy & permissions'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OkapiPrivacyCenter(
                  features: [videoCall],
                  permissions: [
                    OkapiPermission.notification,
                    OkapiPermission.locationWhenInUse,
                    OkapiPermission.photos,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 28, bottom: 10),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}

/// Example of a completely custom prompt using the controller.
class _MyCustomCard extends StatelessWidget {
  const _MyCustomCard({required this.prompt, required this.controller});

  final OkapiPrompt prompt;
  final OkapiPromptController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          controller.iconOf(prompt.permission),
          size: 56,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 16),
        Text(
          prompt.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(prompt.message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Row(
          children: [
            if (prompt.secondaryLabel != null)
              Expanded(
                child: TextButton(
                  onPressed: controller.decline,
                  child: Text(prompt.secondaryLabel!),
                ),
              ),
            Expanded(
              child: FilledButton(
                onPressed: controller.accept,
                child: Text(prompt.primaryLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
