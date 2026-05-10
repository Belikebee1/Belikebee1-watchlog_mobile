import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/check_info.dart';
import '../providers/check_info_provider.dart';
import '../theme.dart';
import '../widgets/check_row.dart';

/// Modal bottom sheet that explains a single check in plain language.
///
/// Pulls the explainer from the cached [checksInfoProvider] payload and
/// localizes each field via [localizedText]. If the backend is too old to
/// have the endpoint, falls back to a minimal sheet showing just the title.
///
/// Action buttons (Snooze / Ignore / Clear) are surfaced here too so the
/// user doesn't have to dismiss the sheet to act on the alert.
class CheckExplainerSheet extends ConsumerWidget {
  final String serverId;
  final CheckRowData data;
  final VoidCallback? onSnooze;
  final VoidCallback? onIgnore;
  final VoidCallback? onClear;

  const CheckExplainerSheet({
    super.key,
    required this.serverId,
    required this.data,
    this.onSnooze,
    this.onIgnore,
    this.onClear,
  });

  static Future<void> show(
    BuildContext context, {
    required String serverId,
    required CheckRowData data,
    VoidCallback? onSnooze,
    VoidCallback? onIgnore,
    VoidCallback? onClear,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bgElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => CheckExplainerSheet(
        serverId: serverId,
        data: data,
        onSnooze: onSnooze,
        onIgnore: onIgnore,
        onClear: onClear,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInfo = ref.watch(checksInfoProvider(serverId));
    final locale = Localizations.localeOf(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (ctx, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
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
              _Header(data: data, asyncInfo: asyncInfo, locale: locale),
              const SizedBox(height: 16),
              asyncInfo.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _CurrentResultOnly(data: data),
                data: (info) {
                  final explainer = info?.explainerFor(data.check);
                  if (explainer == null) {
                    return _CurrentResultOnly(data: data);
                  }
                  return _ExplainerBody(
                    explainer: explainer,
                    data: data,
                    locale: locale,
                  );
                },
              ),
              const SizedBox(height: 16),
              _ActionRow(
                data: data,
                onSnooze: onSnooze,
                onIgnore: onIgnore,
                onClear: onClear,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final CheckRowData data;
  final AsyncValue<ChecksInfo?> asyncInfo;
  final Locale locale;

  const _Header({
    required this.data,
    required this.asyncInfo,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final friendlyTitle = asyncInfo.maybeWhen(
      data: (info) {
        final exp = info?.explainerFor(data.check);
        return exp == null ? null : localizedText(exp.title, locale);
      },
      orElse: () => null,
    );
    final color = _severityColor(data.severity);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SeverityBadge(severity: data.severity, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                friendlyTitle ?? data.check,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.fg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.check,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.fgMuted.withValues(alpha: 0.8),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExplainerBody extends StatelessWidget {
  final CheckExplainer explainer;
  final CheckRowData data;
  final Locale locale;

  const _ExplainerBody({
    required this.explainer,
    required this.data,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          icon: Icons.search,
          label: localizedText(_kWhatLabels, locale),
          body: localizedText(explainer.what, locale),
        ),
        const SizedBox(height: 12),
        _Section(
          icon: Icons.shield_outlined,
          label: localizedText(_kWhyLabels, locale),
          body: localizedText(explainer.why, locale),
        ),
        const SizedBox(height: 12),
        _CurrentResultBlock(data: data),
        const SizedBox(height: 12),
        _Section(
          icon: Icons.handyman_outlined,
          label: localizedText(_kRemediationLabels, locale),
          body: localizedText(explainer.remediation, locale),
          monospace: true,
        ),
      ],
    );
  }
}

class _CurrentResultOnly extends StatelessWidget {
  final CheckRowData data;
  const _CurrentResultOnly({required this.data});

  @override
  Widget build(BuildContext context) => _CurrentResultBlock(data: data);
}

class _CurrentResultBlock extends StatelessWidget {
  final CheckRowData data;
  const _CurrentResultBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return _Section(
      icon: Icons.timeline,
      label: localizedText(_kNowLabels, locale),
      body: data.title,
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String label;
  final String body;
  final bool monospace;

  const _Section({
    required this.icon,
    required this.label,
    required this.body,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SelectableText(
          body,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.fg,
            height: 1.4,
            fontFamily: monospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;
  final Color color;
  const _SeverityBadge({required this.severity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final CheckRowData data;
  final VoidCallback? onSnooze;
  final VoidCallback? onIgnore;
  final VoidCallback? onClear;

  const _ActionRow({
    required this.data,
    required this.onSnooze,
    required this.onIgnore,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isSilenced = data.silenced != SilencedKind.none;
    if (isSilenced) {
      return ElevatedButton.icon(
        onPressed: onClear == null
            ? null
            : () {
                Navigator.of(context).pop();
                onClear!();
              },
        icon: const Icon(Icons.notifications_active_outlined),
        label: const Text('Re-enable'),
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onSnooze == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    onSnooze!();
                  },
            icon: const Icon(Icons.snooze_outlined, size: 18),
            label: const Text('Snooze 4h'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onIgnore == null
                ? null
                : () {
                    Navigator.of(context).pop();
                    onIgnore!();
                  },
            icon: const Icon(Icons.notifications_off_outlined, size: 18),
            label: const Text('Ignore'),
          ),
        ),
      ],
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

const Map<String, String> _kWhatLabels = {
  'en': 'What it checks',
  'pl': 'Co sprawdza',
};
const Map<String, String> _kWhyLabels = {
  'en': 'Why it matters',
  'pl': 'Dlaczego to ważne',
};
const Map<String, String> _kNowLabels = {
  'en': 'Right now',
  'pl': 'Aktualnie',
};
const Map<String, String> _kRemediationLabels = {
  'en': 'How to fix',
  'pl': 'Co zrobić',
};
