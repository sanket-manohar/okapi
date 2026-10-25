// Copyright (c) 2026 Sanket Santosh Vidya Manohar. All rights reserved.
// Use of this source code is governed by the Okapi Software License found
// in the LICENSE file. Redistribution and republishing are not permitted.

import 'package:flutter/foundation.dart';

import '../platform/okapi_platform.dart';

/// A tiny key-value store kept on the device (Android SharedPreferences,
/// iOS UserDefaults) through the platform channel, so Okapi needs no extra
/// packages. Holds only timestamps, counters and flags; never personal data.
class OkapiStore {
  OkapiStore._();

  static Map<String, String>? _cache;
  static Future<Map<String, String>>? _loading;
  static OkapiPlatform? _owner;

  static Future<Map<String, String>> _load() {
    final platform = OkapiPlatform.instance;
    if (!identical(_owner, platform)) {
      // A different platform (tests, debug panel): start fresh.
      _owner = platform;
      _cache = null;
      _loading = null;
    }
    final cache = _cache;
    if (cache != null) return SynchronousFuture(cache);
    return _loading ??= _read(platform);
  }

  static Future<Map<String, String>> _read(OkapiPlatform platform) async {
    try {
      final map = Map.of(await platform.loadStore());
      if (identical(_owner, platform)) _cache = map;
      return map;
    } catch (_) {
      // Not ready yet (for example called before runApp): try again later
      // instead of caching an empty store.
      if (identical(_owner, platform)) _loading = null;
      return <String, String>{};
    }
  }

  /// Reads a value.
  static Future<String?> get(String key) async => (await _load())[key];

  /// Writes a value; `null` removes it.
  static Future<void> set(String key, String? value) async {
    final map = await _load();
    if (value == null) {
      if (!map.containsKey(key)) return;
      map.remove(key);
    } else {
      if (map[key] == value) return;
      map[key] = value;
    }
    try {
      await OkapiPlatform.instance.writeStore(key, value);
    } catch (_) {
      // Storage is best-effort; never break a permission flow over it.
    }
  }

  /// Reads an integer.
  static Future<int?> getInt(String key) async =>
      int.tryParse(await get(key) ?? '');

  /// Reads a timestamp.
  static Future<DateTime?> getTime(String key) async {
    final ms = await getInt(key);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Writes a timestamp.
  static Future<void> setTime(String key, DateTime value) =>
      set(key, '${value.millisecondsSinceEpoch}');

  /// Removes every key starting with [prefix].
  static Future<void> clear(String prefix) async {
    final map = await _load();
    for (final k in map.keys.where((k) => k.startsWith(prefix)).toList()) {
      await set(k, null);
    }
  }

  /// All stored keys and values (for the debug panel).
  static Future<Map<String, String>> snapshot() async =>
      Map.unmodifiable(await _load());

  /// Forgets the in-memory copy.
  @visibleForTesting
  static void resetCache() {
    _owner = null;
    _cache = null;
    _loading = null;
  }
}
