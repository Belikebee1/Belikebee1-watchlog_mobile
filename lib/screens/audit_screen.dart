import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/audit_entry.dart';
import '../providers/audit_provider.dart';
import '../theme.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton.dart';

/// Per-server timeline of audit events recorded by the backend.
/// Reachable from settings → server tile menu. Filterable by kind
/// prefix (Actions / Tokens / Pairing / All) — the chips at the top
/// switch the underlying provider family entry, so each filter
/// loads from cache after the first fetch.
class AuditScreen extends ConsumerStatefulWidget {
  final String serverId;
  const AuditScreen({super.key, required this.serverId});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  String? _kindPrefix; // null = all

  @override
  Widget build(BuildContext context) {
    final query = (serverId: widget.serverId, kind: _kindPrefix);
    final asyncEntries = ref.watch(auditProvider(query));
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, S.auditTitle))),
      body: Column(
        children: [
          _FilterBar(
            current: _kindPrefix,
            onChanged: (prefix) {
              setState(() => _kindPrefix = prefix);
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(auditProvider(query)),
              child: asyncEntries.when(
                loading: () => const _AuditSkeleton(),
                error: (e, _) => ErrorView.from(
                  e,
                  onRetry: () => ref.invalidate(auditProvider(query)),
                ),
                data: (entries) => entries.isEmpty
                    ? _Empty()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: entries.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 56),
                        itemBuilder: (ctx, i) =>
                            _AuditRow(entry: entries[i]),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onChanged;
  const _FilterBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final filters = [
      (null, tr(context, S.auditFilterAll)),
      ('ACTION_', tr(context, S.auditFilterActions)),
      ('TOKEN_', tr(context, S.auditFilterTokens)),
      ('PAIR_', tr(context, S.auditFilterPairing)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final f in filters) ...[
            ChoiceChip(
              label: Text(f.$2),
              selected: current == f.$1,
              onSelected: (_) => onChanged(f.$1),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final AuditEntry entry;
  const _AuditRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final fail = entry.isFailure;
    final color = fail ? AppColors.red : AppColors.accent;
    final icon = fail ? Icons.error_outline : _iconForEvent(entry.event);
    final title = _friendlyTitle(context, entry);
    final subtitle = _subtitleFor(context, entry);
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.surfaces.fgMuted, fontSize: 12),
      ),
      trailing: Text(
        _formatTime(entry.ts.toLocal()),
        style: TextStyle(
          color: context.surfaces.fgMuted,
          fontSize: 11,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  IconData _iconForEvent(String e) {
    if (e.startsWith('ACTION_RESTART')) return Icons.restart_alt;
    if (e.startsWith('ACTION_REBOOT')) return Icons.power_settings_new;
    if (e.startsWith('ACTION_TAIL_LOGS')) return Icons.notes_outlined;
    if (e == 'ACTION_APPLY_SECURITY') return Icons.shield_outlined;
    if (e.startsWith('PAIR_REDEEMED')) return Icons.qr_code_2;
    if (e.startsWith('PAIR_GENERATED')) return Icons.qr_code;
    if (e.startsWith('TOKEN_ISSUED')) return Icons.add_moderator_outlined;
    if (e.startsWith('TOKEN_REVOKED')) return Icons.remove_moderator_outlined;
    if (e == 'TOKEN_PREFS_UPDATED') return Icons.tune;
    return Icons.history;
  }

  String _friendlyTitle(BuildContext context, AuditEntry e) {
    final extra = e.extra;
    switch (e.event) {
      case 'ACTION_RESTART_SERVICE':
        return tr(context, S.evtActionRestartService,
            subs: {'service': '${extra['service'] ?? '?'}'});
      case 'ACTION_RESTART_DENIED':
        return tr(context, S.evtActionRestartDenied,
            subs: {'service': '${extra['service'] ?? '?'}'});
      case 'ACTION_REBOOT':
        return tr(context, S.evtActionReboot);
      case 'ACTION_REBOOT_DENIED':
        return tr(context, S.evtActionRebootDenied);
      case 'ACTION_APPLY_SECURITY':
        return tr(context, S.evtActionApplySecurity);
      case 'ACTION_TAIL_LOGS':
        return tr(context, S.evtActionTailLogs,
            subs: {'service': '${extra['service'] ?? '?'}'});
      case 'ACTION_LOGS_DENIED':
        return tr(context, S.evtActionLogsDenied,
            subs: {'service': '${extra['service'] ?? '?'}'});
      case 'TOKEN_ISSUED':
        return tr(context, S.evtTokenIssued,
            subs: {'device': '${extra['device_label'] ?? '?'}'});
      case 'TOKEN_REVOKED':
        return tr(context, S.evtTokenRevoked);
      case 'TOKEN_AUTH_FAILED':
        return tr(context, S.evtTokenAuthFailed);
      case 'TOKEN_FORBIDDEN':
        return tr(context, S.evtTokenForbidden);
      case 'TOKEN_PREFS_UPDATED':
        return tr(context, S.evtTokenPrefsUpdated);
      case 'PAIR_GENERATED':
        return tr(context, S.evtPairGenerated);
      case 'PAIR_REDEEMED':
        return tr(context, S.evtPairRedeemed);
      case 'PAIR_FAILED':
        return tr(context, S.evtPairFailed,
            subs: {'reason': '${extra['reason'] ?? '?'}'});
      case 'PAIR_LOCKED_OUT':
        return tr(context, S.evtPairLockedOut);
      default:
        return e.event;
    }
  }

  String _subtitleFor(BuildContext context, AuditEntry e) {
    final parts = <String>[];
    final ip = e.extra['ip'];
    final reason = e.extra['reason'];
    if (ip is String && ip.isNotEmpty) parts.add('IP $ip');
    if (reason is String && reason.isNotEmpty && !e.isFailure) {
      parts.add(reason);
    }
    if (parts.isEmpty) {
      final code = e.extra['code'];
      if (code is String) parts.add('code=$code');
    }
    return parts.join(' · ');
  }

  String _formatTime(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$y-$m-$d\n$hh:$mm';
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Center(
          child: Icon(Icons.history,
              size: 56, color: context.surfaces.fgMuted),
        ),
        const SizedBox(height: 16),
        Text(
          tr(context, S.auditEmpty),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.surfaces.fg,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr(context, S.auditEmptyHint),
          textAlign: TextAlign.center,
          style: TextStyle(color: context.surfaces.fgMuted),
        ),
      ],
    );
  }
}

class _AuditSkeleton extends StatelessWidget {
  const _AuditSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 4),
        children: [
          for (var i = 0; i < 10; i++)
            const ListTile(
              leading: Skeleton.circle(size: 22),
              title: Skeleton(width: 200, height: 14),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 6),
                child: Skeleton(width: 140, height: 11),
              ),
              trailing: SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Skeleton(width: 60, height: 10),
                    SizedBox(height: 4),
                    Skeleton(width: 40, height: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
