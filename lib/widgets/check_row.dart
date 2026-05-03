import 'package:flutter/material.dart';

import '../theme.dart';

enum SilencedKind { none, snoozed, ignored }

class CheckRowData {
  final String check;
  final String severity;
  final String title;
  final SilencedKind silenced;
  CheckRowData({
    required this.check,
    required this.severity,
    required this.title,
    this.silenced = SilencedKind.none,
  });
}

class CheckRow extends StatelessWidget {
  final CheckRowData data;
  final VoidCallback onSnooze;
  final VoidCallback onIgnore;
  final VoidCallback onClear;

  const CheckRow({
    super.key,
    required this.data,
    required this.onSnooze,
    required this.onIgnore,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final color = severityColor(data.severity);
    final emoji = severityEmoji(data.severity);

    Widget? badge;
    if (data.silenced == SilencedKind.snoozed) {
      badge = _badge('snoozed', AppColors.accent);
    } else if (data.silenced == SilencedKind.ignored) {
      badge = _badge('ignored', AppColors.red);
    }

    return Opacity(
      opacity: data.silenced == SilencedKind.none ? 1 : 0.6,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        data.check,
                        style: TextStyle(
                          color: color,
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        badge,
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(data.title,
                      style: const TextStyle(
                          color: AppColors.fgMuted, fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [
                      _smallBtn('Snooze 4h', onSnooze),
                      _smallBtn('Ignore', onIgnore),
                      _smallBtn('Clear', onClear),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      );

  Widget _smallBtn(String text, VoidCallback onPressed) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          minimumSize: const Size(0, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.fgMuted,
          textStyle: const TextStyle(fontSize: 12),
        ),
        child: Text(text),
      );
}
