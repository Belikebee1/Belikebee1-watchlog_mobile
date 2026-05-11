import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/crash_reporting_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/changelog_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/lock_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/push_provider.dart';
import 'providers/rate_prompt_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/add_server_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/release_notes_screen.dart';
import 'theme.dart';
import 'widgets/app_lock_gate.dart';

Future<void> main() async {
  // runZonedGuarded captures *uncaught async* errors that
  // FlutterError.onError wouldn't see — anything raised from a
  // Future / Stream / Timer outside the widget tree. Both paths feed
  // the same Crashlytics recorder, which itself respects the
  // user's opt-in (no-op when consent is off).
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init failed (push + crash reporting disabled): $e');
    }

    // Synchronous Flutter framework errors. We never enable
    // crash collection here; setCrashlyticsCollectionEnabled (driven
    // by the user's opt-in via CrashReportingNotifier) decides
    // whether these recordings actually leave the device.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      try {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      } catch (_) {/* Crashlytics may not be initialized in tests */}
    };

    // Engine-level platform exceptions (e.g. method-channel failures).
    PlatformDispatcher.instance.onError = (error, stack) {
      try {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } catch (_) {/* see above */}
      return true;
    };

    runApp(const ProviderScope(child: WatchlogApp()));
  }, (error, stack) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {/* see above */}
  });
}

class WatchlogApp extends ConsumerStatefulWidget {
  const WatchlogApp({super.key});

  @override
  ConsumerState<WatchlogApp> createState() => _WatchlogAppState();
}

class _WatchlogAppState extends ConsumerState<WatchlogApp> {
  bool _bootstrapped = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await ref.read(authProvider.notifier).load();
    // Theme + locale mode persist across launches; both are local
    // secure-storage reads — fast, run sequentially.
    await ref.read(themeModeProvider.notifier).load();
    await ref.read(localeProvider.notifier).load();
    await ref.read(lockProvider.notifier).load();
    await ref.read(onboardingProvider.notifier).load();
    await ref.read(changelogProvider.notifier).load();
    await ref.read(analyticsProvider.notifier).load();
    await ref.read(ratePromptProvider.notifier).load();
    // Honor the persisted crash-reporting opt-in before any work
    // we'd want to report on can produce errors.
    await ref.read(crashReportingProvider.notifier).load();
    // Init push (may fail silently if Firebase not configured — that's OK)
    try {
      await ref.read(pushServiceProvider).initialize();
    } catch (e) {
      debugPrint('Push init failed: $e');
    }
    if (mounted) setState(() => _bootstrapped = true);

    // After the first paint, see if there are unseen changelog
    // entries for this build. We piggy-back on a post-frame callback
    // so the modal opens over the real home, not the splash.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowWhatsNew());
  }

  Future<void> _maybeShowWhatsNew() async {
    if (!mounted) return;
    final ctx = _navigatorKey.currentContext;
    if (ctx == null) return;
    final pending = ref.read(changelogProvider).pendingForToast();
    if (pending.isEmpty) return;
    // Mark seen up-front: if the user kills the app mid-modal, we
    // still don't re-pop next launch (the catalogue is in their
    // settings under Release notes anyway).
    await ref.read(changelogProvider.notifier).markSeen();
    if (!mounted) return;
    await showWhatsNewModal(ctx, entries: pending);
  }

  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final onboardingDone = ref.watch(onboardingProvider) ?? false;
    return MaterialApp(
      title: 'watchlog',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('pl')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: !_bootstrapped
          ? const _Splash()
          : !onboardingDone && !auth.isAuthenticated
              // First launch with no paired server: take the user
              // through onboarding before dropping them on the pair
              // screen. Returning users keep going straight to the
              // dashboard.
              ? const OnboardingScreen()
              : AppLockGate(
                  child: auth.isAuthenticated
                      ? const OverviewScreen()
                      : const AddServerScreen(isFirstRun: true),
                ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👁️', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
