import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/strings.dart';
import '../providers/onboarding_provider.dart';
import '../theme.dart';

/// 4-page introduction shown on first launch (and replayable from
/// Settings). Each page is intentionally short — what / how / when /
/// privacy — followed by a CTA that completes onboarding.
///
/// Skipping has the same effect as completing the last page: the
/// preference flips to "done" and the user lands on the regular
/// first-run flow (currently AddServerScreen).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pager = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  List<_Page> _pages(BuildContext context) => [
        _Page(
          emoji: '👁️',
          title: tr(context, S.ob1Title),
          body: tr(context, S.ob1Body),
          color: AppColors.accent,
        ),
        _Page(
          emoji: '📷',
          title: tr(context, S.ob2Title),
          body: tr(context, S.ob2Body),
          color: AppColors.green,
        ),
        _Page(
          emoji: '🔔',
          title: tr(context, S.ob3Title),
          body: tr(context, S.ob3Body),
          color: AppColors.yellow,
        ),
        _Page(
          emoji: '🔐',
          title: tr(context, S.ob4Title),
          body: tr(context, S.ob4Body),
          color: AppColors.red,
        ),
      ];

  Future<void> _done() async {
    await ref.read(onboardingProvider.notifier).markDone();
  }

  void _onNext() {
    final pages = _pages(context);
    if (_page < pages.length - 1) {
      _pager.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _done();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages(context);
    final isLast = _page == pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button — top-right, always available.
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: TextButton(
                  onPressed: _done,
                  child: Text(
                    tr(context, S.onboardingSkip),
                    style: TextStyle(color: context.surfaces.fgMuted),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (ctx, i) => _PageBody(page: pages[i]),
              ),
            ),
            _Dots(count: pages.length, current: _page),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isLast
                        ? tr(context, S.onboardingGetStarted)
                        : tr(context, S.onboardingNext),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Page {
  final String emoji;
  final String title;
  final String body;
  final Color color;
  const _Page({
    required this.emoji,
    required this.title,
    required this.body,
    required this.color,
  });
}

class _PageBody extends StatelessWidget {
  final _Page page;
  const _PageBody({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: page.color.withValues(alpha: 0.25),
                  blurRadius: 32,
                ),
              ],
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.surfaces.fg,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.surfaces.fgMuted,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int current;
  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current
                  ? AppColors.accent
                  : context.surfaces.fgMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
