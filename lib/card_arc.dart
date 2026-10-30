import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/widgets/playing_card.dart';

/// The decorative fan of aces around the settebello on the start screens. It
/// spreads a little on hover.
class CardArc extends StatefulWidget {
  const CardArc({super.key});

  @override
  State<CardArc> createState() => _CardArcState();
}

class _CardArcState extends State<CardArc> {
  bool hover = false;

  // Paint order puts the settebello on top.
  static const _cards = [('31', -2), ('21', -1), ('41', 2), ('11', 1), ('27', 0)];

  @override
  Widget build(BuildContext context) {
    final spread = hover ? 1.18 : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: SizedBox(
        width: 300,
        height: 190,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final (card, slot) in _cards)
              AnimatedSlide(
                offset: Offset(slot * 0.52 * spread, (slot * slot) * 0.045 * spread),
                duration: Motion.slow,
                curve: Motion.enter,
                child: AnimatedRotation(
                  turns: slot * 0.04 * spread,
                  duration: Motion.slow,
                  curve: Motion.enter,
                  child: PlayingCard(card, height: 110),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
