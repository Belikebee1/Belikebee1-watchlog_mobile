import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/host_info.dart';
import 'auth_provider.dart';

/// Fetches /api/v1/host for a specific server. Host info is static-ish
/// (hostname, OS release, RAM total) so we don't auto-refresh it on a
/// timer — it only changes on reboot or VM resize. The status_screen
/// invalidates this provider on its own pull-to-refresh, which is when
/// any of these fields could plausibly differ.
///
/// Returns null on any failure rather than propagating — the server
/// detail header just collapses to a one-line title in that case, and
/// the rest of the screen (checks, actions) keeps working.
final hostInfoProvider =
    FutureProvider.family<HostInfo?, String>((ref, serverId) async {
  final api = ref.watch(serverApiProvider(serverId));
  if (api == null) return null;
  try {
    final raw = await api.fetchHostInfo();
    return HostInfo.fromJson(raw);
  } catch (_) {
    return null;
  }
});
