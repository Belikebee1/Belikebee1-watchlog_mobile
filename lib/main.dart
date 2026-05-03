import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/status_screen.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: WatchlogApp()));
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
    if (mounted) setState(() => _bootstrapped = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return MaterialApp(
      title: 'watchlog',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: !_bootstrapped
          ? const _Splash()
          : auth.isAuthenticated
              ? const StatusScreen()
              : const LoginScreen(),
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
