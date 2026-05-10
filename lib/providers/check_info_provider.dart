import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/check_info.dart';
import 'auth_provider.dart';

/// Fetches /api/v1/checks/info from a specific server. The returned
/// [ChecksInfo] is static metadata generic across deployments — Riverpod's
/// auto-dispose keeps it alive while the screen is mounted, so each server
/// pays the round-trip cost at most once per app session.
///
/// Returns null on any failure (older server without the endpoint, network
/// error, malformed payload). The UI degrades gracefully: explainer sheets
/// then show only the title.
final checksInfoProvider =
    FutureProvider.family<ChecksInfo?, String>((ref, serverId) async {
  final api = ref.watch(serverApiProvider(serverId));
  if (api == null) return null;
  try {
    final raw = await api.fetchChecksInfo();
    return ChecksInfo.fromJson(raw);
  } catch (_) {
    return null;
  }
});
