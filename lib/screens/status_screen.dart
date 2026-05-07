import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../providers/auth_provider.dart';
import '../providers/status_provider.dart';
import '../theme.dart';
import '../widgets/check_row.dart';
import '../widgets/severity_banner.dart';
import 'add_server_screen.dart';
import 'output_screen.dart';
import 'settings_screen.dart';

class StatusScreen extends ConsumerStatefulWidget {
  const StatusScreen({super.key});
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
    ref.invalidate(statusProvider);
  }

  Future<void> _runWatchlog() async {
    final api = ref.read(apiProvider);
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
    final api = ref.read(apiProvider);
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
    final api = ref.read(apiProvider);
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
    final api = ref.read(apiProvider);
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
    final api = ref.read(apiProvider);
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
    final asyncCombined = ref.watch(statusProvider);
    final servers = ref.watch(serversProvider);
    final active = servers.active;

    return Scaffold(
      appBar: AppBar(
        title: _ServerSwitcher(
          servers: servers.servers.map((s) => (id: s.id, name: s.name)).toList(),
          activeId: active?.id,
          activeName: active?.name ?? 'watchlog',
          onSelect: (id) async {
            await ref.read(serversProvider.notifier).setActive(id);
            ref.invalidate(statusProvider);
          },
          onAdd: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddServerScreen()),
            );
            ref.invalidate(statusProvider);
          },
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
    return Row(
      children: [
        Expanded(child: _countChip('OK', c['OK'] ?? 0, AppColors.green)),
        Expanded(child: _countChip('INFO', c['INFO'] ?? 0, AppColors.accent)),
        Expanded(child: _countChip('WARN', c['WARN'] ?? 0, AppColors.yellow)),
        Expanded(
            child:
                _countChip('CRITICAL', c['CRITICAL'] ?? 0, AppColors.red)),
      ],
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

/// App-bar title that doubles as a server picker. Tap → menu listing every
/// configured server plus "Add server…". A single-server install renders as
/// a plain title (no menu).
class _ServerSwitcher extends StatelessWidget {
  final List<({String id, String name})> servers;
  final String? activeId;
  final String activeName;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;

  const _ServerSwitcher({
    required this.servers,
    required this.activeId,
    required this.activeName,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultiple = servers.length > 1;
    return PopupMenuButton<String>(
      tooltip: 'Switch server',
      onSelected: (value) {
        if (value == '__add__') {
          onAdd();
        } else {
          onSelect(value);
        }
      },
      itemBuilder: (ctx) => [
        for (final s in servers)
          PopupMenuItem<String>(
            value: s.id,
            child: Row(
              children: [
                Icon(
                  s.id == activeId
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: s.id == activeId
                      ? AppColors.accent
                      : AppColors.fgMuted,
                ),
                const SizedBox(width: 12),
                Text(s.name),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: '__add__',
          child: Row(
            children: [
              Icon(Icons.add, size: 18, color: AppColors.fgMuted),
              SizedBox(width: 12),
              Text('Add server…'),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('👁️  ', style: TextStyle(fontSize: 18)),
          Flexible(
            child: Text(
              activeName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (hasMultiple)
            const Icon(Icons.arrow_drop_down, color: AppColors.fgMuted),
        ],
      ),
    );
  }
}
