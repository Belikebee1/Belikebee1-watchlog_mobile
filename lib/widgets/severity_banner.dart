import 'package:flutter/material.dart';

import '../api/models.dart';
import '../theme.dart';

class SeverityBanner extends StatelessWidget {
  final Status? status;
  final VoidCallback onRefresh;
  const SeverityBanner({super.key, required this.status, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (status == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Text('⏳', style: TextStyle(fontSize: 32)),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No heartbeat yet',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.fg)),
                    SizedBox(height: 4),
                    Text(
                      'Run watchlog at least once on the server.',
                      style:
                          TextStyle(color: AppColors.fgMuted, fontSize: 13),
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
        ? '${age.inMinutes} min ago'
        : '${(age.inMinutes / 60).toStringAsFixed(1)} h ago';

    final title = (s.worstSeverity == 'OK' || s.worstSeverity == 'INFO')
        ? 'All clear – ${s.checksTotal} checks'
        : '${s.actionable.length} item(s) need attention';

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
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.fg)),
                  const SizedBox(height: 4),
                  Text(
                    '${s.host} · v${s.watchlogVersion} · $ageStr',
                    style: const TextStyle(
                        color: AppColors.fgMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.fgMuted),
              onPressed: onRefresh,
              tooltip: 'Refresh',
            ),
          ],
        ),
      ),
    );
  }
}
