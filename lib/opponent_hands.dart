import 'package:flutter/material.dart';
import 'package:scopa/game/rules.dart';
import 'package:scopa/opponent_hand.dart';
import 'package:scopa/theme.dart';
import 'package:scopa/utils.dart';
import 'package:scopa/widgets/player_badge.dart';
import 'package:scopa/widgets/playing_card.dart';

/// The other three seats around the table, in play order starting on the
/// left, plus this player's own badge above their hand.
class OpponentHands extends StatelessWidget {
  const OpponentHands({super.key, required this.data, required this.uid});

  final DynaMap data;
  final String uid;

  static const _alignments = [Alignment.centerLeft, Alignment.topCenter, Alignment.centerRight];

  @override
  Widget build(BuildContext context) {
    final players = List<String>.from(data['players']);
    final nicknames = data['nicknames'] as Map;
    final images = data['images'] as Map;
    final counts = data['handCounts'] as Map? ?? {};
    final seat = players.indexOf(uid);
    final toPlay = players[seatToPlay(data['turn'], data['round'])];
    final waiting = data['pending'] == null;
    final metrics = CardMetrics.of(context);

    return Stack(
      children: [
        for (var x = 1; x <= 3; x++)
          if (players[(seat + x) % 4] case final id)
            Padding(
              padding: const EdgeInsets.all(18),
              child: OpponentHand(
                alignment: _alignments[x - 1],
                name: nicknames[id] ?? '',
                imageUrl: images[id] ?? '',
                count: counts[id] as int? ?? 0,
                cardHeight: metrics.height * 0.62,
                active: waiting && id == toPlay,
              ),
            ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: metrics.height + 44),
            child: PlayerBadge(
              name: nicknames[uid] ?? '',
              imageUrl: images[uid] ?? '',
              active: waiting && toPlay == uid,
              trailing: AnimatedSize(
                duration: Motion.medium,
                curve: Motion.enter,
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  child: waiting && toPlay == uid
                      ? Text('· Your turn', key: const ValueKey(true), style: displayStyle(15, color: AppColors.accent))
                      : const SizedBox.shrink(key: ValueKey(false)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
