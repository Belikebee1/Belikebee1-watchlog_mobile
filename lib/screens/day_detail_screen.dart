import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../theme.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton.dart';

/// Shows every individual `watchlog run` recorded on a specific day,
/// each expandable to its full check list. Reachable from
/// [HistoryScreen] via tap on a day row.
///
/// Why expand-per-run instead of flattening: the same check can have
/// flipped severity multiple times in a day (e.g. INFO → WARN → OK),
/// and seeing the timeline of runs preserves that story. A flat
/// "worst per check that day" view loses it.
class DayDetailScreen extends ConsumerWidget {
  final String serverId;
  final String date;
  const DayDetailScreen({
    super.key,
    required this.serverId,
    required this.date,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (serverId: serverId, date: date);
    final asyncRuns = ref.watch(reportDayProvider(key));
    return Scaffold(
      appBar: AppBar(title: Text(date)),
      body: asyncRuns.when(
        loading: () => const _DaySkeleton(),
        error: (e, _) => ErrorView.from(
          e,
          onRetry: () => ref.invalidate(reportDayProvider(key)),
        ),
        data: (runs) {
          if (runs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr(context, S.noRunsForDay),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.surfaces.fgMuted),
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: runs.length,
            itemBuilder: (ctx, i) => _RunTile(
              run: runs[i],
              defaultExpanded: i == runs.length - 1,
            ),
          );
        },
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  final ReportRun run;
  final bool defaultExpanded;
  const _RunTile({required this.run, required this.defaultExpanded});

  @override
  Widget build(BuildContext context) {
    final worst = _worstSeverity(run.results);
    final color = _severityColor(worst);
    final emoji = _severityEmoji(worst);
    final timeStr = _formatTime(run.ranAt.toLocal());
    return Theme(
      // ExpansionTile uses divider color from theme — keep it subtle.
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        listTileTheme: ListTileTheme.of(context).copyWith(
          dense: true,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: defaultExpanded,
        leading: Text(emoji, style: const TextStyle(fontSize: 18)),
        title: Text(
          timeStr,
          style: TextStyle(
            color: context.surfaces.fg,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
          ),
        ),
        subtitle: Text(
          '$worst · ${run.results.length}',
          style: TextStyle(color: color, fontSize: 12),
        ),
        children: [
          for (final r in run.results) _CheckRow(check: r),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  final ReportCheck check;
  const _CheckRow({required this.check});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(check.severity);
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  check.check,
                  style: TextStyle(
                    color: color,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  check.title,
                  style: TextStyle(
                    color: context.surfaces.fg,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySkeleton extends StatelessWidget {
  const _DaySkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Skeleton(height: 56, radius: 8),
          SizedBox(height: 8),
          Skeleton(height: 56, radius: 8),
          SizedBox(height: 8),
          Skeleton(height: 56, radius: 8),
          SizedBox(height: 8),
          Skeleton(height: 200, radius: 8),
        ],
      ),
    );
  }
}

String _worstSeverity(List<ReportCheck> results) {
  if (results.isEmpty) return 'OK';
  const order = ['OK', 'INFO', 'WARN', 'CRITICAL'];
  var worst = 0;
  for (final r in results) {
    final idx = order.indexOf(r.severity.toUpperCase());
    if (idx > worst) worst = idx;
  }
  return order[worst];
}

Color _severityColor(String severity) {
  switch (severity.toUpperCase()) {
    case 'CRITICAL':
      return AppColors.red;
    case 'WARN':
      return AppColors.yellow;
    case 'INFO':
      return AppColors.accent;
    default:
      return AppColors.green;
  }
}

String _severityEmoji(String severity) {
  switch (severity.toUpperCase()) {
    case 'CRITICAL':
      return '🔴';
    case 'WARN':
      return '⚠️';
    case 'INFO':
      return 'ℹ️';
    default:
      return '✅';
  }
}

String _formatTime(DateTime t) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}
