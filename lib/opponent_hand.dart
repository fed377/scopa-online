import 'package:flutter/material.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/widgets/player_badge.dart';
import 'package:scopa/widgets/playing_card.dart';

/// An opponent's seat: a fan of card backs plus their name badge. The fan is
/// vertical for the side seats; the badge is never rotated.
class OpponentHand extends StatelessWidget {
  const OpponentHand({
    super.key,
    required this.alignment,
    required this.name,
    required this.imageUrl,
    required this.count,
    required this.cardHeight,
    this.active = false,
  });

  final Alignment alignment;
  final String name;
  final String imageUrl;
  final int count;
  final double cardHeight;

  /// Whether it is this opponent's turn.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final overlap = cardHeight * 0.73 * 0.32;
    final fan = AnimatedSize(
      duration: Motion.medium,
      curve: Motion.move,
      child: SizedBox(
        width: cardHeight * 0.73 + overlap * (count - 1).clamp(0, 9),
        height: cardHeight,
        child: Stack(
          children: [
            for (var i = 0; i < count; i++) Positioned(left: overlap * i, child: CardBack(height: cardHeight)),
          ],
        ),
      ),
    );
    final badge = PlayerBadge(name: name, imageUrl: imageUrl, active: active);
    final vertical = alignment.y == 0;

    return Align(
      alignment: alignment,
      child: vertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: alignment.x < 0 ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [badge, const SizedBox(height: 12), RotatedBox(quarterTurns: 1, child: fan)],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [fan, const SizedBox(width: 16), badge],
            ),
    );
  }
}
