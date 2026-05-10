import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../api/client.dart';
import '../l10n/strings.dart';
import '../providers/auth_provider.dart';
import '../providers/push_provider.dart';
import '../theme.dart';

/// Full-screen pairing flow.
///
/// Default mode: live camera viewport using `mobile_scanner`. The scanner
/// fires on every detected QR and we pick the first that decodes to a
/// valid watchlog payload (`{"v":1,"kind":"watchlog_pairing",...}`).
///
/// Manual fallback: tap "Enter code manually" to switch to a typed-input
/// form (server URL + 6-character code). Useful when the device has no
/// camera, the QR is too small, or the user only has the code on paper.
///
/// On success: calls [ServersNotifier.addServer] with the freshly minted
/// per-device token and pops back to the previous screen. Push token is
/// auto-registered against the new server via [PushService.onServerAdded].
class PairScreen extends ConsumerStatefulWidget {
  /// True when shown as the app's first screen (no servers yet).
  /// Mostly used to suppress the back button — the user can't bail to a
  /// previous screen because there isn't one.
  final bool isFirstRun;
  const PairScreen({super.key, this.isFirstRun = false});

  @override
  ConsumerState<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends ConsumerState<PairScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );
  bool _manualMode = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _onScanCapture(BarcodeCapture capture) async {
    if (_busy) return;
    for (final b in capture.barcodes) {
      final raw = b.rawValue;
      if (raw == null || raw.isEmpty) continue;
      final parsed = _tryParseQr(raw);
      if (parsed == null) continue;
      // Pause the scanner so we don't fire repeatedly while we exchange
      // the code over the network.
      await _scannerController.stop();
      await _attemptPair(baseUrl: parsed.baseUrl, code: parsed.code);
      return;
    }
  }

  Future<void> _onManualSubmit({
    required String baseUrl,
    required String code,
  }) async {
    if (_busy) return;
    if (baseUrl.trim().isEmpty || code.trim().isEmpty) {
      setState(() => _error = tr(context, S.serverUrlAndCodeRequired));
      return;
    }
    await _attemptPair(baseUrl: baseUrl.trim(), code: code.trim());
  }

  Future<void> _attemptPair({
    required String baseUrl,
    required String code,
  }) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await pairWithCode(
        baseUrl: baseUrl,
        code: code,
        deviceLabel: _defaultDeviceLabel(),
        platform: _platformString(),
      );
      if (result == null) {
        setState(() {
          _error = tr(context, S.invalidCode);
          _busy = false;
        });
        if (!_manualMode) {
          await _scannerController.start();
        }
        return;
      }
      final server = await ref.read(serversProvider.notifier).addServer(
            name: result.name,
            baseUrl: baseUrl,
            token: result.token,
          );
      try {
        await ref.read(pushServiceProvider).onServerAdded(server);
      } catch (_) {}
      if (!mounted) return;
      // Pop all the way back to the home route. We may be sitting on
      // {Home, Settings, AddServerScreen, PairScreen} or
      // {AddServerScreen(first-run), PairScreen} — in either case,
      // landing on the overview after a successful pair is correct.
      // popUntil(isFirst) is also safe when MaterialApp's home has just
      // swapped from AddServerScreen → OverviewScreen because of the
      // state change: the Navigator's first route is whichever widget
      // is currently rendered as MaterialApp.home.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on DioException catch (e) {
      setState(() {
        _error = tr(context, S.networkErrorPrefix,
            subs: {'detail': e.message ?? e.type.name});
        _busy = false;
      });
      if (!_manualMode) {
        try {
          await _scannerController.start();
        } catch (_) {}
      }
    } catch (e) {
      setState(() {
        _error = tr(context, S.errorPrefix, subs: {'detail': '$e'});
        _busy = false;
      });
      if (!_manualMode) {
        try {
          await _scannerController.start();
        } catch (_) {}
      }
    }
  }

  String _platformString() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'other';
  }

  String _defaultDeviceLabel() {
    // We don't have access to a precise model name without extra plugins;
    // the platform string is a reasonable best-effort hint that helps
    // disambiguate "android phone" vs "ios phone" in `tokens list`.
    return _platformString() == 'android'
        ? 'Android device'
        : _platformString() == 'ios'
            ? 'iOS device'
            : 'Mobile device';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_manualMode
            ? tr(context, S.enterCodeManually)
            : tr(context, S.scanPairingQr)),
        leading: widget.isFirstRun
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
        actions: [
          if (!_manualMode)
            IconButton(
              tooltip: tr(context, S.toggleTorch),
              icon: const Icon(Icons.flash_on),
              onPressed: () => _scannerController.toggleTorch(),
            ),
        ],
      ),
      body: _manualMode ? _buildManual() : _buildScanner(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() {
                      _manualMode = !_manualMode;
                      _error = null;
                    });
                    if (_manualMode) {
                      _scannerController.stop();
                    } else {
                      _scannerController.start();
                    }
                  },
            child: Text(
              _manualMode
                  ? tr(context, S.useCameraScanner)
                  : tr(context, S.enterCodeManually),
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onScanCapture,
                errorBuilder: (ctx, err, _) =>
                    _ScannerErrorView(error: err, onSwitchManual: () {
                      setState(() => _manualMode = true);
                    }),
              ),
              const _ScannerOverlay(),
              if (_busy)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          ),
        ),
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.red.withValues(alpha: 0.15),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.red),
              textAlign: TextAlign.center,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            tr(context, S.onServerRunQr),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.surfaces.fgMuted.withValues(alpha: 0.9),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManual() {
    return _ManualPairForm(
      busy: _busy,
      error: _error,
      onSubmit: _onManualSubmit,
    );
  }
}

class _ManualPairForm extends StatefulWidget {
  final bool busy;
  final String? error;
  final Future<void> Function({required String baseUrl, required String code})
      onSubmit;

  const _ManualPairForm({
    required this.busy,
    required this.error,
    required this.onSubmit,
  });

  @override
  State<_ManualPairForm> createState() => _ManualPairFormState();
}

class _ManualPairFormState extends State<_ManualPairForm> {
  final _urlController =
      TextEditingController(text: 'https://api.watchlog.pl');
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr(context, S.runOnServerMultiline),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.surfaces.fgMuted,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: tr(context, S.serverUrl),
                hintText: 'https://api.watchlog.pl',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              maxLength: 16,
              decoration: InputDecoration(
                labelText: tr(context, S.pairingCode),
                hintText: 'e.g. K3M9XR',
                counterText: '',
              ),
              onSubmitted: (_) => widget.onSubmit(
                baseUrl: _urlController.text,
                code: _codeController.text,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.error != null) ...[
              Text(widget.error!,
                  style: const TextStyle(color: AppColors.red)),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: widget.busy
                  ? null
                  : () => widget.onSubmit(
                        baseUrl: _urlController.text,
                        code: _codeController.text,
                      ),
              child: widget.busy
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.surfaces.bg))
                  : Text(tr(context, S.pairBtn)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Visual frame around the scanner viewport — purely cosmetic, gives the
/// user a target to aim at.
class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _ScannerErrorView extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onSwitchManual;

  const _ScannerErrorView({required this.error, required this.onSwitchManual});

  @override
  Widget build(BuildContext context) {
    final reason = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        tr(context, S.cameraPermissionDenied),
      MobileScannerErrorCode.unsupported => tr(context, S.scannerUnsupported),
      _ => tr(context, S.cameraError, subs: {
            'detail': error.errorDetails?.message ?? error.errorCode.name,
          }),
    };
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off,
              size: 56, color: context.surfaces.fgMuted),
          const SizedBox(height: 16),
          Text(
            reason,
            textAlign: TextAlign.center,
            style: TextStyle(color: context.surfaces.fgMuted),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onSwitchManual,
            child: Text(tr(context, S.enterCodeManually)),
          ),
        ],
      ),
    );
  }
}

/// QR payload schema produced by `watchlog api qr`. Versioned so we can
/// extend the format later without breaking older clients.
class _PairingPayload {
  final String baseUrl;
  final String code;
  final String? name;
  const _PairingPayload({required this.baseUrl, required this.code, this.name});
}

_PairingPayload? _tryParseQr(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    if (decoded['kind'] != 'watchlog_pairing') return null;
    final url = decoded['baseUrl'];
    final code = decoded['code'];
    if (url is! String || code is! String) return null;
    if (url.isEmpty || code.isEmpty) return null;
    return _PairingPayload(
      baseUrl: url,
      code: code,
      name: decoded['name'] as String?,
    );
  } catch (_) {
    return null;
  }
}
