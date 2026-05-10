import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/client.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';
import '../theme.dart';
import 'pair_screen.dart';

/// Entry point for adding a watchlog server.
///
/// Two flows:
///   * Primary: tap "Scan QR" → opens [PairScreen] which exchanges a
///     short-lived code for a per-device token. The plaintext token never
///     leaves the server-mobile pair.
///   * Advanced: expand "Set up manually" to type the full base URL +
///     master Bearer token. Used when pairing isn't an option (offline,
///     no terminal access, sharing a token across machines).
///
/// Used both as the first-run home (no servers configured) and as a
/// pushed screen from settings ("+ Add server").
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
  bool _manualExpanded = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _submitManual() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    final token = _tokenController.text.trim();
    if (url.isEmpty || token.isEmpty) {
      setState(() => _error = tr(context, S.urlAndTokenRequired));
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
          _error = tr(context, S.invalidToken);
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
      // Same rationale as PairScreen: we may be reached from settings or
      // from the first-run flow. Always settle on the home route.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on DioException catch (e) {
      setState(() {
        _error = tr(context, S.networkErrorPrefix,
            subs: {'detail': e.message ?? e.type.name});
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _error = tr(context, S.errorPrefix, subs: {'detail': '$e'});
        _busy = false;
      });
    }
  }

  Future<void> _openPairScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PairScreen(isFirstRun: widget.isFirstRun),
      ),
    );
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
                  Text(
                    tr(context, S.watchlogTitle),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: context.surfaces.fg,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, S.addFirstServer),
                    style: TextStyle(
                        color: context.surfaces.fgMuted, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
                ElevatedButton.icon(
                  onPressed: _busy ? null : _openPairScreen,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      tr(context, S.scanQrBtn),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tr(context, S.onServerRunQr),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.surfaces.fgMuted.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: context.surfaces.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        tr(context, S.orDivider),
                        style: TextStyle(
                          color: context.surfaces.fgMuted
                              .withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: context.surfaces.border)),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _manualExpanded = !_manualExpanded),
                  icon: Icon(_manualExpanded
                      ? Icons.expand_less
                      : Icons.expand_more),
                  label: Text(tr(context, S.setupManually)),
                ),
                if (_manualExpanded) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: tr(context, S.displayNameOptional),
                      hintText: 'e.g. ticklist',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: tr(context, S.apiBaseUrl),
                      hintText: 'https://api.watchlog.pl',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tokenController,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: tr(context, S.bearerToken),
                      hintText: tr(context, S.pasteToken),
                    ),
                    onSubmitted: (_) => _submitManual(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!,
                        style: const TextStyle(color: AppColors.red)),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton(
                    onPressed: _busy ? null : _submitManual,
                    child: _busy
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(tr(context, S.addServerTitle)),
                  ),
                ],
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
      appBar: AppBar(title: Text(tr(context, S.addServerTitle))),
      body: body,
    );
  }
}
