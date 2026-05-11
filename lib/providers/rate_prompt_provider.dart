import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_review/in_app_review.dart';

import 'auth_provider.dart' show secureStorageProvider;

/// Tracks usage signals + asks for a Play Store rating once the user
/// has stuck around long enough to have an informed opinion.
///
/// Triggering conditions (all must be true):
///   * first launch was ≥ 7 days ago,
///   * user has performed ≥ 3 meaningful actions (snooze, apply,
///     restart, run-now),
///   * we haven't already prompted in this install OR last prompt
///     was ≥ 90 days ago.
///
/// All counts live in flutter_secure_storage (one key, JSON blob)
/// so they survive app upgrades without touching the OS keychain.
/// The actual sheet comes from `in_app_review` — Play Store's native
/// 1-tap dialog, no leaving the app.
class RatePromptState {
  final DateTime? firstLaunchAt;
  final int actionCount;
  final DateTime? lastPromptAt;

  const RatePromptState({
    required this.firstLaunchAt,
    required this.actionCount,
    required this.lastPromptAt,
  });

  static const empty =
      RatePromptState(firstLaunchAt: null, actionCount: 0, lastPromptAt: null);
}

class RatePromptNotifier extends StateNotifier<RatePromptState> {
  static const _kFirst = 'watchlog_rate_first_launch_v1';
  static const _kCount = 'watchlog_rate_actions_v1';
  static const _kLast = 'watchlog_rate_last_prompt_v1';

  final FlutterSecureStorage _storage;

  RatePromptNotifier(this._storage) : super(RatePromptState.empty);

  Future<void> load() async {
    final first = await _storage.read(key: _kFirst);
    final count = await _storage.read(key: _kCount);
    final last = await _storage.read(key: _kLast);
    final firstAt = first != null ? DateTime.tryParse(first) : null;
    final lastAt = last != null ? DateTime.tryParse(last) : null;
    state = RatePromptState(
      firstLaunchAt: firstAt ?? DateTime.now(),
      actionCount: int.tryParse(count ?? '') ?? 0,
      lastPromptAt: lastAt,
    );
    if (firstAt == null) {
      // Stamp first-launch the first time we ever load. Lets the 7-day
      // threshold start ticking from the *real* first day, not whenever
      // the user happens to perform their first action.
      await _storage.write(
          key: _kFirst, value: state.firstLaunchAt!.toIso8601String());
    }
  }

  /// Caller bumps this whenever the user does something meaningful.
  /// Keeps the count cheap: just an int in secure storage.
  Future<void> recordAction() async {
    final next = state.actionCount + 1;
    state = RatePromptState(
      firstLaunchAt: state.firstLaunchAt,
      actionCount: next,
      lastPromptAt: state.lastPromptAt,
    );
    await _storage.write(key: _kCount, value: '$next');
  }

  /// Called from somewhere innocuous (status screen build) after an
  /// action — if conditions match, ask the OS to surface the in-app
  /// review sheet. We're OK with the OS silently dropping the request
  /// (Play Store rate-limits to a few per year per device).
  Future<void> maybePrompt() async {
    final first = state.firstLaunchAt;
    if (first == null) return;
    final age = DateTime.now().difference(first);
    if (age < const Duration(days: 7)) return;
    if (state.actionCount < 3) return;
    final last = state.lastPromptAt;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(days: 90)) {
      return;
    }

    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await review.requestReview();
      state = RatePromptState(
        firstLaunchAt: state.firstLaunchAt,
        actionCount: state.actionCount,
        lastPromptAt: DateTime.now(),
      );
      await _storage.write(
          key: _kLast, value: state.lastPromptAt!.toIso8601String());
    } catch (e) {
      debugPrint('In-app review failed: $e');
    }
  }
}

final ratePromptProvider =
    StateNotifierProvider<RatePromptNotifier, RatePromptState>((ref) {
  return RatePromptNotifier(ref.watch(secureStorageProvider));
});
