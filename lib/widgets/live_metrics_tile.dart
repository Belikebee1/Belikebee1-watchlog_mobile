import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/strings.dart';
import '../theme.dart';

/// Compact tile showing live disk + RAM usage as colored progress bars.
///
/// Rendered between the server header and the severity banner. Pulls
/// numerics from the [Status.metrics] map populated by the disk_space
/// and memory checks. If neither check exposed metrics (older watchlog
/// backend on schema_version 1) the tile renders nothing — the rest of
/// the screen keeps working.
///
/// Bar color follows the same severity scale as the rest of the app:
///   * < warn threshold → green
///   * warn ≤ x < critical → yellow
///   * ≥ critical → red
class LiveMetricsTile extends StatelessWidget {
  final Status status;
  const LiveMetricsTile({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final disk = status.metricsFor('disk_space');
    final mem = status.metricsFor('memory');
    if (disk == null && mem == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaces.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.surfaces.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              tr(context, S.liveMetricsHeader),
              style: TextStyle(
                color: context.surfaces.fgMuted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          if (disk != null) _DiskRow(metrics: disk),
          if (disk != null && mem != null) const SizedBox(height: 10),
          if (mem != null) _MemoryRow(metrics: mem),
        ],
      ),
    );
  }
}

class _DiskRow extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _DiskRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final usedPct = _toDouble(metrics['worst_used_pct']);
    final freeGb = _toDouble(metrics['worst_free_gb']);
    final totalGb = _toDouble(metrics['worst_total_gb']);
    final mountpoint = metrics['worst_mountpoint'] as String?;
    final warnPct = _toDouble(metrics['warn_pct']) ?? 80;
    final critPct = _toDouble(metrics['critical_pct']) ?? 90;

    final color = _colorForPct(usedPct, warn: warnPct, crit: critPct);
    final subtitle = (freeGb != null && totalGb != null)
        ? '${freeGb.toStringAsFixed(0)} GB ${tr(context, S.freeShort)} ${tr(context, S.ofShort)} ${totalGb.toStringAsFixed(0)} GB'
        : null;

    return _MetricBar(
      icon: Icons.storage_rounded,
      label: tr(context, S.diskLabel),
      mountpointHint: mountpoint == '/' ? null : mountpoint,
      pct: usedPct,
      color: color,
      subtitle: subtitle,
    );
  }
}

class _MemoryRow extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _MemoryRow({required this.metrics});

  @override
  Widget build(BuildContext context) {
    final usedPct = _toDouble(metrics['used_pct']);
    final usedMb = _toDouble(metrics['used_mb']);
    final totalMb = _toDouble(metrics['total_mb']);
    final availMb = _toDouble(metrics['available_mb']);
    final critFreeMb = _toDouble(metrics['critical_mb_free']) ?? 100;
    final warnFreeMb = _toDouble(metrics['warn_mb_free']) ?? 500;

    // Memory thresholds are expressed in absolute MB-free, not %, so
    // synthesize a comparable color based on the ratio of available
    // RAM to the warn/critical floors.
    Color color = AppColors.green;
    if (availMb != null) {
      if (availMb <= critFreeMb) {
        color = AppColors.red;
      } else if (availMb <= warnFreeMb) {
        color = AppColors.yellow;
      }
    }

    final subtitle = (usedMb != null && totalMb != null)
        ? '${(usedMb / 1024).toStringAsFixed(1)} GB ${tr(context, S.usedShort)} ${tr(context, S.ofShort)} ${(totalMb / 1024).toStringAsFixed(1)} GB'
        : null;

    return _MetricBar(
      icon: Icons.memory,
      label: tr(context, S.ramLabel2),
      mountpointHint: null,
      pct: usedPct,
      color: color,
      subtitle: subtitle,
    );
  }
}

/// Generic bar row reused by disk / RAM / future metrics.
class _MetricBar extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? mountpointHint;
  final double? pct;
  final Color color;
  final String? subtitle;

  const _MetricBar({
    required this.icon,
    required this.label,
    required this.mountpointHint,
    required this.pct,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = pct == null ? 0.0 : (pct! / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: context.surfaces.fgMuted),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: context.surfaces.fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (mountpointHint != null) ...[
                const SizedBox(width: 6),
                Text(
                  '($mountpointHint)',
                  style: TextStyle(
                    color: context.surfaces.fgMuted,
                    fontSize: 12,
                  ),
                ),
              ],
              const Spacer(),
              if (pct != null)
                Text(
                  '${pct!.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 6,
              backgroundColor: context.surfaces.bgCard.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: context.surfaces.fgMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

double? _toDouble(Object? raw) {
  if (raw == null) return null;
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}

Color _colorForPct(double? pct, {required double warn, required double crit}) {
  if (pct == null) return AppColors.green;
  if (pct >= crit) return AppColors.red;
  if (pct >= warn) return AppColors.yellow;
  return AppColors.green;
}
