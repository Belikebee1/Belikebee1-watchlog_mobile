import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../providers/lock_provider.dart';
import '../theme.dart';

/// Full-screen lock overlay. Shown by [AppLockGate] whenever
/// LockState.locked is true. The user authenticates via the platform
/// biometric dialog; on success the LockNotifier flips locked back to
/// false and the gate falls through to the real app.
///
/// We auto-prompt on mount so the user doesn't have to tap a button
/// every time they return from the background.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _attempting = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAuth());
  }

  Future<void> _tryAuth() async {
    if (_attempting) return;
    setState(() {
      _attempting = true;
      _failed = false;
    });
    final ok = await ref
        .read(lockProvider.notifier)
        .authenticate(tr(context, S.lockReason));
    if (!mounted) return;
    setState(() {
      _attempting = false;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👁️', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(
                tr(context, S.lockTitle),
                style: TextStyle(
                  color: context.surfaces.fg,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr(context, S.lockSubtitle),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.surfaces.fgMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _attempting ? null : _tryAuth,
                icon: const Icon(Icons.fingerprint),
                label: Text(tr(context, S.lockAuthenticate)),
              ),
              if (_failed) ...[
                const SizedBox(height: 16),
                Text(
                  tr(context, S.lockFailed),
                  style: const TextStyle(color: AppColors.red),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
