import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/check_info.dart';
import 'auth_provider.dart';

/// Fetches /api/v1/checks/info from the active server once per app
/// session. The returned [ChecksInfo] is static metadata generic across
/// deployments — caching it across server switches is safe (and
/// simplification-positive) because every watchlog instance returns the
/// same explainers for the same version.
///
/// Returns null when no server is configured yet (no auth, can't fetch).
final checksInfoProvider = FutureProvider<ChecksInfo?>((ref) async {
  final api = ref.watch(apiProvider);
  if (api == null) return null;
  try {
    final raw = await api.fetchChecksInfo();
    return ChecksInfo.fromJson(raw);
  } catch (_) {
    // Don't break the UI if the server is on an older watchlog without
    // the endpoint — the explainer sheet just won't have descriptions.
    return null;
  }
});
