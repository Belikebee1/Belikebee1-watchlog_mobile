import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';
import 'auth_provider.dart';

/// Last ~90 days of run summaries for a specific server. The backend
/// computes worst severity per day so each mobile entry colors itself
/// without further requests.
final reportsListProvider =
    FutureProvider.family<List<ReportSummary>, String>((ref, serverId) async {
  final api = ref.watch(serverApiProvider(serverId));
  if (api == null) return [];
  final raw = await api.listReports();
  final summaries = (raw['summaries'] as List?) ?? [];
  return summaries
      .map((e) => ReportSummary.fromJson(e as Map<String, dynamic>))
      .toList();
});

/// Detail for one specific day. Composite key = (serverId, date) so
/// multi-server browsing keeps each day's data isolated and cache-able.
typedef DayKey = ({String serverId, String date});

final reportDayProvider =
    FutureProvider.family<List<ReportRun>, DayKey>((ref, key) async {
  final api = ref.watch(serverApiProvider(key.serverId));
  if (api == null) return [];
  final raw = await api.fetchReportForDay(key.date);
  return raw
      .map((e) => ReportRun.fromJson(e as Map<String, dynamic>))
      .toList();
});
