import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart' as l10n;
import '../models/check_info.dart';
import '../providers/check_info_provider.dart';
import '../theme.dart';

/// Modal sheet explaining what OK / INFO / WARN / CRITICAL mean and when
/// each one fires. Pulled from the backend so wording stays in sync with
/// alert behavior, but a hardcoded fallback ships with the app so the
/// legend works even when the server is unreachable.
class SeverityLegendSheet extends ConsumerWidget {
  final String serverId;
  const SeverityLegendSheet({super.key, required this.serverId});

  static Future<void> show(BuildContext context, {required String serverId}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surfaces.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SeverityLegendSheet(serverId: serverId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(checksInfoProvider(serverId));
    final locale = Localizations.localeOf(context);
    final entries = asyncInfo.maybeWhen(
      data: (info) => info?.severity ?? _fallback,
      orElse: () => _fallback,
    );

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
              l10n.tr(context, l10n.S.severityLevels),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.surfaces.fg,
              ),
            ),
            const SizedBox(height: 16),
            for (final level in _kOrder) ...[
              if (entries[level] != null)
                _LegendRow(
                  level: level,
                  entry: entries[level]!,
                  locale: locale,
                ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String level;
  final SeverityEntry entry;
  final Locale locale;

  const _LegendRow({
    required this.level,
    required this.entry,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(level);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                localizedText(entry.label, locale),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            localizedText(entry.description, locale),
            style: TextStyle(
              color: context.surfaces.fg,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

const List<String> _kOrder = ['OK', 'INFO', 'WARN', 'CRITICAL'];

Color _colorFor(String level) {
  switch (level) {
    case 'OK':
      return AppColors.green;
    case 'INFO':
      return AppColors.accent;
    case 'WARN':
      return AppColors.yellow;
    case 'CRITICAL':
      return AppColors.red;
    default:
      return AppColors.fgMuted;
  }
}

/// Shipped fallback so the legend works offline / on old backends.
final Map<String, SeverityEntry> _fallback = {
  'OK': const SeverityEntry(
    label: {'en': 'OK', 'pl': 'OK'},
    description: {
      'en': 'Everything is normal. No action needed.',
      'pl': 'Wszystko w porządku. Nic nie trzeba robić.',
    },
  ),
  'INFO': const SeverityEntry(
    label: {'en': 'Info', 'pl': 'Info'},
    description: {
      'en': 'Something noteworthy, but not urgent.',
      'pl': 'Coś zauważalnego, ale nie pilnego.',
    },
  ),
  'WARN': const SeverityEntry(
    label: {'en': 'Warning', 'pl': 'Ostrzeżenie'},
    description: {
      'en': 'Look at this within hours, not weeks.',
      'pl': 'Sprawdź to w ciągu godzin, nie tygodni.',
    },
  ),
  'CRITICAL': const SeverityEntry(
    label: {'en': 'Critical', 'pl': 'Krytyczne'},
    description: {
      'en': 'Something is broken or about to expire. Act now.',
      'pl': 'Coś jest popsute albo zaraz wygaśnie. Działaj teraz.',
    },
  ),
};
