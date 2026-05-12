import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../providers/server_update_provider.dart';
import '../theme.dart';

/// Canonical one-liner shown in the banner. Covers the most common
/// install path (system pip + systemd services). Users on venv/pipx
/// installs adapt it to their setup — the GitHub release notes link
/// linked from the banner has detailed install-method instructions.
const _kUpgradeCommand =
    'pip install --upgrade watchlog && sudo systemctl restart watchlog-api watchlog';

/// Compact card that appears at the top of the Status tab when the
/// server's installed watchlog version is older than the latest
/// GitHub release.
///
/// Stays hidden when:
///   - the comparison is impossible (old server, GitHub unreachable),
///   - the server is already on the latest version,
///   - the user has dismissed this exact version (per-server scope).
class UpdateBanner extends ConsumerWidget {
  final String serverId;
  const UpdateBanner({super.key, required this.serverId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(serverUpdateProvider(serverId));
    if (status == null || !status.hasUpdate) {
      return const SizedBox.shrink();
    }
    final dismissals = ref.watch(updateDismissalProvider);
    final latestVersion = status.latest?.version ?? '';
    if (latestVersion.isNotEmpty &&
        dismissals[serverId] == latestVersion) {
      return const SizedBox.shrink();
    }

    final scheme = Theme.of(context).colorScheme;
    // Use the same accent colour the rest of the app uses for "info worth
    // your attention but not an alarm" — softer than the severity banner's
    // WARN/CRIT palette.
    final accent = AppColors.accent;

    return Card(
      color: accent.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.system_update_alt, color: accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr(context, S.updateBannerTitle),
                        style: TextStyle(
                          color: context.surfaces.fg,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tr(context, S.updateBannerSubtitle, subs: {
                          'installed': status.installed ?? '?',
                          'latest': latestVersion,
                        }),
                        style: TextStyle(
                          color: context.surfaces.fgMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: tr(context, S.updateBannerDismiss),
                  color: context.surfaces.fgMuted,
                  onPressed: latestVersion.isEmpty
                      ? null
                      : () => ref
                          .read(updateDismissalProvider.notifier)
                          .dismiss(serverId, latestVersion),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // The actual command, presented as a copyable code block so
            // the user can SSH to the box and paste — no typing,
            // no transcription mistakes on critical strings like the
            // service name.
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: context.surfaces.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.surfaces.border),
              ),
              child: Text(
                _kUpgradeCommand,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12.5,
                  color: context.surfaces.fg,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyCommand(context),
                    icon: const Icon(Icons.copy, size: 16),
                    label: Text(tr(context, S.updateBannerCopy)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.onSurface,
                      side: BorderSide(color: context.surfaces.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: status.latest?.htmlUrl.isNotEmpty == true
                        ? () => _openReleaseNotes(status.latest!.htmlUrl)
                        : null,
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(tr(context, S.updateBannerReleaseNotes)),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyCommand(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _kUpgradeCommand));
    HapticFeedback.selectionClick();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(context, S.updateBannerCopied))),
    );
  }

  Future<void> _openReleaseNotes(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
