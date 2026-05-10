import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/action_descriptor.dart';
import 'auth_provider.dart';

/// Per-server list of available action shortcuts. Empty when the
/// operator hasn't whitelisted anything in actions.allowed_services or
/// the backend predates Phase 2D.
final availableActionsProvider =
    FutureProvider.family<List<ActionDescriptor>, String>((ref, serverId) async {
  final api = ref.watch(serverApiProvider(serverId));
  if (api == null) return [];
  try {
    final raw = await api.listActions();
    return raw
        .map((e) => ActionDescriptor.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});
