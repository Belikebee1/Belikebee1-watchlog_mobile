import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_provider.dart' show secureStorageProvider;

/// User opt-in for anonymous Firebase Analytics. Same shape as the
/// crash-reporting toggle: tri-state nullable bool, default OFF, user
/// must flip it explicitly. We never auto-enable.
///
/// Events we log when enabled (none of them carry token bytes, hostnames,
/// or any other identifier the user might consider sensitive):
///
///   * app_open             — bootstrap finished
///   * pair_success         — a new server was added via QR
///   * action_restart       — restart-service shortcut tapped
///   * action_apply_security
///   * push_received        — FCM message landed in foreground
///   * theme_changed        — user flipped appearance toggle
///   * lang_changed         — user flipped language toggle
///
/// Everything else stays out by policy; the goal is to learn what
/// features people actually use, not who uses them.
class AnalyticsNotifier extends StateNotifier<bool?> {
  static const _kKey = 'watchlog_analytics_optin_v1';
  final FlutterSecureStorage _storage;

  AnalyticsNotifier(this._storage) : super(null);

  Future<void> load() async {
    final raw = await _storage.read(key: _kKey);
    final value = raw == null ? null : raw == 'true';
    state = value;
    await _applyToFirebase(value ?? false);
  }

  Future<void> setEnabled(bool? enabled) async {
    state = enabled;
    if (enabled == null) {
      await _storage.delete(key: _kKey);
    } else {
      await _storage.write(key: _kKey, value: enabled.toString());
    }
    await _applyToFirebase(enabled ?? false);
  }

  Future<void> _applyToFirebase(bool enabled) async {
    try {
      await FirebaseAnalytics.instance
          .setAnalyticsCollectionEnabled(enabled);
      // setConsent is iOS-side and harmless on Android.
      await FirebaseAnalytics.instance.setConsent(
        analyticsStorageConsentGranted: enabled,
        adStorageConsentGranted: false,
        adUserDataConsentGranted: false,
        adPersonalizationSignalsConsentGranted: false,
      );
    } catch (e) {
      debugPrint('Analytics toggle failed: $e');
    }
  }

  /// Helper for the rest of the app — sites that want to log an event
  /// don't have to import FirebaseAnalytics directly, and the no-op
  /// here means callers never have to guard on the opt-in state.
  Future<void> logEvent(String name, {Map<String, Object?>? params}) async {
    if (state != true) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: params?.map((k, v) => MapEntry(k, v as Object)),
      );
    } catch (_) {/* never break the UI over telemetry */}
  }
}

final analyticsProvider =
    StateNotifierProvider<AnalyticsNotifier, bool?>((ref) {
  return AnalyticsNotifier(ref.watch(secureStorageProvider));
});
