import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/audit_entry.dart';
import 'auth_provider.dart';

/// Composite key for the audit family: (server + optional kind prefix).
/// Different kinds for the same server are cached separately so a user
/// can flip 'all events' ↔ 'actions only' without re-fetching the
/// originally-loaded set.
typedef AuditQuery = ({String serverId, String? kind});

final auditProvider =
    FutureProvider.family<List<AuditEntry>, AuditQuery>((ref, q) async {
  final api = ref.watch(serverApiProvider(q.serverId));
  if (api == null) return [];
  final raw = await api.fetchAudit(limit: 200, kind: q.kind);
  return raw
      .map((e) => AuditEntry.fromJson(e as Map<String, dynamic>))
      .toList();
});
