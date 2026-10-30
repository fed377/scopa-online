import 'package:flutter/material.dart';
import 'package:scopa/board_cards.dart';
import 'package:scopa/game/rules.dart';
import 'package:scopa/hand.dart';
import 'package:scopa/opponent_hands.dart';
import 'package:scopa/play_board.dart';
import 'package:scopa/taken_cards.dart';
import 'package:scopa/utils.dart';
import 'package:scopa/widgets/scopa_banner.dart';
import 'package:scopa/widgets/scoreboard.dart';

class PlayingMenu extends StatelessWidget {
  const PlayingMenu({
    super.key,
    required this.data,
    required this.hand,
    required this.uid,
    required this.playCard,
    required this.cardAnimDuration,
  });

  final DynaMap data;
  final List<String> hand;
  final String uid;
  final void Function(String) playCard;
  final Duration cardAnimDuration;

  @override
  Widget build(BuildContext context) {
    final seat = (data['players'] as List).indexOf(uid);
    final pair = pairForSeat(seat);
    final opponents = otherPair(pair);
    final myTurn = seatToPlay(data['turn'], data['round']) == seat;
    return Stack(
      children: [
        const PlayBoard(),
        ...[
          TakenCards(data: data, pair: pair),
          OpponentHands(data: data, uid: uid),
          BoardCards(data: data, seat: seat, pair: pair, cardAnimDuration: cardAnimDuration),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Scoreboard(
                ours: data['${pair}Score'] as int? ?? 0,
                theirs: data['${opponents}Score'] as int? ?? 0,
                target: data['targetScore'] as int? ?? 21,
              ),
            ),
          ),
          ScopaBanner(
            ourScope: data['${pair}Scope'] as int? ?? 0,
            theirScope: data['${opponents}Scope'] as int? ?? 0,
          ),
        ].map((e) => IgnorePointer(child: e)),
        Hand(cards: hand, enabled: myTurn && data['pending'] == null, playCard: playCard),
      ],
    );
  }
}
