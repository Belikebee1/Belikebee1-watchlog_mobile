import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../models/server.dart';
import '../providers/auth_provider.dart';
import '../providers/status_provider.dart';
import '../theme.dart';
import 'add_server_screen.dart';
import 'settings_screen.dart';
import 'status_screen.dart';

/// Home screen: a list-of-servers overview where each card summarizes one
/// watchlog deployment. Tap a card to drill into its [StatusScreen].
///
/// Why this exists: with the multi-server refactor users routinely watch
/// 2+ servers. Forcing them to switch the "active" server every time they
/// want to glance at another one is friction; the overview lets them see
/// the worst-of state across all hosts in one screen.
///
/// Each card runs its own [serverStatusProvider] family instance, so a
/// network failure on one host doesn't blank the whole list — that host's
/// card just renders an error chip.
class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  Timer? _autoRefresh;

  @override
  void initState() {
    super.initState();
    // Periodic refresh — same cadence as the per-server status screen so
    // both views feel synchronized when navigating between them.
    _autoRefresh = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _refreshAll(),
    );
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }

  void _refreshAll() {
    final servers = ref.read(serversProvider).servers;
    for (final s in servers) {
      ref.invalidate(serverStatusProvider(s.id));
    }
  }

  Future<void> _onAddServer() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddServerScreen()),
    );
    if (mounted) _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    final servers = ref.watch(serversProvider).servers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('👁️  watchlog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: servers.isEmpty
            ? _EmptyServers(onAdd: _onAddServer)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: servers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) => _ServerCard(server: servers[i]),
              ),
      ),
      floatingActionButton: servers.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _onAddServer,
              icon: const Icon(Icons.add),
              label: const Text('Add server'),
            ),
    );
  }
}

class _EmptyServers extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyServers({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Center(child: Text('👁️', style: TextStyle(fontSize: 64))),
        const SizedBox(height: 16),
        const Text(
          'No servers yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.fg,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Pair your first watchlog server to see its health here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.fgMuted),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Pair server'),
          ),
        ),
      ],
    );
  }
}

/// Single-server card on the overview. Watches its own provider family
/// instance so its loading / error / data state is independent of others.
class _ServerCard extends ConsumerWidget {
  final Server server;
  const _ServerCard({required this.server});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSnapshot = ref.watch(serverStatusProvider(server.id));

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatusScreen(serverId: server.id),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: asyncSnapshot.when(
          loading: () => _CardLoading(server: server),
          error: (e, _) => _CardError(server: server, error: e),
          data: (combined) => _CardLoaded(
            server: server,
            status: combined.status,
            state: combined.state,
          ),
        ),
      ),
    );
  }
}

class _CardLoading extends StatelessWidget {
  final Server server;
  const _CardLoading({required this.server});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(server.name,
                  style: const TextStyle(
                    color: AppColors.fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
              const SizedBox(height: 2),
              const Text('Loading…',
                  style: TextStyle(color: AppColors.fgMuted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardError extends StatelessWidget {
  final Server server;
  final Object error;
  const _CardError({required this.server, required this.error});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.error_outline, color: AppColors.red, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(server.name,
                  style: const TextStyle(
                    color: AppColors.fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  )),
              const SizedBox(height: 2),
              Text(
                _humanizeError(error),
                style: const TextStyle(color: AppColors.red, fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                server.baseUrl,
                style: const TextStyle(color: AppColors.fgMuted, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardLoaded extends StatelessWidget {
  final Server server;
  final Status? status;
  final StateData? state;

  const _CardLoaded({
    required this.server,
    required this.status,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final worst = status?.worstSeverity ?? 'OK';
    final color = _severityColor(worst);
    final counts = status?.counts ?? const <String, int>{};
    final actionable = (status?.actionable ?? const <Actionable>[]).length;
    final age = status?.age;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 4),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(server.name,
                      style: const TextStyle(
                        color: AppColors.fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    _summaryLine(worst, actionable),
                    style: TextStyle(color: color, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (age != null)
              Text(
                _ageString(age),
                style: const TextStyle(
                    color: AppColors.fgMuted, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _CountsStrip(counts: counts),
      ],
    );
  }

  String _summaryLine(String severity, int actionable) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return 'CRITICAL · $actionable to fix';
      case 'WARN':
        return 'WARN · $actionable to look at';
      case 'INFO':
        return 'INFO · $actionable advisory';
      default:
        return 'All checks passing';
    }
  }

  String _ageString(Duration age) {
    if (age.inMinutes < 1) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }
}

class _CountsStrip extends StatelessWidget {
  final Map<String, int> counts;
  const _CountsStrip({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip('OK', counts['OK'] ?? 0, AppColors.green),
        const SizedBox(width: 6),
        _chip('INFO', counts['INFO'] ?? 0, AppColors.accent),
        const SizedBox(width: 6),
        _chip('WARN', counts['WARN'] ?? 0, AppColors.yellow),
        const SizedBox(width: 6),
        _chip('CRIT', counts['CRITICAL'] ?? 0, AppColors.red),
      ],
    );
  }

  Widget _chip(String label, int count, Color color) {
    final dim = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: dim ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: dim
              ? AppColors.border
              : color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              color: dim ? AppColors.fgMuted : color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: dim ? AppColors.fgMuted : color.withValues(alpha: 0.8),
              fontSize: 10,
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

String _humanizeError(Object error) {
  final text = error.toString();
  // Dio errors include a lot of stack-trace-like noise; trim aggressively.
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return 'Cannot reach server';
  }
  if (text.contains('401')) {
    return 'Token revoked or expired — re-pair from settings';
  }
  if (text.contains('429')) {
    return 'Too many requests';
  }
  if (text.contains('TimeoutException') || text.contains('timeout')) {
    return 'Request timed out';
  }
  // Last resort: show the first line only, bounded.
  final first = text.split('\n').first;
  return first.length > 80 ? '${first.substring(0, 80)}…' : first;
}
