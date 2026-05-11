import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_provider.dart' show secureStorageProvider;

/// User's opt-in choice for sending crash reports to Firebase
/// Crashlytics. Three-state semantics:
///
///   * null (unknown) — first launch; we treat as disabled and ask
///     the user explicitly the first time we have somewhere to ask.
///     Default is OFF so we never send before consent.
///   * false           — explicitly opted out.
///   * true            — explicitly opted in.
///
/// We sync the choice to Crashlytics.setCrashlyticsCollectionEnabled
/// on every change. When the user disables it, we also clear any
/// queued reports that hadn't been uploaded yet (deleteUnsentReports).
class CrashReportingNotifier extends StateNotifier<bool?> {
  static const _kKey = 'watchlog_crashlytics_optin_v1';
  final FlutterSecureStorage _storage;

  CrashReportingNotifier(this._storage) : super(null);

  Future<void> load() async {
    final raw = await _storage.read(key: _kKey);
    final value = raw == null ? null : raw == 'true';
    state = value;
    await _applyToCrashlytics(value ?? false);
  }

  Future<void> setEnabled(bool? enabled) async {
    state = enabled;
    if (enabled == null) {
      await _storage.delete(key: _kKey);
    } else {
      await _storage.write(key: _kKey, value: enabled.toString());
    }
    await _applyToCrashlytics(enabled ?? false);
  }

  Future<void> _applyToCrashlytics(bool enabled) async {
    try {
      final cl = FirebaseCrashlytics.instance;
      await cl.setCrashlyticsCollectionEnabled(enabled);
      if (!enabled) {
        // Pending reports are gone the moment the user revokes consent.
        await cl.deleteUnsentReports();
      }
    } catch (e) {
      // Crashlytics may be unavailable in debug builds or if Firebase
      // isn't configured — never break the app over telemetry plumbing.
      debugPrint('Crashlytics toggle failed: $e');
    }
  }
}

final crashReportingProvider =
    StateNotifierProvider<CrashReportingNotifier, bool?>((ref) {
  return CrashReportingNotifier(ref.watch(secureStorageProvider));
});
