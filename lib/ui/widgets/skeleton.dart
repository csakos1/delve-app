import 'package:flutter/material.dart';

import '../../theme/delve_theme.dart';

/// Placeholder blocks that pulse in opacity (1200 ms, no shimmer gradient);
/// still when the system asks for reduced motion.
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c
        ..stop()
        ..value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(
      begin: 0.55,
      end: 1,
    ).animate(CurvedAnimation(parent: _c, curve: DelveTokens.standard)),
    child: widget.child,
  );
}

/// One placeholder block.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.strong = true,
  });

  final double width;
  final double height;

  /// surface-2 (titles) instead of surface-1 (secondary lines).
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: strong ? cs.surfaceContainer : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DelveTokens.rxs),
      ),
    );
  }
}
