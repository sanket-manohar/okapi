// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/device.dart';
import '../../core/okapi.dart';
import '../../core/permission.dart';
import '../../core/policy.dart';
import '../../core/status.dart';
import '../../core/store.dart';
import '../../platform/dev_platform.dart';
import '../icons.dart';

/// A floating debug panel to simulate any permission state without
/// reinstalling the app or resetting the phone.
///
/// Add it once, in `MaterialApp.builder`:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => OkapiDebugPanel(child: child!),
/// )
/// ```
///
/// It is active only in debug builds (`kDebugMode`). In profile and release
/// builds it returns [child] untouched.
class OkapiDebugPanel extends StatefulWidget {
  /// Creates the panel.
  const OkapiDebugPanel({
    super.key,
    required this.child,
    this.enabled = kDebugMode,
    this.permissions,
  });

  /// Your app.
  final Widget child;

  /// Force-disable the panel in debug builds. It is never active in release
  /// builds, even when true.
  final bool enabled;

  /// Permissions listed first. Defaults to the ones Okapi has seen, then all.
  final List<OkapiPermission>? permissions;

  @override
  State<OkapiDebugPanel> createState() => _OkapiDebugPanelState();
}

class _OkapiDebugPanelState extends State<OkapiDebugPanel> {
  final OkapiDevOverrides _o = OkapiDevOverrides.instance;
  bool _active = false;
  bool _open = false;
  bool _showAll = false;
  Offset? _pos;
  String? _note;

  @override
  void initState() {
    super.initState();
    _active = widget.enabled && !kReleaseMode && installOkapiDevPlatform();
    if (_active) _o.addListener(_rebuild);
  }

  @override
  void dispose() {
    _o.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _toast(String text) {
    setState(() => _note = text);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _note == text) setState(() => _note = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return widget.child;
    final size = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final pos = _pos ?? Offset(size.width - 64, size.height - pad.bottom - 150);

    return Directionality(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      child: Stack(
        children: [
          widget.child,
          if (_open) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _open = false),
                child: const ColoredBox(color: Color(0x66000000)),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: pad.bottom + 12,
              child: Center(child: _panel(context, size)),
            ),
          ],
          if (!_open)
            Positioned(
              left: pos.dx.clamp(8.0, size.width - 56),
              top: pos.dy.clamp(pad.top + 8, size.height - 56),
              child: GestureDetector(
                onPanUpdate: (d) => setState(() => _pos = pos + d.delta),
                onTap: () => setState(() => _open = true),
                child: _Fab(count: _o.count),
              ),
            ),
        ],
      ),
    );
  }

  List<OkapiPermission> get _list {
    final first = widget.permissions ?? Okapi.knownPermissions.toList();
    if (!_showAll && first.isNotEmpty) return first;
    return [
      ...first,
      ...OkapiPermission.values.where((p) => !first.contains(p)),
    ];
  }

  Widget _panel(BuildContext context, Size size) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: scheme.surface,
      elevation: 12,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFF2E140D),
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.bug_report_rounded,
                    color: Color(0xFFF2C9A0),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Okapi debug',
                      style: TextStyle(
                        color: Color(0xFFFFF8EF),
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_o.count > 0)
                    TextButton(
                      onPressed: _o.clear,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFF2C9A0),
                      ),
                      child: Text('Reset ${_o.count}'),
                    ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _open = false),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFFF8EF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                shrinkWrap: true,
                children: [
                  _label(textTheme, 'Simulation'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('System dialog: user taps Allow'),
                    subtitle: const Text(
                      'Simulated permissions become granted when requested.',
                    ),
                    value: _o.allowOnRequest,
                    onChanged: (v) => _o.allowOnRequest = v,
                  ),
                  const SizedBox(height: 4),
                  const Text('Unused-app auto-reset'),
                  const SizedBox(height: 6),
                  _chips<OkapiAutoResetStatus?>(
                    value: _o.autoReset,
                    options: const {
                      null: 'Real',
                      OkapiAutoResetStatus.enabled: 'On',
                      OkapiAutoResetStatus.exempt: 'Exempt',
                      OkapiAutoResetStatus.notAvailable: 'N/A',
                    },
                    onSelected: (v) => _o.autoReset = v,
                  ),
                  const SizedBox(height: 12),
                  const Text('Preview phone maker'),
                  const SizedBox(height: 6),
                  _chips<OkapiOemBrand?>(
                    value: _o.brand,
                    options: const {
                      null: 'Real',
                      OkapiOemBrand.xiaomi: 'Xiaomi',
                      OkapiOemBrand.samsung: 'Samsung',
                      OkapiOemBrand.vivo: 'vivo',
                      OkapiOemBrand.oppo: 'OPPO',
                      OkapiOemBrand.realme: 'realme',
                      OkapiOemBrand.oneplus: 'OnePlus',
                      OkapiOemBrand.tecno: 'TECNO',
                    },
                    onSelected: (v) => _o.brand = v,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _label(textTheme, 'Permissions')),
                      FilterChip(
                        label: const Text('Show all'),
                        selected: _showAll,
                        onSelected: (v) => setState(() => _showAll = v),
                      ),
                    ],
                  ),
                  for (final p in _list) _permissionRow(p),
                  _label(textTheme, 'Stored data'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          await OkapiPolicyEngine.reset();
                          _toast('Ask history cleared');
                        },
                        child: const Text('Reset ask history'),
                      ),
                      OutlinedButton(
                        onPressed: () async {
                          await OkapiStore.clear('okapi.');
                          await OkapiPolicyEngine.reset(launchesToo: true);
                          _toast('Okapi storage cleared');
                        },
                        child: const Text('Clear Okapi storage'),
                      ),
                      const OutlinedButton(
                        onPressed: Okapi.openAppSettings,
                        child: Text('Open app settings'),
                      ),
                    ],
                  ),
                  if (_note != null) ...[
                    const SizedBox(height: 10),
                    Text(_note!, style: TextStyle(color: scheme.primary)),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Debug builds only. Not active in profile or release.',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(TextTheme textTheme, String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(
          text.toUpperCase(),
          style: textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _chips<T>({
    required T value,
    required Map<T, String> options,
    required ValueChanged<T> onSelected,
  }) =>
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final e in options.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: e.key == value,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onSelected(e.key),
            ),
        ],
      );

  Widget _permissionRow(OkapiPermission p) {
    final real = Okapi.lastKnown(p);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(okapiIconFor(p), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              if (real != null)
                Text(real.name, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 6),
          _chips<OkapiStatus?>(
            value: _o.statusOf(p),
            options: const {
              null: 'Real',
              OkapiStatus.granted: 'Granted',
              OkapiStatus.denied: 'Denied',
              OkapiStatus.permanentlyDenied: 'Blocked',
              OkapiStatus.limited: 'Limited',
              OkapiStatus.restricted: 'Restricted',
            },
            onSelected: (v) => _o.setStatus(p, v),
          ),
          if (p.hasService)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                p.name.startsWith('bluetooth')
                    ? 'Simulate Bluetooth off'
                    : 'Simulate Location Services off',
              ),
              value: _o.serviceOf(p) == OkapiServiceStatus.disabled,
              onChanged: (v) =>
                  _o.setService(p, v ? OkapiServiceStatus.disabled : null),
            ),
        ],
      ),
    );
  }
}

class _Fab extends StatelessWidget {
  const _Fab({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF5A2A1E),
        shape: const CircleBorder(),
        elevation: 6,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.bug_report_rounded, color: Color(0xFFF2C9A0)),
              if (count > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2BD9A0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Color(0xFF0E3B2C),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
}
