import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.cloud_outlined, color: AppColors.fgMuted),
            title: const Text('API URL'),
            subtitle: Text(auth.baseUrl ?? '(not set)',
                style: const TextStyle(color: AppColors.fgMuted)),
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined, color: AppColors.fgMuted),
            title: const Text('Token'),
            subtitle: Text(
              auth.token == null
                  ? '(not set)'
                  : '${auth.token!.substring(0, 8)}…${auth.token!.substring(auth.token!.length - 4)}',
              style: const TextStyle(
                  color: AppColors.fgMuted, fontFamily: 'monospace'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.red),
            title: const Text('Sign out',
                style: TextStyle(color: AppColors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.bgElevated,
                  title: const Text('Sign out?'),
                  content: const Text(
                      'You will need to enter the token again to sign in.'),
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
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
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
