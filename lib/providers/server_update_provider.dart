import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/github_release.dart';
import 'auth_provider.dart';
import 'host_info_provider.dart';

/// Owner/repo for the watchlog backend on GitHub. Hard-coded because
/// there's only one canonical source — if it ever moves, we'll bump
/// the constant and ship a new mobile build.
const _kReleasesUrl =
    'https://api.github.com/repos/Belikebee1/watchlog/releases/latest';

/// Fetches the latest published (non-prerelease) GitHub release of the
/// watchlog backend. Returns null on any failure (offline, rate-limited,
/// repo private, etc.) — the banner stays hidden in that case rather
/// than nagging the user with a comparison-impossible state.
///
/// Riverpod caches the future for the lifetime of the app session.
/// A pull-to-refresh on the status screen does NOT invalidate this; the
/// banner is intentionally low-frequency and refreshing on every gesture
/// would burn through GitHub's 60-req/hr unauthenticated rate limit on
/// shared mobile networks.
final latestWatchlogReleaseProvider =
    FutureProvider<GithubRelease?>((ref) async {
  try {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 6),
      headers: {'Accept': 'application/vnd.github+json'},
    ));
    final resp = await dio.get<Map<String, dynamic>>(_kReleasesUrl);
    final data = resp.data;
    if (data == null) return null;
    return GithubRelease.fromJson(data);
  } catch (_) {
    return null;
  }
});

/// Outcome of comparing a server's installed version to the latest
/// GitHub release. The banner reads this and either renders a prompt
/// ([UpdateAvailability.updateAvailable]) or nothing.
enum UpdateAvailability {
  /// Server version is older than the latest GitHub release.
  updateAvailable,

  /// Server is on the latest version, or newer (dev install).
  upToDate,

  /// Not enough information — server pre-dates the `watchlog_version`
  /// field, or GitHub is unreachable. The UI hides the banner.
  unknown,
}

class ServerUpdateStatus {
  final UpdateAvailability availability;
  final String? installed;
  final GithubRelease? latest;

  const ServerUpdateStatus({
    required this.availability,
    this.installed,
    this.latest,
  });

  bool get hasUpdate => availability == UpdateAvailability.updateAvailable;
}

/// Compares the [installed] watchlog version (from the server's host
/// info) with the [latest] GitHub release tag. Returns a status the
/// banner can render directly.
///
/// Version strings are parsed as numeric SemVer (major.minor.patch).
/// Anything weird — empty strings, suffixes like "-dev", parse failures
/// — collapses to [UpdateAvailability.unknown] and the banner stays
/// hidden. We deliberately don't try to be clever about pre-release
/// tags here; the goal is "don't nag the user when in doubt."
ServerUpdateStatus computeUpdateStatus({
  required String? installed,
  required GithubRelease? latest,
}) {
  if (installed == null || installed.isEmpty || latest == null ||
      latest.version.isEmpty) {
    return ServerUpdateStatus(
      availability: UpdateAvailability.unknown,
      installed: installed,
      latest: latest,
    );
  }
  final a = _parseVersion(installed);
  final b = _parseVersion(latest.version);
  if (a == null || b == null) {
    return ServerUpdateStatus(
      availability: UpdateAvailability.unknown,
      installed: installed,
      latest: latest,
    );
  }
  final cmp = _compareSemver(a, b);
  return ServerUpdateStatus(
    availability: cmp < 0
        ? UpdateAvailability.updateAvailable
        : UpdateAvailability.upToDate,
    installed: installed,
    latest: latest,
  );
}

List<int>? _parseVersion(String s) {
  // Strip a leading "v" so "v0.5.1" and "0.5.1" parse the same.
  final trimmed = s.startsWith('v') ? s.substring(1) : s;
  // Drop anything after a "-" / "+" suffix ("0.6.0-dev", "0.6.0+local")
  // so we compare on the numeric core only.
  final core = trimmed.split(RegExp(r'[-+]')).first;
  final parts = core.split('.');
  if (parts.isEmpty) return null;
  final out = <int>[];
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null) return null;
    out.add(n);
  }
  while (out.length < 3) {
    out.add(0);
  }
  return out;
}

int _compareSemver(List<int> a, List<int> b) {
  final len = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < len; i++) {
    final av = i < a.length ? a[i] : 0;
    final bv = i < b.length ? b[i] : 0;
    if (av != bv) return av.compareTo(bv);
  }
  return 0;
}

/// Combined status for a specific server: looks up host info (for the
/// installed version) and the cached GitHub release, then computes the
/// availability flag. Returns `null` while either source is still
/// loading — the banner waits silently rather than flashing in.
final serverUpdateProvider =
    Provider.family<ServerUpdateStatus?, String>((ref, serverId) {
  final hostInfoAsync = ref.watch(hostInfoProvider(serverId));
  final latestAsync = ref.watch(latestWatchlogReleaseProvider);

  final host = hostInfoAsync.maybeWhen(data: (h) => h, orElse: () => null);
  final latest =
      latestAsync.maybeWhen(data: (r) => r, orElse: () => null);

  if (host == null) return null;
  return computeUpdateStatus(
    installed: host.watchlogVersion,
    latest: latest,
  );
});

/// Tracks which update version the user has already dismissed for a
/// given server. Persists in secure storage so the banner doesn't pop
/// back on every app launch. The key includes the server id so the
/// dismissal is scoped — dismissing v0.6.0 for server A doesn't hide
/// the banner for server B.
class UpdateDismissalNotifier
    extends StateNotifier<Map<String, String>> {
  static const _kKey = 'watchlog_update_dismissals_v1';
  final FlutterSecureStorage _storage;

  UpdateDismissalNotifier(this._storage) : super(const {}) {
    _load();
  }

  Future<void> _load() async {
    try {
      final raw = await _storage.read(key: _kKey);
      if (raw == null || raw.isEmpty) return;
      // Stored format: "serverId:version,serverId:version,..."
      // We avoid JSON here to keep the file tiny — the map is rarely
      // more than a handful of entries.
      final out = <String, String>{};
      for (final pair in raw.split(',')) {
        final i = pair.indexOf(':');
        if (i <= 0) continue;
        out[pair.substring(0, i)] = pair.substring(i + 1);
      }
      state = out;
    } catch (_) {/* corrupt blob — start fresh, dismissal is non-critical */}
  }

  Future<void> _save() async {
    final encoded =
        state.entries.map((e) => '${e.key}:${e.value}').join(',');
    await _storage.write(key: _kKey, value: encoded);
  }

  bool isDismissed(String serverId, String version) =>
      state[serverId] == version;

  Future<void> dismiss(String serverId, String version) async {
    state = {...state, serverId: version};
    await _save();
  }
}

final updateDismissalProvider =
    StateNotifierProvider<UpdateDismissalNotifier, Map<String, String>>((ref) {
  return UpdateDismissalNotifier(ref.watch(secureStorageProvider));
});
