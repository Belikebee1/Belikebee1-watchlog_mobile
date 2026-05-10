import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/report.dart';
import '../providers/reports_provider.dart';
import '../theme.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton.dart';
import 'day_detail_screen.dart';

/// Calendar-ish list of past run archives for one server. Each row is
/// a single day, colored by the worst severity of any check during
/// that day's runs. Tap → drill into [DayDetailScreen] which lists
/// every individual run + every check at that point in time.
///
/// Reachable from the status screen app bar. No timer / pull-to-poll
/// — history is immutable once a day is closed, so a single fetch on
/// entry is enough; the user can pull-to-refresh to recheck the latest
/// day.
class HistoryScreen extends ConsumerWidget {
  final String serverId;
  const HistoryScreen({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(reportsListProvider(serverId));
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, S.historyTitle))),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reportsListProvider(serverId)),
        child: asyncList.when(
          loading: () => const _HistorySkeleton(),
          error: (e, _) => ErrorView.from(
            e,
            onRetry: () => ref.invalidate(reportsListProvider(serverId)),
          ),
          data: (summaries) => summaries.isEmpty
              ? _EmptyHistory()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: summaries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 1),
                  itemBuilder: (ctx, i) =>
                      _DayTile(serverId: serverId, summary: summaries[i]),
                ),
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final String serverId;
  final ReportSummary summary;
  const _DayTile({required this.serverId, required this.summary});

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(summary.worstSeverity);
    final emoji = _severityEmoji(summary.worstSeverity);
    final runsLabel = summary.runs == 1
        ? tr(context, S.runsCountSingular, subs: {'n': '1'})
        : tr(context, S.runsCount, subs: {'n': '${summary.runs}'});
    return ListTile(
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      title: Text(
        summary.date,
        style: TextStyle(
          color: context.surfaces.fg,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
      subtitle: Text(
        '$emoji ${summary.worstSeverity}  ·  $runsLabel',
        style: TextStyle(
          color: context.surfaces.fgMuted,
          fontSize: 13,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: context.surfaces.fgMuted),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DayDetailScreen(
            serverId: serverId,
            date: summary.date,
          ),
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Icon(
            Icons.calendar_today_outlined,
            size: 56,
            color: context.surfaces.fgMuted,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          tr(context, S.noHistory),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.surfaces.fg,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr(context, S.noHistoryHint),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.surfaces.fgMuted),
        ),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (var i = 0; i < 8; i++)
            ListTile(
              leading: const Skeleton.circle(size: 12),
              title: const Skeleton(width: 120, height: 14),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Skeleton(width: 180, height: 11),
              ),
            ),
        ],
      ),
    );
  }
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
