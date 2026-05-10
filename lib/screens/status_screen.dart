import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../providers/host_info_provider.dart';
import '../providers/status_provider.dart';
import '../theme.dart';
import '../utils/error_humanizer.dart';
import '../widgets/check_explainer_sheet.dart';
import '../widgets/check_row.dart';
import '../widgets/error_view.dart';
import '../widgets/live_metrics_tile.dart';
import '../widgets/server_header.dart';
import '../widgets/severity_banner.dart';
import '../widgets/severity_legend_sheet.dart';
import '../widgets/skeleton.dart';
import 'history_screen.dart';
import 'output_screen.dart';
import 'settings_screen.dart';

/// Per-server detail screen: full check list, action buttons, and the
/// snooze/ignore actions. Pushed from [OverviewScreen] when the user taps
/// a server card. The server is identified explicitly by [serverId] so
/// this screen renders the right host even if the user changes the
/// "active" server elsewhere mid-session.
class StatusScreen extends ConsumerStatefulWidget {
  final String serverId;
  const StatusScreen({super.key, required this.serverId});
  @override
  ConsumerState<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends ConsumerState<StatusScreen> {
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    _autoRefresh = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(serverStatusProvider(widget.serverId));
    // Host info is largely static, but pull-to-refresh is the user's
    // explicit "refresh everything" gesture — re-fetch in case the box
    // rebooted or its IPs changed.
    ref.invalidate(hostInfoProvider(widget.serverId));
  }

  Future<void> _runWatchlog() async {
    final api = ref.read(serverApiProvider(widget.serverId));
    if (api == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
        SnackBar(content: Text(tr(context, S.runningWatchlog))));
    try {
      final result = await api.runWatchlog();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => OutputScreen(
              title: tr(ctx, S.watchlogRunTitle), result: result),
        ),
      );
      _refresh();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(shortMessage(context, e))));
    }
  }

  Future<void> _applySecurity() async {
    final api = ref.read(serverApiProvider(widget.serverId));
    if (api == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaces.bgElevated,
        title: Text(tr(ctx, S.applySecurityConfirmTitle)),
        content: Text(tr(ctx, S.applySecurityConfirmBody)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(tr(ctx, S.cancel))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr(ctx, S.applySecurityCta))),
        ],
      ),
    );
    if (confirm != true) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
        SnackBar(content: Text(tr(context, S.applyingSecurity))));
    try {
      final result = await api.applySecurityUpdates();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => OutputScreen(
              title: tr(ctx, S.applySecurityTitle), result: result),
        ),
      );
      _refresh();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(shortMessage(context, e))));
    }
  }

  Future<void> _onSnooze(String check) async {
    final api = ref.read(serverApiProvider(widget.serverId));
    if (api == null) return;
    try {
      await api.snooze(check, 4);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr(context, S.snackSnoozed, subs: {'check': check}))),
      );
      _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shortMessage(context, e))),
      );
    }
  }

  Future<void> _onIgnore(String check) async {
    final api = ref.read(serverApiProvider(widget.serverId));
    if (api == null) return;
    try {
      await api.ignore(check);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr(context, S.snackIgnored, subs: {'check': check}))),
      );
      _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shortMessage(context, e))),
      );
    }
  }

  Future<void> _onClear(String check) async {
    final api = ref.read(serverApiProvider(widget.serverId));
    if (api == null) return;
    try {
      await api.unsnooze(check);
      await api.unignore(check);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(tr(context, S.snackCleared, subs: {'check': check}))),
      );
      _refresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final asyncCombined = ref.watch(serverStatusProvider(widget.serverId));
    final server = ref.watch(serverByIdProvider(widget.serverId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          server?.name ?? 'watchlog',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: tr(context, S.historyTooltip),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoryScreen(serverId: widget.serverId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: asyncCombined.when(
          loading: () => const _StatusSkeleton(),
          error: (e, _) => ErrorView.from(
            e,
            onRetry: _refresh,
            onSecondaryAction:
                humanize(context, e).action == HumanErrorAction.rePair
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        )
                    : null,
            secondaryActionLabel:
                humanize(context, e).action == HumanErrorAction.rePair
                    ? tr(context, S.openSettings)
                    : null,
          ),
          data: (combined) =>
              _buildContent(combined.status, combined.state),
        ),
      ),
    );
  }

  Widget _buildContent(Status? status, StateData? state) {
    final actionable = status?.actionable ?? [];
    final snoozes = state?.snoozes ?? {};
    final ignores = state?.ignores ?? {};

    final rows = <CheckRowData>[];
    final seen = <String>{};
    for (final a in actionable) {
      seen.add(a.check);
      var kind = SilencedKind.none;
      if (snoozes.containsKey(a.check)) kind = SilencedKind.snoozed;
      if (ignores.containsKey(a.check)) kind = SilencedKind.ignored;
      rows.add(CheckRowData(
        check: a.check,
        severity: a.severity,
        title: a.title,
        silenced: kind,
      ));
    }
    for (final entry in snoozes.entries) {
      if (seen.contains(entry.key)) continue;
      seen.add(entry.key);
      rows.add(CheckRowData(
        check: entry.key,
        severity: 'INFO',
        title: tr(context, S.snoozedRow),
        silenced: SilencedKind.snoozed,
      ));
    }
    for (final entry in ignores.entries) {
      if (seen.contains(entry.key)) continue;
      rows.add(CheckRowData(
        check: entry.key,
        severity: 'INFO',
        title: tr(context, S.ignoredRow),
        silenced: SilencedKind.ignored,
      ));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ServerHeader(serverId: widget.serverId),
        const SizedBox(height: 12),
        if (status != null) ...[
          LiveMetricsTile(status: status),
          const SizedBox(height: 12),
        ],
        SeverityBanner(status: status, onRefresh: _refresh),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _applySecurity,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(tr(context, S.applySecurityBtn)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _runWatchlog,
                icon: const Icon(Icons.refresh),
                label: Text(tr(context, S.runNowBtn)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.surfaces.border),
                  foregroundColor: context.surfaces.fg,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (status != null) _countsRow(status),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('✅', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(tr(context, S.allChecksPassing),
                      style: TextStyle(color: context.surfaces.fg)),
                  const SizedBox(height: 4),
                  Text(tr(context, S.nothingToActOn),
                      style: TextStyle(color: context.surfaces.fgMuted)),
                ],
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: context.surfaces.border),
                  CheckRow(
                    data: rows[i],
                    onSnooze: () => _onSnooze(rows[i].check),
                    onIgnore: () => _onIgnore(rows[i].check),
                    onClear: () => _onClear(rows[i].check),
                    onTap: () => CheckExplainerSheet.show(
                      context,
                      serverId: widget.serverId,
                      data: rows[i],
                      onSnooze: () => _onSnooze(rows[i].check),
                      onIgnore: () => _onIgnore(rows[i].check),
                      onClear: () => _onClear(rows[i].check),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _countsRow(Status s) {
    final c = s.counts;
    return InkWell(
      onTap: () => SeverityLegendSheet.show(context, serverId: widget.serverId),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Expanded(child: _countChip('OK', c['OK'] ?? 0, AppColors.green)),
          Expanded(child: _countChip('INFO', c['INFO'] ?? 0, AppColors.accent)),
          Expanded(child: _countChip('WARN', c['WARN'] ?? 0, AppColors.yellow)),
          Expanded(
              child:
                  _countChip('CRITICAL', c['CRITICAL'] ?? 0, AppColors.red)),
        ],
      ),
    );
  }

  Widget _countChip(String label, int count, Color color) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text('$count',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
              Text(label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                  )),
            ],
          ),
        ),
      );
}

/// Loading-state stand-in for the status screen. Mirrors the layout of
/// the real content (server header strip → severity banner → action
/// buttons → counts strip → check rows) so the page doesn't reflow when
/// data arrives.
class _StatusSkeleton extends StatelessWidget {
  const _StatusSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server header strip skeleton
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.surfaces.bgElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.surfaces.border),
            ),
            child: Row(
              children: [
                Icon(Icons.dns_outlined,
                    size: 18, color: context.surfaces.fgMuted),
                const SizedBox(width: 8),
                const Skeleton(width: 100, height: 12),
                const SizedBox(width: 12),
                const Skeleton(width: 80, height: 12),
                const SizedBox(width: 12),
                const Skeleton(width: 60, height: 12),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Severity banner skeleton — mimics the real banner's height
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: context.surfaces.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.surfaces.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Skeleton(width: 80, height: 16),
                SizedBox(height: 8),
                Skeleton(width: 200, height: 12),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: Skeleton(height: 44, radius: 8)),
              SizedBox(width: 8),
              Expanded(child: Skeleton(height: 44, radius: 8)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: Skeleton(height: 50, radius: 8)),
              SizedBox(width: 8),
              Expanded(child: Skeleton(height: 50, radius: 8)),
              SizedBox(width: 8),
              Expanded(child: Skeleton(height: 50, radius: 8)),
              SizedBox(width: 8),
              Expanded(child: Skeleton(height: 50, radius: 8)),
            ],
          ),
          const SizedBox(height: 16),
          // A few check-row placeholders
          for (var i = 0; i < 4; i++) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: context.surfaces.bgElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.surfaces.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Skeleton.circle(size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Skeleton(width: 100, height: 14),
                        SizedBox(height: 6),
                        Skeleton(width: double.infinity, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

