import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_provider.dart' show secureStorageProvider;

/// Persists the user's appearance choice across app launches.
///
/// Three options exposed to the user:
///   * [ThemeMode.system] — follow the OS (default)
///   * [ThemeMode.light]  — always light
///   * [ThemeMode.dark]   — always dark
///
/// Stored in flutter_secure_storage rather than SharedPreferences so it
/// shares the same encryption envelope as the server tokens — one
/// storage backend for the whole app keeps deletion semantics simple
/// when the user wipes data.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _kKey = 'watchlog_theme_mode_v1';
  final FlutterSecureStorage _storage;

  ThemeModeNotifier(this._storage) : super(ThemeMode.system);

  Future<void> load() async {
    final raw = await _storage.read(key: _kKey);
    state = _parse(raw);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    await _storage.write(key: _kKey, value: _serialize(mode));
  }

  static ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      case null:
      default:
        return ThemeMode.system;
    }
  }

  static String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(secureStorageProvider));
});
