import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../providers/auth_provider.dart';
import '../providers/status_provider.dart';
import '../theme.dart';
import '../providers/host_info_provider.dart';
import '../widgets/check_explainer_sheet.dart';
import '../widgets/check_row.dart';
import '../widgets/server_header.dart';
import '../widgets/severity_banner.dart';
import '../widgets/severity_legend_sheet.dart';
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
    messenger.showSnackBar(const SnackBar(content: Text('Running watchlog…')));
    try {
      final result = await api.runWatchlog();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OutputScreen(title: 'watchlog run', result: result),
        ),
      );
      _refresh();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _applySecurity() async {
    final api = ref.read(serverApiProvider(widget.serverId));
    if (api == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('Apply security updates?'),
        content: const Text(
          'This will run `unattended-upgrade -v` on the server. '
          'It may install patches and (rarely) require a service restart.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apply')),
        ],
      ),
    );
    if (confirm != true) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
        const SnackBar(content: Text('Applying security updates…')));
    try {
      final result = await api.applySecurityUpdates();
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OutputScreen(title: 'Apply security updates', result: result),
        ),
      );
      _refresh();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _onSnooze(String check) async {
    final api = ref.read(serverApiProvider(widget.serverId));
    if (api == null) return;
    try {
      await api.snooze(check, 4);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snoozed $check for 4h')),
      );
      _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
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
        SnackBar(content: Text('Ignored $check')),
      );
      _refresh();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
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
        SnackBar(content: Text('Cleared $check')),
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
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline,
                  color: AppColors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.fgMuted),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _refresh,
                  child: const Text('Retry'),
                ),
              ),
            ],
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
        title: '(snoozed)',
        silenced: SilencedKind.snoozed,
      ));
    }
    for (final entry in ignores.entries) {
      if (seen.contains(entry.key)) continue;
      rows.add(CheckRowData(
        check: entry.key,
        severity: 'INFO',
        title: '(ignored)',
        silenced: SilencedKind.ignored,
      ));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ServerHeader(serverId: widget.serverId),
        const SizedBox(height: 12),
        SeverityBanner(status: status, onRefresh: _refresh),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _applySecurity,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Apply security'),
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
                label: const Text('Run now'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.fg,
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
                children: const [
                  Text('✅', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text('All checks passing.',
                      style: TextStyle(color: AppColors.fg)),
                  SizedBox(height: 4),
                  Text('Nothing to act on.',
                      style: TextStyle(color: AppColors.fgMuted)),
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
                    const Divider(height: 1, color: AppColors.border),
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

