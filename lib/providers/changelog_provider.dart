import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/changelog.dart';
import 'auth_provider.dart' show secureStorageProvider;

/// State for the "what's new" flow.
///
/// We store the highest version the user has acknowledged (closed the
/// modal for). On startup the bootstrap routine compares the *current*
/// build's version against this stored marker; if newer entries exist
/// in [kChangelog], the next call to [pendingForToast] returns the
/// list of unseen entries and the modal pops over the home route.
class ChangelogState {
  /// Hard-coded current version. Bumped at every release alongside the
  /// changelog entry above. We don't pull from pubspec.yaml at runtime
  /// to avoid a build-time codegen dependency for a one-line constant.
  static const currentVersion = '0.6.0';

  final String? lastSeenVersion;
  const ChangelogState(this.lastSeenVersion);

  /// Slice of [kChangelog] the user hasn't seen yet, newest first.
  /// Empty when nothing new — caller treats empty as "no modal".
  List<ChangelogEntry> pendingForToast() {
    if (lastSeenVersion == null) {
      // Brand-new install — onboarding handles the welcome, so we
      // don't ALSO pop a 'what's new' modal at the same time.
      return [];
    }
    if (lastSeenVersion == currentVersion) return [];
    final out = <ChangelogEntry>[];
    for (final e in kChangelog) {
      if (_compareVersions(e.version, lastSeenVersion!) > 0) {
        out.add(e);
      }
    }
    return out;
  }
}

class ChangelogNotifier extends StateNotifier<ChangelogState> {
  static const _kKey = 'watchlog_changelog_last_seen_v1';
  final FlutterSecureStorage _storage;

  ChangelogNotifier(this._storage) : super(const ChangelogState(null));

  Future<void> load() async {
    final raw = await _storage.read(key: _kKey);
    state = ChangelogState(raw);
  }

  /// Stamp the current build's version as seen — call after the user
  /// dismisses the modal so it doesn't re-pop on every launch.
  Future<void> markSeen() async {
    state = const ChangelogState(ChangelogState.currentVersion);
    await _storage.write(
      key: _kKey,
      value: ChangelogState.currentVersion,
    );
  }
}

final changelogProvider =
    StateNotifierProvider<ChangelogNotifier, ChangelogState>((ref) {
  return ChangelogNotifier(ref.watch(secureStorageProvider));
});

/// Compare two semver-like dotted strings — only first three numeric
/// components matter. Non-numeric segments compare as 0 so a
/// pre-release suffix doesn't break the comparison.
int _compareVersions(String a, String b) {
  final pa = a.split('.').map(int.tryParse).map((v) => v ?? 0).toList();
  final pb = b.split('.').map(int.tryParse).map((v) => v ?? 0).toList();
  final len = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < len; i++) {
    final ai = i < pa.length ? pa[i] : 0;
    final bi = i < pb.length ? pb[i] : 0;
    if (ai != bi) return ai - bi;
  }
  return 0;
}
