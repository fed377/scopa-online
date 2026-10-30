import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';

/// Fades, slides and scales its child in once, after [delay]. Used to stagger
/// lists of items (score cards, lobby seats, dealt cards).
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.slow,
    this.offset = const Offset(0, 24),
    this.scale = 0.92,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Where the child starts, in logical pixels relative to its final position.
  final Offset offset;
  final double scale;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: widget.duration);
  late final _curve = CurvedAnimation(parent: _controller, curve: Motion.enter);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: _controller.value,
          child: Transform.translate(
            offset: widget.offset * (1 - t),
            child: Transform.scale(scale: widget.scale + (1 - widget.scale) * t, child: child),
          ),
        );
      },
    );
  }
}
