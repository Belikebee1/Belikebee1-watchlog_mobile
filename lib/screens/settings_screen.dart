import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/server.dart';
import '../providers/auth_provider.dart';
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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const _SectionHeader('Servers'),
          for (final s in servers.servers)
            _ServerTile(
              server: s,
              isActive: s.id == servers.active?.id,
              onSetActive: () =>
                  ref.read(serversProvider.notifier).setActive(s.id),
              onRename: (newName) =>
                  ref.read(serversProvider.notifier).renameServer(s.id, newName),
              onRemove: () async {
                try {
                  await ref.read(pushServiceProvider).onServerRemoved(s);
                } catch (_) {}
                await ref.read(serversProvider.notifier).removeServer(s.id);
              },
            ),
          ListTile(
            leading: const Icon(Icons.add, color: AppColors.accent),
            title: const Text('Add server…',
                style: TextStyle(color: AppColors.accent)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddServerScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.red),
            title: const Text('Sign out of all servers',
                style: TextStyle(color: AppColors.red)),
            enabled: servers.servers.isNotEmpty,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.bgElevated,
                  title: const Text('Sign out of all servers?'),
                  content: const Text(
                      'This removes every server from this device. You will need to add them again to receive alerts.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign out',
                          style: TextStyle(color: AppColors.red)),
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
          const _SectionHeader('Appearance'),
          const _AppearanceTile(),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppColors.fgMuted),
            title: Text('About'),
            subtitle: Text(
              'watchlog mobile · v0.1.0\nhttps://watchlog.pl',
              style: TextStyle(color: AppColors.fgMuted),
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
          style: const TextStyle(
            color: AppColors.fgMuted,
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
        color: isActive ? AppColors.accent : AppColors.fgMuted,
      ),
      title: Text(server.name),
      subtitle: Text(
        server.baseUrl,
        style: const TextStyle(color: AppColors.fgMuted, fontSize: 12),
      ),
      onTap: isActive ? null : onSetActive,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppColors.fgMuted),
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
                backgroundColor: AppColors.bgElevated,
                title: Text('Remove ${server.name}?'),
                content: const Text(
                    'This stops alerts from this server on this device.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Remove',
                        style: TextStyle(color: AppColors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) onRemove();
          }
        },
        itemBuilder: (ctx) => const [
          PopupMenuItem<String>(
            value: 'rename',
            child: Text('Rename'),
          ),
          PopupMenuItem<String>(
            value: 'remove',
            child: Text('Remove', style: TextStyle(color: AppColors.red)),
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
        backgroundColor: AppColors.bgElevated,
        title: const Text('Rename server'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Display name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// "Appearance" row — three-segment toggle: System / Light / Dark.
///
/// We use a SegmentedButton rather than a dialog/dropdown so the user
/// sees all three options at once and can toggle with a single tap. The
/// chosen mode persists in secure storage via [themeModeProvider].
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Theme',
              style: TextStyle(fontSize: 14),
            ),
          ),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('System'),
                icon: Icon(Icons.brightness_auto_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(Icons.light_mode_outlined),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(Icons.dark_mode_outlined),
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
