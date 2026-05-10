import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import 'auth_provider.dart';

/// Aggregate of /api/v1/status + /api/v1/state for one server.
/// Either field may be null on partial failures (e.g. heartbeat present
/// but state endpoint timed out) — the UI still renders sensibly.
class CombinedState {
  final Status? status;
  final StateData? state;
  CombinedState({this.status, this.state});
}

/// Status + snooze/ignore for the *active* server. Kept as a thin alias
/// over [serverStatusProvider] so existing call sites keep working.
final statusProvider = FutureProvider<CombinedState>((ref) async {
  final servers = ref.watch(serversProvider).servers;
  final activeId = ref.watch(serversProvider).activeId;
  String? id = activeId;
  if (id == null && servers.isNotEmpty) id = servers.first.id;
  if (id == null) return CombinedState();
  return await ref.watch(serverStatusProvider(id).future);
});

/// Status + snooze/ignore for a specific server, identified by its id in
/// the [serversProvider] registry. Cards on the overview screen each watch
/// their own instance of this family so they refresh independently and
/// failures isolate per-server.
final serverStatusProvider =
    FutureProvider.family<CombinedState, String>((ref, serverId) async {
  final api = ref.watch(serverApiProvider(serverId));
  if (api == null) return CombinedState();
  // Run both calls in parallel — `state` is small and almost always
  // available, but `status` may 503 if the host hasn't run watchlog yet.
  final results = await Future.wait([
    api.getStatus().catchError((_) => null as Status?),
    api.getState().catchError((_) => null as StateData?),
  ]);
  return CombinedState(
    status: results[0] as Status?,
    state: results[1] as StateData?,
  );
});
