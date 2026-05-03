import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/client.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _urlController =
      TextEditingController(text: 'https://api.watchlog.pl');
  final _tokenController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    if (url.isEmpty || token.isEmpty) {
      setState(() => _error = 'Both fields are required.');
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
      await ref.read(authProvider.notifier).signIn(url, token);
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
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
                    'Sign in with your watchlog API token.',
                    style: TextStyle(color: AppColors.fgMuted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
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
                    onSubmitted: (_) => _signIn(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!,
                        style: const TextStyle(color: AppColors.red)),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton(
                    onPressed: _busy ? null : _signIn,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.bg))
                        : const Text('Sign in'),
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
      ),
    );
  }
}
