import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../models/server.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/push_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import 'add_server_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servers = ref.watch(serversProvider);
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, S.settingsTitle))),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SectionHeader(tr(context, S.sectionServers)),
          for (final s in servers.servers)
            _ServerTile(
              server: s,
              isActive: s.id == servers.active?.id,
              onSetActive: () =>
                  ref.read(serversProvider.notifier).setActive(s.id),
              onRename: (newName) => ref
                  .read(serversProvider.notifier)
                  .renameServer(s.id, newName),
              onRemove: () async {
                try {
                  await ref.read(pushServiceProvider).onServerRemoved(s);
                } catch (_) {}
                await ref.read(serversProvider.notifier).removeServer(s.id);
              },
            ),
          ListTile(
            leading: const Icon(Icons.add, color: AppColors.accent),
            title: Text(tr(context, S.addServerEllipsis),
                style: const TextStyle(color: AppColors.accent)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddServerScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.red),
            title: Text(tr(context, S.signOutAll),
                style: const TextStyle(color: AppColors.red)),
            enabled: servers.servers.isNotEmpty,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: ctx.surfaces.bgElevated,
                  title: Text(tr(ctx, S.signOutAllConfirmTitle)),
                  content: Text(tr(ctx, S.signOutAllConfirmBody)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(tr(ctx, S.cancel)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(tr(ctx, S.signOutCta),
                          style: const TextStyle(color: AppColors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await ref.read(pushServiceProvider).onSignOutAll();
                } catch (_) {}
                await ref.read(serversProvider.notifier).signOutAll();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          const Divider(),
          _SectionHeader(tr(context, S.sectionAppearance)),
          const _AppearanceTile(),
          const Divider(),
          _SectionHeader(tr(context, S.sectionLanguage)),
          const _LanguageTile(),
          const Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: context.surfaces.fgMuted),
            title: Text(tr(context, S.sectionAbout)),
            subtitle: Text(
              tr(context, S.aboutBody),
              style: TextStyle(color: context.surfaces.fgMuted),
            ),
          ),
        ],
      ),
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

class _ServerTile extends StatelessWidget {
  final Server server;
  final bool isActive;
  final VoidCallback onSetActive;
  final ValueChanged<String> onRename;
  final VoidCallback onRemove;

  const _ServerTile({
    required this.server,
    required this.isActive,
    required this.onSetActive,
    required this.onRename,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isActive ? Icons.radio_button_checked : Icons.radio_button_off,
        color: isActive ? AppColors.accent : context.surfaces.fgMuted,
      ),
      title: Text(server.name),
      subtitle: Text(
        server.baseUrl,
        style: TextStyle(color: context.surfaces.fgMuted, fontSize: 12),
      ),
      onTap: isActive ? null : onSetActive,
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: context.surfaces.fgMuted),
        onSelected: (value) async {
          if (value == 'rename') {
            final newName = await _promptRename(context, server.name);
            if (newName != null && newName.trim().isNotEmpty) {
              onRename(newName);
            }
          } else if (value == 'remove') {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: ctx.surfaces.bgElevated,
                title: Text(tr(ctx, S.removeServerTitle, subs: {
                  'name': server.name,
                })),
                content: Text(tr(ctx, S.removeServerBody)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(tr(ctx, S.cancel))),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(tr(ctx, S.removeMenu),
                        style: const TextStyle(color: AppColors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) onRemove();
          }
        },
        itemBuilder: (ctx) => [
          PopupMenuItem<String>(
            value: 'rename',
            child: Text(tr(ctx, S.renameMenu)),
          ),
          PopupMenuItem<String>(
            value: 'remove',
            child: Text(tr(ctx, S.removeMenu),
                style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Future<String?> _promptRename(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaces.bgElevated,
        title: Text(tr(ctx, S.renameServer)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: tr(ctx, S.displayName)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr(ctx, S.cancel))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(tr(ctx, S.save)),
          ),
        ],
      ),
    );
  }
}

/// "Appearance" row — three-segment toggle: System / Light / Dark.
class _AppearanceTile extends ConsumerWidget {
  const _AppearanceTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              tr(context, S.themeLabel),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(tr(context, S.themeSystem)),
                icon: const Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(tr(context, S.themeLight)),
                icon: const Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(tr(context, S.themeDark)),
                icon: const Icon(Icons.dark_mode_outlined),
              ),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (set) {
              if (set.isNotEmpty) {
                ref.read(themeModeProvider.notifier).setMode(set.first);
              }
            },
          ),
        ],
      ),
    );
  }
}

/// "Language" row — three-segment toggle: System / English / Polski.
///
/// Forces a specific language regardless of the system locale, or follows
/// the OS when set to System. Persists via [localeProvider].
class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tri-state encoded as a String key because SegmentedButton can't
    // deal with nullable values directly.
    final locale = ref.watch(localeProvider);
    final selected = locale == null
        ? 'system'
        : (locale.languageCode == 'pl' ? 'pl' : 'en');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(
            value: 'system',
            label: Text(tr(context, S.langSystem)),
            icon: const Icon(Icons.translate),
          ),
          ButtonSegment(
            value: 'en',
            label: Text(tr(context, S.langEnglish)),
          ),
          ButtonSegment(
            value: 'pl',
            label: Text(tr(context, S.langPolish)),
          ),
        ],
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (set) {
          final v = set.isEmpty ? 'system' : set.first;
          final next = switch (v) {
            'en' => const Locale('en'),
            'pl' => const Locale('pl'),
            _ => null,
          };
          ref.read(localeProvider.notifier).setLocale(next);
        },
      ),
    );
  }
}
