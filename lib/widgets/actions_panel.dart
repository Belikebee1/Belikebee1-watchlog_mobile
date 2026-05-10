import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/models.dart';
import '../l10n/strings.dart';
import '../models/action_descriptor.dart';
import '../providers/actions_provider.dart';
import '../providers/auth_provider.dart';
import '../screens/log_viewer_screen.dart';
import '../screens/output_screen.dart';
import '../theme.dart';
import '../utils/error_humanizer.dart';

/// Collapsible panel shown on [StatusScreen] listing the action
/// shortcuts the operator has whitelisted in `actions.allowed_services`.
///
/// Renders nothing when the backend returns an empty list — keeps the
/// status screen clean on hosts that haven't enabled actions, while
/// hosts with services to manage get one-tap controls.
///
/// Each restart / reboot action runs through a confirmation dialog,
/// then ships the resulting [ActionResult] to [OutputScreen] so the
/// user sees stdout/stderr. Tail-logs jumps straight to
/// [LogViewerScreen] which has its own pull-to-refresh loop.
class ActionsPanel extends ConsumerWidget {
  final String serverId;
  const ActionsPanel({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncActions = ref.watch(availableActionsProvider(serverId));
    return asyncActions.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (actions) {
        if (actions.isEmpty) return const SizedBox.shrink();
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
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  tr(context, S.sectionActions).toUpperCase(),
                  style: TextStyle(
                    color: context.surfaces.fgMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              for (final a in actions)
                _ActionRow(serverId: serverId, action: a),
            ],
          ),
        );
      },
    );
  }
}

class _ActionRow extends ConsumerWidget {
  final String serverId;
  final ActionDescriptor action;
  const _ActionRow({required this.serverId, required this.action});

  IconData get _icon {
    if (action.isReboot) return Icons.power_settings_new;
    if (action.isRestart) return Icons.restart_alt;
    if (action.isTailLogs) return Icons.notes_outlined;
    return Icons.bolt;
  }

  Color _color(BuildContext context) {
    if (action.destructive) return AppColors.red;
    if (action.isTailLogs) return context.surfaces.fgMuted;
    return AppColors.accent;
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final api = ref.read(serverApiProvider(serverId));
    if (api == null) return;
    if (action.isTailLogs) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LogViewerScreen(
            serverId: serverId,
            service: action.target,
          ),
        ),
      );
      return;
    }

    final confirmed = await _confirm(context);
    if (!confirmed || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final waitingLabel = action.isReboot
        ? tr(context, S.reboootingSnack)
        : tr(context, S.restartingSnack, subs: {'service': action.target});
    messenger.showSnackBar(SnackBar(content: Text(waitingLabel)));

    try {
      final ActionResult result = action.isReboot
          ? await api.rebootHost()
          : await api.restartService(action.target);
      if (!context.mounted) return;
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => OutputScreen(
            title: action.label,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(shortMessage(context, e))));
    }
  }

  Future<bool> _confirm(BuildContext context) async {
    if (action.isReboot) {
      return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: ctx.surfaces.bgElevated,
              title: Text(tr(ctx, S.rebootConfirmTitle)),
              content: Text(tr(ctx, S.rebootConfirmBody)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(tr(ctx, S.cancel))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(tr(ctx, S.rebootCta)),
                ),
              ],
            ),
          ) ??
          false;
    }
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: ctx.surfaces.bgElevated,
            title: Text(tr(ctx, S.restartConfirmTitle,
                subs: {'service': action.target})),
            content: Text(tr(ctx, S.restartConfirmBody,
                subs: {'service': action.target})),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(tr(ctx, S.cancel))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(tr(ctx, S.restartCta)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _color(context);
    return InkWell(
      onTap: () => _onTap(context, ref),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Icon(_icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.label,
                style: TextStyle(
                  color: action.destructive ? color : context.surfaces.fg,
                  fontSize: 14,
                  fontWeight: action.destructive
                      ? FontWeight.w600
                      : FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.surfaces.fgMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
