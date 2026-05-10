import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/notification_prefs.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_prefs_provider.dart';
import '../theme.dart';
import '../utils/error_humanizer.dart';
import '../widgets/error_view.dart';
import '../widgets/skeleton.dart';

/// Per-server notification settings: quiet hours plus the global
/// severity floor. Pushed from Settings → server tile menu.
///
/// All edits hit `PATCH /api/v1/push/preferences` immediately on save —
/// there's no separate "save" button. Each toggle/picker triggers its
/// own round-trip and the provider invalidates so the UI re-reads from
/// the server (single source of truth, no local-vs-server divergence).
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  final String serverId;
  const NotificationSettingsScreen({super.key, required this.serverId});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _busy = false;

  Future<void> _patch(Map<String, dynamic> partial) async {
    final api = ref.read(serverApiProvider(widget.serverId));
    if (api == null) return;
    setState(() => _busy = true);
    try {
      // Send the device's IANA timezone the first time the user
      // engages with quiet hours so the backend evaluates the window
      // in the right clock.
      final withTz = {
        'quiet_timezone': DateTime.now().timeZoneName,
        ...partial,
      };
      await api.updateNotificationPreferences(withTz);
      ref.invalidate(notificationPrefsProvider(widget.serverId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, S.prefsSavedSnack))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shortMessage(context, e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickTime({
    required BuildContext context,
    required String currentHHMM,
    required ValueChanged<String> onPicked,
  }) async {
    final parts = currentHHMM.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 22,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        // Always render the time picker in 24h regardless of locale —
        // matches the HH:MM string format we send to the backend.
        data: MediaQuery.of(ctx)
            .copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null) return;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    onPicked('$hh:$mm');
  }

  @override
  Widget build(BuildContext context) {
    final asyncPrefs = ref.watch(notificationPrefsProvider(widget.serverId));
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, S.notificationsTitle))),
      body: asyncPrefs.when(
        loading: () => const _PrefsSkeleton(),
        error: (e, _) => ErrorView.from(
          e,
          onRetry: () =>
              ref.invalidate(notificationPrefsProvider(widget.serverId)),
        ),
        data: (prefs) => _Body(
          prefs: prefs,
          busy: _busy,
          onPatch: _patch,
          onPickTime: _pickTime,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final NotificationPreferences prefs;
  final bool busy;
  final Future<void> Function(Map<String, dynamic>) onPatch;
  final Future<void> Function({
    required BuildContext context,
    required String currentHHMM,
    required ValueChanged<String> onPicked,
  }) onPickTime;

  const _Body({
    required this.prefs,
    required this.busy,
    required this.onPatch,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 8),
        _SectionHeader(tr(context, S.sectionQuietHours)),
        SwitchListTile(
          title: Text(tr(context, S.quietHoursToggle)),
          value: prefs.quietHoursEnabled,
          onChanged: busy
              ? null
              : (v) => onPatch({'quiet_hours_enabled': v}),
        ),
        ListTile(
          enabled: prefs.quietHoursEnabled && !busy,
          title: Text(tr(context, S.quietStartLabel)),
          trailing: Text(prefs.quietStart,
              style: TextStyle(
                color: context.surfaces.fg,
                fontFamily: 'monospace',
                fontSize: 16,
              )),
          onTap: () => onPickTime(
            context: context,
            currentHHMM: prefs.quietStart,
            onPicked: (v) => onPatch({'quiet_start': v}),
          ),
        ),
        ListTile(
          enabled: prefs.quietHoursEnabled && !busy,
          title: Text(tr(context, S.quietEndLabel)),
          trailing: Text(prefs.quietEnd,
              style: TextStyle(
                color: context.surfaces.fg,
                fontFamily: 'monospace',
                fontSize: 16,
              )),
          onTap: () => onPickTime(
            context: context,
            currentHHMM: prefs.quietEnd,
            onPicked: (v) => onPatch({'quiet_end': v}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            tr(context, S.quietHoursHint),
            style:
                TextStyle(color: context.surfaces.fgMuted, fontSize: 12),
          ),
        ),
        ListTile(
          enabled: prefs.quietHoursEnabled && !busy,
          title: Text(tr(context, S.quietOverrideLabel)),
          trailing: _SeverityDropdown(
            value: prefs.quietMinSeverity,
            enabled: prefs.quietHoursEnabled && !busy,
            onChanged: (v) => onPatch({'quiet_min_severity': v}),
          ),
        ),
        const Divider(),
        _SectionHeader(tr(context, S.sectionFloor)),
        ListTile(
          enabled: !busy,
          title: Text(tr(context, S.minSeverityLabel)),
          trailing: _SeverityDropdown(
            value: prefs.minSeverity,
            enabled: !busy,
            onChanged: (v) => onPatch({'min_severity': v}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Text(
            tr(context, S.minSeverityHint),
            style:
                TextStyle(color: context.surfaces.fgMuted, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// Severity picker. Values are uppercase as the backend expects; the
/// displayed labels are localized.
class _SeverityDropdown extends StatelessWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;
  const _SeverityDropdown({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final levels = [
      ('OK', tr(context, S.sevOk)),
      ('INFO', tr(context, S.sevInfo)),
      ('WARN', tr(context, S.sevWarn)),
      ('CRITICAL', tr(context, S.sevCritical)),
    ];
    return DropdownButton<String>(
      value: value,
      onChanged: enabled ? (v) { if (v != null) onChanged(v); } : null,
      items: [
        for (final l in levels)
          DropdownMenuItem(
            value: l.$1,
            child: Text(l.$2),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: context.surfaces.fgMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _PrefsSkeleton extends StatelessWidget {
  const _PrefsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonGroup(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Skeleton(width: 120, height: 12),
          SizedBox(height: 12),
          Skeleton(height: 56, radius: 8),
          SizedBox(height: 8),
          Skeleton(height: 56, radius: 8),
          SizedBox(height: 8),
          Skeleton(height: 56, radius: 8),
          SizedBox(height: 24),
          Skeleton(width: 100, height: 12),
          SizedBox(height: 12),
          Skeleton(height: 56, radius: 8),
        ],
      ),
    );
  }
}
