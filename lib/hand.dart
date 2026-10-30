import 'package:flutter/material.dart';
import 'package:scopa/hand_card.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/widgets/playing_card.dart';

/// This player's cards, fanned in a gentle arc at the bottom of the screen.
class Hand extends StatelessWidget {
  const Hand({
    super.key,
    required this.cards,
    required this.enabled,
    required this.playCard,
  });

  final List<String> cards;

  /// False when this player can't play right now; the hand is dimmed and ignores taps.
  final bool enabled;
  final void Function(String) playCard;

  @override
  Widget build(BuildContext context) {
    final metrics = CardMetrics.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final spacing = metrics.width * 0.68;
    final mid = (cards.length - 1) / 2;

    return IgnorePointer(
      ignoring: !enabled,
      child: AnimatedOpacity(
        duration: Motion.medium,
        opacity: enabled ? 1 : 0.7,
        child: Stack(
          children: [
            for (final (i, card) in cards.indexed)
              AnimatedPositioned(
                key: ValueKey(card),
                duration: Motion.medium,
                curve: Motion.move,
                left: width / 2 + (i - mid) * spacing - metrics.width / 2,
                bottom: 28 - (i - mid) * (i - mid) * metrics.height * 0.012 - (enabled ? 0 : 10),
                child: HandCard(
                  card: card,
                  height: metrics.height,
                  angle: (i - mid) * 0.06,
                  dealDelay: Duration(milliseconds: 70 * i),
                  onTap: playCard,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
