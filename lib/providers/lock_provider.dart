import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'auth_provider.dart' show secureStorageProvider;

/// Persisted app-lock configuration.
///
/// Why minutes (not seconds): we expose discrete presets (immediate /
/// 1 / 5 / 15 / 60 min / never) in Settings — sub-minute granularity
/// would invite "lock me 30 seconds after I close the app" requests
/// the OS already enforces via its own keychain timing.
class LockConfig {
  /// Master switch. When false, the app is unlocked permanently and
  /// the auto-lock timer / secure-screen flag don't run.
  final bool biometricEnabled;

  /// How many minutes of background time before the app re-locks.
  /// 0 = lock as soon as the app loses focus.
  /// -1 (the "never" sentinel) = unlock once per session, never relock.
  final int autoLockMinutes;

  /// Hides the live UI from the OS app switcher / screenshot APIs.
  /// Android sets FLAG_SECURE on the activity; iOS replaces the
  /// snapshot with a blank image.
  final bool secureScreen;

  const LockConfig({
    required this.biometricEnabled,
    required this.autoLockMinutes,
    required this.secureScreen,
  });

  static const defaults = LockConfig(
    biometricEnabled: false,
    autoLockMinutes: 5,
    secureScreen: false,
  );

  LockConfig copyWith({
    bool? biometricEnabled,
    int? autoLockMinutes,
    bool? secureScreen,
  }) =>
      LockConfig(
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
        secureScreen: secureScreen ?? this.secureScreen,
      );

  Map<String, dynamic> toJson() => {
        'biometric_enabled': biometricEnabled,
        'auto_lock_minutes': autoLockMinutes,
        'secure_screen': secureScreen,
      };

  factory LockConfig.fromJson(Map<String, dynamic> json) => LockConfig(
        biometricEnabled: json['biometric_enabled'] as bool? ?? false,
        autoLockMinutes: json['auto_lock_minutes'] as int? ?? 5,
        secureScreen: json['secure_screen'] as bool? ?? false,
      );
}

/// Runtime lock state. [config] is the user's persisted settings;
/// [locked] flips true when the auto-lock timer expires or the app
/// resumes after being backgrounded long enough.
///
/// [biometricAvailable] tells the UI whether the device has hardware
/// to enroll — when false, the toggle should be greyed out instead of
/// flipping a setting that wouldn't take effect.
class LockState {
  final LockConfig config;
  final bool locked;
  final bool biometricAvailable;

  const LockState({
    required this.config,
    required this.locked,
    required this.biometricAvailable,
  });

  LockState copyWith({
    LockConfig? config,
    bool? locked,
    bool? biometricAvailable,
  }) =>
      LockState(
        config: config ?? this.config,
        locked: locked ?? this.locked,
        biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      );
}

class LockNotifier extends StateNotifier<LockState> {
  static const _kKey = 'watchlog_lock_v1';
  final FlutterSecureStorage _storage;
  final LocalAuthentication _auth = LocalAuthentication();

  /// Wall-clock time when the app last went to background, or null
  /// if we're currently in the foreground / haven't backgrounded yet.
  DateTime? _backgroundedAt;

  LockNotifier(this._storage)
      : super(const LockState(
          config: LockConfig.defaults,
          locked: false,
          biometricAvailable: false,
        ));

  Future<void> load() async {
    final raw = await _storage.read(key: _kKey);
    LockConfig cfg = LockConfig.defaults;
    if (raw != null && raw.isNotEmpty) {
      try {
        cfg = LockConfig.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        /* keep defaults */
      }
    }
    final available = await _checkBiometricAvailable();
    // Start locked iff biometric is enabled AND auto-lock is not the
    // "never" sentinel — the user's most likely intent on opening the
    // app cold is "prove you're me before showing tokens".
    final startLocked = cfg.biometricEnabled && cfg.autoLockMinutes >= 0;
    state = LockState(
      config: cfg,
      locked: startLocked && available,
      biometricAvailable: available,
    );
  }

  Future<bool> _checkBiometricAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      // canCheckBiometrics is false on devices with no enrolled
      // biometric but device-credential (PIN/pattern) is still
      // available. local_auth's biometricOnly: false fallback will
      // surface that, so we don't require canCheckBiometrics here.
      return supported || canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateConfig(LockConfig cfg) async {
    state = state.copyWith(config: cfg);
    await _storage.write(key: _kKey, value: jsonEncode(cfg.toJson()));
    // If the user just enabled biometric and we're unlocked, no
    // immediate action — the lock kicks in on next backgrounding.
    // If they disabled it, ensure we're unlocked right now.
    if (!cfg.biometricEnabled && state.locked) {
      state = state.copyWith(locked: false);
    }
  }

  /// Called from the app's WidgetsBindingObserver when the lifecycle
  /// state changes. Drives the auto-lock timer.
  void onLifecycleChange(bool inForeground) {
    if (!state.config.biometricEnabled) return;
    if (!state.biometricAvailable) return;
    if (!inForeground) {
      // App going to background — stamp the time so the next resume
      // can compute "how long was it away".
      _backgroundedAt = DateTime.now();
      return;
    }
    // App returning from background.
    final stamp = _backgroundedAt;
    _backgroundedAt = null;
    if (stamp == null) return;
    final autoLockMinutes = state.config.autoLockMinutes;
    if (autoLockMinutes < 0) {
      // "Never" sentinel — once unlocked, stay unlocked.
      return;
    }
    if (autoLockMinutes == 0) {
      // Lock immediately on every return.
      state = state.copyWith(locked: true);
      return;
    }
    final elapsed = DateTime.now().difference(stamp);
    if (elapsed >= Duration(minutes: autoLockMinutes)) {
      state = state.copyWith(locked: true);
    }
  }

  /// Prompt the user with the system biometric dialog. Returns true
  /// when authentication succeeds and the lock is released.
  Future<bool> authenticate(String reason) async {
    if (!state.config.biometricEnabled) {
      state = state.copyWith(locked: false);
      return true;
    }
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          // biometricOnly: false → device PIN / pattern works as a
          // fallback when biometrics aren't enrolled or temporarily
          // unavailable (e.g. fingerprint sensor disabled).
          biometricOnly: false,
        ),
      );
      if (ok) {
        state = state.copyWith(locked: false);
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
}

final lockProvider = StateNotifierProvider<LockNotifier, LockState>((ref) {
  return LockNotifier(ref.watch(secureStorageProvider));
});
