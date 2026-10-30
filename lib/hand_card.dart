import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/widgets/playing_card.dart';

/// A card in this player's hand. It deals in from below after [dealDelay] and
/// lifts on hover. All of it is transform-only, so nothing re-lays out while
/// animating.
class HandCard extends StatefulWidget {
  const HandCard({
    super.key,
    required this.card,
    required this.height,
    required this.onTap,
    this.angle = 0,
    this.dealDelay = Duration.zero,
  });

  final String card;
  final double height;
  final void Function(String) onTap;

  /// Rotation in radians, for the fan.
  final double angle;
  final Duration dealDelay;

  @override
  State<HandCard> createState() => _HandCardState();
}

class _HandCardState extends State<HandCard> with SingleTickerProviderStateMixin {
  bool hover = false;
  late final _deal = AnimationController(vsync: this, duration: Motion.slow);
  late final _dealCurve = CurvedAnimation(parent: _deal, curve: Motion.enter);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.dealDelay, () {
      if (mounted) _deal.forward();
    });
  }

  @override
  void dispose() {
    _deal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.height;
    return AnimatedRotation(
      turns: widget.angle / (2 * pi),
      duration: Motion.medium,
      curve: Motion.move,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hover = true),
        onExit: (_) => setState(() => hover = false),
        // The tap target stays at the card's resting slot so that the lifted
        // card can't slide out from under the cursor.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onTap(widget.card),
          child: SizedBox(
            width: height * 0.73,
            height: height,
            child: AnimatedBuilder(
              animation: _dealCurve,
              builder: (context, child) => Opacity(
                opacity: _deal.value,
                child: Transform.translate(offset: Offset(0, (1 - _dealCurve.value) * height * 1.2), child: child),
              ),
              child: AnimatedSlide(
                offset: hover ? const Offset(0, -0.2) : Offset.zero,
                duration: Motion.medium,
                curve: Motion.enter,
                child: AnimatedScale(
                  scale: hover ? 1.08 : 1,
                  duration: Motion.medium,
                  curve: Motion.enter,
                  child: PlayingCard(widget.card, height: height, elevated: hover),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
