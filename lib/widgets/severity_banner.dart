import 'package:flutter/material.dart';

import '../api/models.dart';
import '../l10n/strings.dart';
import '../theme.dart';

class SeverityBanner extends StatelessWidget {
  final Status? status;
  final VoidCallback onRefresh;
  const SeverityBanner(
      {super.key, required this.status, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text('⏳', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr(context, S.noHeartbeat),
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.surfaces.fg)),
                    const SizedBox(height: 4),
                    Text(
                      tr(context, S.noHeartbeatHint),
                      style: TextStyle(
                          color: context.surfaces.fgMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final s = status!;
    final color = severityColor(s.worstSeverity);
    final emoji = severityEmoji(s.worstSeverity);
    final age = s.age;
    final ageStr = age.inMinutes < 60
        ? tr(context, S.ageMinAgo, subs: {'n': '${age.inMinutes}'})
        : tr(context, S.ageHAgo,
            subs: {'n': (age.inMinutes / 60).toStringAsFixed(1)});

    final title = (s.worstSeverity == 'OK' || s.worstSeverity == 'INFO')
        ? tr(context, S.allClearN, subs: {'n': '${s.checksTotal}'})
        : tr(context, S.itemsNeedAttention,
            subs: {'n': '${s.actionable.length}'});

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.surfaces.fg)),
                  const SizedBox(height: 4),
                  Text(
                    '${s.host} · v${s.watchlogVersion} · $ageStr',
                    style: TextStyle(
                        color: context.surfaces.fgMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: context.surfaces.fgMuted),
              onPressed: onRefresh,
              tooltip: tr(context, S.refreshTooltip),
            ),
          ],
        ),
      ),
    );
  }
}
