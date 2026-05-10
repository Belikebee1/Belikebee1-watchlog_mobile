import 'package:flutter/material.dart';

import '../theme.dart';

/// A pulsing placeholder shape used while real content loads.
///
/// One [AnimationController] is shared via an inherited [SkeletonGroup] so
/// all skeletons in a tree pulse in phase — that's noticeably more
/// pleasant than every box throbbing on its own clock. Wrap a screen in
/// [SkeletonGroup] when there are several skeletons; standalone
/// skeletons fall back to spawning their own controller.
///
/// Why we don't use `flutter_shimmer`: it pulls in a 200KB dependency for
/// what's effectively a 50-line widget. Hand-rolled keeps the bundle
/// small and the look consistent with the rest of the app's theme.
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry margin;
  final BoxShape shape;

  const Skeleton({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 4,
    this.margin = EdgeInsets.zero,
    this.shape = BoxShape.rectangle,
  });

  /// Convenience constructor for circular avatar/dot skeletons.
  const Skeleton.circle({
    super.key,
    required double size,
    this.margin = EdgeInsets.zero,
  })  : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;

  @override
  void dispose() {
    _localController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupController =
        SkeletonGroup.maybeControllerOf(context);
    final controller = groupController ??
        (_localController ??= AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )..repeat(reverse: true));

    return AnimatedBuilder(
      animation: controller,
      builder: (ctx, _) {
        // Sinusoidal pulse between 0.35 and 0.65 alpha — visible enough
        // to read as "loading", subtle enough to not be distracting on
        // screens with many skeletons at once.
        final t = (controller.value * 2 - 1).abs();
        final alpha = 0.35 + 0.30 * t;
        final color = context.surfaces.fgMuted.withValues(alpha: alpha * 0.4);
        return Container(
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Wrap any subtree to share a single pulse controller across every
/// [Skeleton] inside it. Without this, each skeleton runs its own
/// AnimationController which is cheap but visually busy.
class SkeletonGroup extends StatefulWidget {
  final Widget child;
  const SkeletonGroup({super.key, required this.child});

  /// Returns the parent group's pulse controller, or null if no group is
  /// in the tree (in which case [Skeleton] spawns its own).
  static AnimationController? maybeControllerOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_SkeletonGroupScope>();
    return scope?.controller;
  }

  @override
  State<SkeletonGroup> createState() => _SkeletonGroupState();
}

class _SkeletonGroupState extends State<SkeletonGroup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SkeletonGroupScope(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _SkeletonGroupScope extends InheritedWidget {
  final AnimationController controller;
  const _SkeletonGroupScope({
    required this.controller,
    required super.child,
  });

  @override
  bool updateShouldNotify(_SkeletonGroupScope oldWidget) =>
      oldWidget.controller != controller;
}
