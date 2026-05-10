import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_provider.dart' show secureStorageProvider;

/// User's app-language preference. Three states:
///   * null         → follow the system locale (default)
///   * Locale('en') → force English
///   * Locale('pl') → force Polish
///
/// Stored in flutter_secure_storage to share the encryption envelope
/// with server tokens — one storage backend simplifies "wipe data" UX.
class LocaleNotifier extends StateNotifier<Locale?> {
  static const _kKey = 'watchlog_locale_v1';
  final FlutterSecureStorage _storage;

  LocaleNotifier(this._storage) : super(null);

  Future<void> load() async {
    final raw = await _storage.read(key: _kKey);
    state = _parse(raw);
  }

  Future<void> setLocale(Locale? locale) async {
    if (locale == state) return;
    state = locale;
    if (locale == null) {
      await _storage.delete(key: _kKey);
    } else {
      await _storage.write(key: _kKey, value: locale.languageCode);
    }
  }

  static Locale? _parse(String? raw) {
    switch (raw) {
      case 'en':
        return const Locale('en');
      case 'pl':
        return const Locale('pl');
      default:
        return null;
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref.watch(secureStorageProvider));
});
