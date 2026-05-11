import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_provider.dart' show secureStorageProvider;

/// Tracks whether the user has finished (or skipped) the first-run
/// onboarding tutorial. Three states:
///
///   * null  — never asked; show onboarding next time main routes.
///   * true  — finished or skipped; never show again unless replayed
///             from Settings.
///   * false — same as null in routing semantics, kept distinct for
///             future "show me again on next launch" flows.
class OnboardingNotifier extends StateNotifier<bool?> {
  static const _kKey = 'watchlog_onboarding_done_v1';
  final FlutterSecureStorage _storage;

  OnboardingNotifier(this._storage) : super(null);

  Future<void> load() async {
    final raw = await _storage.read(key: _kKey);
    state = raw == 'true' ? true : null;
  }

  Future<void> markDone() async {
    state = true;
    await _storage.write(key: _kKey, value: 'true');
  }

  /// Replay from Settings — drops the persisted flag so the next app
  /// route decision lands on OnboardingScreen again.
  Future<void> reset() async {
    state = null;
    await _storage.delete(key: _kKey);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool?>((ref) {
  return OnboardingNotifier(ref.watch(secureStorageProvider));
});
