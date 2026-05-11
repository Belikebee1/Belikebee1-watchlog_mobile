import 'package:flutter/material.dart';

import '../data/changelog.dart';
import '../l10n/strings.dart';
import '../theme.dart';

/// Full chronological release-notes scroll. Reachable from Settings.
/// The "what's new" modal renders only the slice the user hasn't
/// seen; this screen always shows the full history.
class ReleaseNotesScreen extends StatelessWidget {
  const ReleaseNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, S.releaseNotesTitle))),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: kChangelog.length,
        itemBuilder: (ctx, i) {
          final entry = kChangelog[i];
          final title = entry.title[locale] ?? entry.title['en'] ?? '';
          final items = entry.items[locale] ?? entry.items['en'] ?? const [];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'v${entry.version}',
                      style: TextStyle(
                        color: context.surfaces.fg,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      entry.date,
                      style: TextStyle(
                        color: context.surfaces.fgMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                for (final line in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.surfaces.fgMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line,
                            style: TextStyle(
                              color: context.surfaces.fg,
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Modal version: shows ONLY the slice the user hasn't acknowledged.
/// Caller is responsible for calling ChangelogNotifier.markSeen() in
/// the modal's then() so it doesn't re-pop next launch.
Future<void> showWhatsNewModal(
  BuildContext context, {
  required List<ChangelogEntry> entries,
}) async {
  final locale = Localizations.localeOf(context).languageCode;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.surfaces.bgElevated,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) {
          final newest = entries.first;
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ctx.surfaces.fgMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr(ctx, S.whatsNewTitle,
                      subs: {'version': newest.version}),
                  style: TextStyle(
                    color: ctx.surfaces.fg,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                for (final e in entries) ...[
                  if (e != newest) ...[
                    const SizedBox(height: 8),
                    Text(
                      tr(ctx, S.versionLabel, subs: {'n': e.version}),
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (final line
                      in (e.items[locale] ?? e.items['en'] ?? const []))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7, right: 10),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              line,
                              style: TextStyle(
                                color: ctx.surfaces.fg,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(tr(ctx, S.whatsNewClose)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
