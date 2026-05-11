import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/strings.dart';
import '../models/server.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/lock_provider.dart';
import '../providers/theme_provider.dart';
import '../theme.dart';
import '../utils/backup_codec.dart';
import '../utils/error_humanizer.dart';

/// Settings → Data screen. Two flows:
///
/// * Export: collect the user's server list (with tokens), theme,
///   locale, and lock config; ask for a passphrase; encrypt to a
///   .wlbackup file; hand to the system share sheet.
/// * Import: pick a file, ask for the passphrase, show what would
///   be replaced, then apply.
///
/// Why two passphrases instead of an OS-level keychain export: the
/// user may want to restore on a different device / different OS, so
/// portability beats convenience here.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});
  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr(context, S.dataTitle))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            tr(context, S.dataHint),
            style: TextStyle(color: context.surfaces.fgMuted, fontSize: 13),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _busy ? null : _exportFlow,
            icon: const Icon(Icons.upload_file_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(tr(context, S.exportCta)),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _importFlow,
            icon: const Icon(Icons.download_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(tr(context, S.importCta)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFlow() async {
    final servers = ref.read(serversProvider).servers;
    if (servers.isEmpty) {
      _snack(tr(context, S.exportEmpty));
      return;
    }
    final pass = await _askPassphrase(create: true);
    if (pass == null) return;
    setState(() => _busy = true);
    try {
      final payload = _collectPayload();
      final wire = await BackupCodec.encrypt(
        payload: payload,
        passphrase: pass,
      );
      final ts = DateTime.now().toIso8601String().split('T').first;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/watchlog-$ts.wlbackup');
      await file.writeAsString(wire);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'watchlog backup',
      );
    } catch (e) {
      if (mounted) _snack(shortMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importFlow() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wlbackup', 'json'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.single.path;
    if (path == null) return;
    final wire = await File(path).readAsString();
    final pass = await _askPassphrase(create: false);
    if (pass == null) return;
    setState(() => _busy = true);
    try {
      final payload = await BackupCodec.decrypt(
        wire: wire,
        passphrase: pass,
      );
      if (!mounted) return;
      final confirmed = await _confirmRestore(payload);
      if (!confirmed) return;
      await _applyPayload(payload);
      if (!mounted) return;
      _snack(tr(context, S.restoreApplied));
    } on DecryptError {
      if (mounted) _snack(tr(context, S.wrongPassphrase));
    } on FormatException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack(shortMessage(context, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, dynamic> _collectPayload() {
    final servers = ref.read(serversProvider);
    final theme = ref.read(themeModeProvider);
    final locale = ref.read(localeProvider);
    final lock = ref.read(lockProvider).config;
    return {
      'schema_version': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'servers': servers.toJson(),
      'theme_mode': _serializeThemeMode(theme),
      'locale': locale?.languageCode,
      'lock_config': {
        // Only export NON-secret lock prefs — never export biometric_enabled
        // on its own, since restoring on a device without biometry would
        // lock the user out. The auto-lock window and secure-screen flag
        // are safe to carry across.
        'auto_lock_minutes': lock.autoLockMinutes,
        'secure_screen': lock.secureScreen,
      },
    };
  }

  String _serializeThemeMode(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  Future<bool> _confirmRestore(Map<String, dynamic> payload) async {
    final serversJson =
        (payload['servers'] as Map<String, dynamic>?)?['servers'] as List?;
    final count = serversJson?.length ?? 0;
    final ts = payload['created_at'] as String? ?? '?';
    final answer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surfaces.bgElevated,
        title: Text(tr(ctx, S.restoreConfirmTitle)),
        content: Text(
          tr(ctx, S.restoreConfirmBody,
              subs: {'n': '$count', 'ts': ts}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr(ctx, S.cancel)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr(ctx, S.restoreApply)),
          ),
        ],
      ),
    );
    return answer == true;
  }

  Future<void> _applyPayload(Map<String, dynamic> payload) async {
    // Servers: replace via secure-storage write directly (we don't
    // have a "set whole state" notifier method but we can clear and
    // re-add each one).
    final serversJson = payload['servers'] as Map<String, dynamic>?;
    if (serversJson != null) {
      await ref.read(serversProvider.notifier).signOutAll();
      final list = (serversJson['servers'] as List?) ?? [];
      for (final raw in list) {
        final s = Server.fromJson(raw as Map<String, dynamic>);
        await ref.read(serversProvider.notifier).addServer(
              name: s.name,
              baseUrl: s.baseUrl,
              token: s.token,
            );
      }
    }
    final theme = payload['theme_mode'] as String?;
    if (theme != null) {
      await ref.read(themeModeProvider.notifier).setMode(
            switch (theme) {
              'light' => ThemeMode.light,
              'dark' => ThemeMode.dark,
              _ => ThemeMode.system,
            },
          );
    }
    final localeCode = payload['locale'] as String?;
    if (localeCode != null) {
      await ref.read(localeProvider.notifier).setLocale(
            Locale(localeCode),
          );
    }
    final lockJson = payload['lock_config'] as Map<String, dynamic>?;
    if (lockJson != null) {
      final current = ref.read(lockProvider).config;
      await ref.read(lockProvider.notifier).updateConfig(
            current.copyWith(
              autoLockMinutes: lockJson['auto_lock_minutes'] as int?,
              secureScreen: lockJson['secure_screen'] as bool?,
            ),
          );
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<String?> _askPassphrase({required bool create}) async {
    final controller = TextEditingController();
    final controller2 = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        var obscure = true;
        var error = '';
        return StatefulBuilder(builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: ctx.surfaces.bgElevated,
            title: Text(tr(
                ctx,
                create
                    ? S.exportPassphraseTitle
                    : S.importPassphraseTitle)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tr(ctx,
                      create ? S.exportPassphraseHint : S.importPassphraseHint),
                  style: TextStyle(
                      color: ctx.surfaces.fgMuted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: tr(ctx, S.passphraseLabel),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => obscure = !obscure),
                    ),
                  ),
                ),
                if (create) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller2,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: tr(ctx, S.passphraseRepeat),
                    ),
                  ),
                ],
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(error,
                      style: const TextStyle(color: AppColors.red)),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(tr(ctx, S.cancel)),
              ),
              ElevatedButton(
                onPressed: () {
                  final v = controller.text;
                  if (v.length < 8) {
                    setState(() => error = tr(ctx, S.passphraseTooShort));
                    return;
                  }
                  if (create && v != controller2.text) {
                    setState(() => error = tr(ctx, S.passphraseMismatch));
                    return;
                  }
                  Navigator.pop(ctx, v);
                },
                child: Text(tr(ctx, S.save)),
              ),
            ],
          );
        });
      },
    );
  }
}
