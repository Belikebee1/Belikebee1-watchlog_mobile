import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/host_info.dart';
import '../providers/host_info_provider.dart';
import '../theme.dart';
import 'skeleton.dart';

/// Compact metadata strip that sits above the severity banner on the
/// per-server status screen. Shows the OS, kernel, uptime and primary
/// IPv4 in one row; tap to expand into a full sheet with every detail
/// (CPU model, all IPs, timezone, RAM/disk totals, boot time).
///
/// Loading and missing-info states are silent — we just don't render
/// anything until the host endpoint resolves. That keeps the rest of
/// the screen visible immediately on slow networks; the header pops in
/// when ready.
class ServerHeader extends ConsumerWidget {
  final String serverId;
  const ServerHeader({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(hostInfoProvider(serverId));
    return asyncInfo.when(
      loading: () => const _HeaderSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) =>
          info == null ? const SizedBox.shrink() : _CompactStrip(info: info),
    );
  }
}

/// Loading-state placeholder shaped like the real compact strip so the
/// status screen doesn't jump when the host endpoint resolves.
class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: const [
            Icon(Icons.dns_outlined, size: 18, color: AppColors.fgMuted),
            SizedBox(width: 8),
            Skeleton(width: 100, height: 12),
            SizedBox(width: 12),
            Skeleton(width: 80, height: 12),
            SizedBox(width: 12),
            Skeleton(width: 60, height: 12),
            Spacer(),
            Icon(Icons.chevron_right, size: 18, color: AppColors.fgMuted),
          ],
        ),
      ),
    );
  }
}

class _CompactStrip extends StatelessWidget {
  final HostInfo info;
  const _CompactStrip({required this.info});

  @override
  Widget build(BuildContext context) {
    final ip = _primaryIp(info);
    final uptimeShort = _uptimeShort(info.uptimeSeconds);
    final osLabel = info.os?.label;

    return InkWell(
      onTap: () => _HostInfoSheet.show(context, info: info),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.dns_outlined,
                size: 18, color: AppColors.fgMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (osLabel != null)
                    _ChipText(text: osLabel, icon: null),
                  if (info.kernel != null)
                    _ChipText(
                      text: info.kernel!,
                      icon: Icons.terminal,
                    ),
                  if (uptimeShort != null)
                    _ChipText(
                      text: 'up $uptimeShort',
                      icon: Icons.schedule,
                    ),
                  if (ip != null)
                    _ChipText(
                      text: ip,
                      icon: Icons.lan,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.fgMuted),
          ],
        ),
      ),
    );
  }

  String? _primaryIp(HostInfo info) {
    for (final ip in info.ipAddresses) {
      if (ip.isIpv4) return ip.addr;
    }
    if (info.ipAddresses.isNotEmpty) return info.ipAddresses.first.addr;
    return null;
  }

  String? _uptimeShort(int? seconds) {
    if (seconds == null) return null;
    final days = seconds ~/ 86400;
    if (days >= 1) return '${days}d';
    final hours = seconds ~/ 3600;
    if (hours >= 1) return '${hours}h';
    final minutes = seconds ~/ 60;
    return '${minutes}m';
  }
}

class _ChipText extends StatelessWidget {
  final String text;
  final IconData? icon;
  const _ChipText({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: AppColors.fgMuted),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.fg,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet with every detail. Reachable by tapping the compact
/// strip — keeps the at-a-glance view uncluttered while the full info is
/// one tap away.
class _HostInfoSheet extends StatelessWidget {
  final HostInfo info;
  const _HostInfoSheet({required this.info});

  static Future<void> show(BuildContext context, {required HostInfo info}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _HostInfoSheet(info: info),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fgMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              info.fqdn ?? info.hostname,
              style: const TextStyle(
                color: AppColors.fg,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            if (info.fqdn != null && info.fqdn != info.hostname)
              Text(
                info.hostname,
                style: const TextStyle(
                  color: AppColors.fgMuted,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            const SizedBox(height: 16),
            ..._buildRows(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows() {
    final rows = <Widget>[];
    void add(String label, String? value) {
      if (value == null || value.isEmpty) return;
      rows.add(_DetailRow(label: label, value: value));
    }

    add('Operating system', info.os?.label);
    add('Kernel', info.kernel);
    add('Architecture', info.arch);
    if (info.cpuModel != null || info.cpuCores != null) {
      final cores = info.cpuCores != null
          ? '${info.cpuCores} core${info.cpuCores == 1 ? "" : "s"}'
          : null;
      final cpu = [info.cpuModel, cores]
          .where((s) => s != null && s.isNotEmpty)
          .join(' · ');
      add('CPU', cpu);
    }
    if (info.ramTotalMb != null) {
      add('RAM', '${(info.ramTotalMb! / 1024).toStringAsFixed(1)} GB');
    }
    if (info.diskTotalGb != null) {
      add('Disk total (/)', '${info.diskTotalGb} GB');
    }
    if (info.uptimeSeconds != null) {
      add('Uptime', _uptimeLong(info.uptimeSeconds!));
    }
    if (info.bootTime != null) {
      add('Booted', _formatBootTime(info.bootTime!));
    }
    add('Timezone', info.timezone);

    if (info.ipAddresses.isNotEmpty) {
      rows.add(const SizedBox(height: 8));
      rows.add(const _SectionLabel(text: 'NETWORK'));
      for (final ip in info.ipAddresses) {
        rows.add(_DetailRow(
          label: '${ip.interface} (${ip.family})',
          value: ip.addr,
          monospace: true,
        ));
      }
    }
    return rows;
  }

  String _uptimeLong(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (mins > 0 && days == 0) parts.add('${mins}m');
    return parts.isEmpty ? '< 1m' : parts.join(' ');
  }

  String _formatBootTime(DateTime t) {
    final local = t.toLocal();
    final y = local.year;
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;
  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.fgMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                color: AppColors.fg,
                fontSize: 13,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
