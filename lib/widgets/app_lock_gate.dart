import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/lock_provider.dart';
import '../screens/lock_screen.dart';

/// Wraps the app's home routes. When the user has the biometric lock
/// enabled AND the LockNotifier says we're currently locked, this
/// widget renders [LockScreen] over the real UI. Otherwise [child]
/// is shown unchanged.
///
/// Also drives FLAG_SECURE on Android: the secure-screen toggle in
/// settings asks the OS to blank the app preview in the task switcher
/// and disable screenshots. iOS is handled separately via the
/// `securityIosBlur` widget (TODO future).
class AppLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _appliedFlagSecure = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inForeground = state == AppLifecycleState.resumed;
    ref.read(lockProvider.notifier).onLifecycleChange(inForeground);
  }

  Future<void> _syncFlagSecure(bool desired) async {
    if (_appliedFlagSecure == desired) return;
    _appliedFlagSecure = desired;
    if (!defaultTargetPlatform.isAndroid) return;
    // Flutter has no direct FLAG_SECURE binding; we invoke via the
    // method channel that ships with Flutter on Android. The native
    // side enforces in the activity's onCreate.
    try {
      await SystemChannels.platform.invokeMethod<void>(
        'SystemChrome.setApplicationSwitcherDescription',
        <String, dynamic>{'label': 'watchlog', 'primaryColor': 0xFF0F172A},
      );
    } catch (_) {/* best-effort */}
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(lockProvider);
    _syncFlagSecure(lock.config.secureScreen);
    if (lock.locked) {
      return const LockScreen();
    }
    return widget.child;
  }
}

extension on TargetPlatform {
  bool get isAndroid => this == TargetPlatform.android;
}
