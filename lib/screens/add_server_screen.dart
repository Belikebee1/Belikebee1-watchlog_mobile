import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/client.dart';
import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';
import '../theme.dart';

/// Screen for adding a new watchlog server.
///
/// Used in two flows:
///   - first run, no servers yet → shown as the app's home screen
///   - from settings, "+ Add server" → pushed onto the navigator
///
/// On first run there is no app bar back button (you can't bail from the
/// initial sign-in); when pushed from settings, normal back navigation
/// applies.
class AddServerScreen extends ConsumerStatefulWidget {
  final bool isFirstRun;
  const AddServerScreen({super.key, this.isFirstRun = false});

  @override
  ConsumerState<AddServerScreen> createState() => _AddServerScreenState();
}

class _AddServerScreenState extends ConsumerState<AddServerScreen> {
  final _nameController = TextEditingController();
  final _urlController =
      TextEditingController(text: 'https://api.watchlog.pl');
  final _tokenController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    if (url.isEmpty || token.isEmpty) {
      setState(() => _error = 'URL and token are required.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final api = WatchlogApi(baseUrl: url, token: token);
      final ok = await api.verifyToken();
      if (!ok) {
        setState(() {
          _error = 'Invalid token.';
          _busy = false;
        });
        return;
      }
      final server = await ref.read(serversProvider.notifier).addServer(
            name: name,
            baseUrl: url,
            token: token,
          );
      try {
        await ref.read(pushServiceProvider).onServerAdded(server);
      } catch (_) {}
      if (!mounted) return;
      if (!widget.isFirstRun) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      setState(() {
        _error = 'Network error: ${e.message ?? e.type.name}';
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.isFirstRun) ...[
                  const SizedBox(height: 32),
                  const Text('👁️',
                      style: TextStyle(fontSize: 56),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  const Text(
                    'watchlog',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.fg,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add your first watchlog server.',
                    style: TextStyle(color: AppColors.fgMuted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display name (optional)',
                    hintText: 'e.g. ticklist',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'API base URL',
                    hintText: 'https://api.watchlog.pl',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tokenController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Bearer token',
                    hintText: 'paste token',
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(_error!,
                      style: const TextStyle(color: AppColors.red)),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.bg))
                      : Text(widget.isFirstRun ? 'Sign in' : 'Add server'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Get your token by running on the server:\n'
                  'sudo watchlog api setup',
                  style: TextStyle(
                      color: AppColors.fgMuted.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontFamily: 'monospace'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.isFirstRun) {
      return Scaffold(body: body);
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Add server')),
      body: body,
    );
  }
}
