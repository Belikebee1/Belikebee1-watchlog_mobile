import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme.dart';

/// Bottom sheet that lets the user pick how long to silence a check.
///
/// Backend accepts 1..720 hours (24*30). We surface six common
/// presets plus a "Custom…" entry that opens a numeric prompt for
/// anything in range. Returns the chosen hours, or null if the user
/// dismissed the sheet.
class SnoozeDurationSheet extends StatelessWidget {
  final String checkName;
  const SnoozeDurationSheet({super.key, required this.checkName});

  /// Convenience: open the sheet, return the picked duration, or
  /// null if the user backed out.
  static Future<int?> show(BuildContext context, {required String checkName}) {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: context.surfaces.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SnoozeDurationSheet(checkName: checkName),
    );
  }

  static const _presets = <({int hours, Map<String, String> label})>[
    (hours: 1, label: S.snooze1h),
    (hours: 4, label: S.snooze4hLabel),
    (hours: 12, label: S.snooze12h),
    (hours: 24, label: S.snooze24h),
    (hours: 72, label: S.snooze72h),
    (hours: 168, label: S.snooze168h),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.surfaces.fgMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              tr(context, S.snoozePickerTitle, subs: {'check': checkName}),
              style: TextStyle(
                color: context.surfaces.fg,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr(context, S.snoozePickerHint),
              style: TextStyle(
                color: context.surfaces.fgMuted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in _presets)
                  _PresetChip(
                    label: tr(context, p.label),
                    onTap: () => Navigator.of(context).pop(p.hours),
                  ),
                _PresetChip(
                  label: tr(context, S.snoozeCustom),
                  outlined: true,
                  onTap: () async {
                    final custom = await _promptCustom(context);
                    if (custom != null && context.mounted) {
                      Navigator.of(context).pop(custom);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _promptCustom(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaces.bgElevated,
        title: Text(tr(ctx, S.snoozeCustomTitle)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr(ctx, S.snoozeCustomLabel)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr(ctx, S.cancel)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 1 && v <= 720) {
                Navigator.pop(ctx, v);
              }
            },
            child: Text(tr(ctx, S.save)),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool outlined;
  const _PresetChip({
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          side: BorderSide(color: context.surfaces.border),
          foregroundColor: context.surfaces.fg,
        ),
        child: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        backgroundColor: AppColors.accent.withValues(alpha: 0.18),
        foregroundColor: AppColors.accent,
        elevation: 0,
      ),
      child: Text(label),
    );
  }
}
