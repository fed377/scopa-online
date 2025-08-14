import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:scopa/board_cards.dart';
import 'package:scopa/hand.dart';
import 'package:scopa/main.dart';
import 'package:scopa/opponent_hands.dart';
import 'package:scopa/play_board.dart';
import 'package:scopa/taken_cards.dart';
import 'package:scopa/user_state.dart';

class PlayingMenu extends StatelessWidget {
  const PlayingMenu({
    super.key,
    required this.game,
    required this.userState,
    required this.snapshot,
    required this.cardSize,
    required this.playCard,
    required this.cardAnimDuration,
  });

  final UserState userState;
  final Stream<DocumentSnapshot<Map<String, dynamic>>> snapshot;
  final double cardSize;
  final void Function(String) playCard;
  final Duration cardAnimDuration;

  final DocumentReference<DynaMap> game;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Hand(userState: userState, snapshot: snapshot, cardSize: cardSize, playCard: playCard),
        PlayBoard(),
        ...[
          BoardCards(
            cardAnimDuration: cardAnimDuration,
            snapshot: game.snapshots(),
            turnKey: userState.turnKey,
            round: userState.round,
          ),
          OpponentHands(game: game, userState: userState, cardSize: cardSize),
          TakenCards(
            snapshot: game.snapshots(),
            pair: userState.pair,
            oppositePair: userState.oppositePair,
            cardSize: cardSize,
          ),
        ].map((e) => IgnorePointer(ignoring: true, child: e))
      ],
    );
  }
}
